using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VeroEqulibraFit.Api.Services;
using VeroEqulibraFit.Contracts.Auth;
using VeroEqulibraFit.Infrastructure.Data;

namespace VeroEqulibraFit.Api.Controllers;

[ApiController]
[Route("api/v1/auth")]
public sealed class AuthController(
    UserManager<AppUser> userManager,
    VeroEqulibraFitDbContext database,
    JwtTokenService tokenService,
    IAccountEmailSender emailSender) : ControllerBase
{
    private static readonly TimeSpan RefreshLifetime = TimeSpan.FromDays(30);

    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<ActionResult<AuthResponse>> Register(RegisterRequest request, CancellationToken cancellationToken)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(request.Password))
            return ValidationProblem("E-mail e senha são obrigatórios.");
        var user = new AppUser { Id = Guid.NewGuid(), UserName = email, Email = email, DisplayName = request.DisplayName?.Trim() };
        var result = await userManager.CreateAsync(user, request.Password);
        if (!result.Succeeded)
            return BadRequest(new ValidationProblemDetails(result.Errors.GroupBy(error => error.Code).ToDictionary(group => group.Key, group => group.Select(error => error.Description).ToArray())));
        return Ok(await IssueTokens(user, cancellationToken));
    }

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<ActionResult<AuthResponse>> Login(LoginRequest request, CancellationToken cancellationToken)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var user = await userManager.FindByEmailAsync(email);
        if (user is null || !await userManager.CheckPasswordAsync(user, request.Password))
            return Unauthorized(new ProblemDetails { Title = "Credenciais inválidas." });
        return Ok(await IssueTokens(user, cancellationToken));
    }

    [HttpPost("forgot-password")]
    [AllowAnonymous]
    public async Task<AcceptedResult> ForgotPassword(ForgotPasswordRequest request, CancellationToken cancellationToken)
    {
        var email = request.Email?.Trim().ToLowerInvariant();
        if (!string.IsNullOrWhiteSpace(email))
        {
            var user = await userManager.FindByEmailAsync(email);
            if (user is not null)
            {
                var token = await userManager.GeneratePasswordResetTokenAsync(user);
                var baseUrl = HttpContext.Request.Scheme + "://" + HttpContext.Request.Host;
                var link = $"{baseUrl}/reset-password?userId={Uri.EscapeDataString(user.Id.ToString())}&token={Uri.EscapeDataString(token)}";
                try { await emailSender.SendPasswordResetAsync(user.Email!, link, cancellationToken); }
                catch (InvalidOperationException) { /* Avoid account enumeration; deployment health exposes missing configuration. */ }
            }
        }
        return Accepted();
    }

    [HttpPost("reset-password")]
    [AllowAnonymous]
    public async Task<IActionResult> ResetPassword(ResetPasswordRequest request)
    {
        if (!Guid.TryParse(request.UserId, out var userId) || string.IsNullOrWhiteSpace(request.Token) || string.IsNullOrWhiteSpace(request.NewPassword))
            return BadRequest(new ProblemDetails { Title = "Solicitação inválida." });
        var user = await userManager.FindByIdAsync(userId.ToString());
        if (user is null) return BadRequest(new ProblemDetails { Title = "Solicitação inválida ou expirada." });
        var result = await userManager.ResetPasswordAsync(user, request.Token, request.NewPassword);
        if (!result.Succeeded) return BadRequest(new ProblemDetails { Title = "Solicitação inválida ou expirada." });
        var tokens = database.RefreshTokens.Where(token => token.UserId == user.Id && token.RevokedAt == null);
        await tokens.ExecuteUpdateAsync(setters => setters.SetProperty(token => token.RevokedAt, DateTimeOffset.UtcNow));
        return NoContent();
    }

    [HttpPost("refresh")]
    [AllowAnonymous]
    public async Task<ActionResult<AuthResponse>> Refresh(RefreshRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.RefreshToken)) return Unauthorized();
        var hash = JwtTokenService.HashRefreshToken(request.RefreshToken);
        var refreshToken = await database.RefreshTokens.AsNoTracking().SingleOrDefaultAsync(token => token.TokenHash == hash, cancellationToken);
        if (refreshToken is null || refreshToken.RevokedAt is not null || refreshToken.ExpiresAt <= DateTimeOffset.UtcNow) return Unauthorized();
        var user = await userManager.FindByIdAsync(refreshToken.UserId.ToString());
        if (user is null) return Unauthorized();
        var revokedAt = DateTimeOffset.UtcNow;
        var revoked = await database.RefreshTokens
            .Where(token => token.Id == refreshToken.Id && token.RevokedAt == null)
            .ExecuteUpdateAsync(setters => setters.SetProperty(token => token.RevokedAt, revokedAt), cancellationToken);
        if (revoked != 1) return Unauthorized();
        var response = await IssueTokens(user, cancellationToken);
        await database.RefreshTokens
            .Where(token => token.Id == refreshToken.Id)
            .ExecuteUpdateAsync(setters => setters.SetProperty(token => token.ReplacedByTokenHash, JwtTokenService.HashRefreshToken(response.RefreshToken)), cancellationToken);
        return Ok(response);
    }

    [HttpPost("logout")]
    [Authorize]
    public async Task<IActionResult> Logout(RefreshRequest request, CancellationToken cancellationToken)
    {
        var userId = CurrentUserId();
        var hash = JwtTokenService.HashRefreshToken(request.RefreshToken);
        var token = await database.RefreshTokens.SingleOrDefaultAsync(item => item.TokenHash == hash && item.UserId == userId, cancellationToken);
        if (token is not null) { token.RevokedAt = DateTimeOffset.UtcNow; await database.SaveChangesAsync(cancellationToken); }
        return NoContent();
    }

    [HttpGet("session")]
    [Authorize]
    public async Task<ActionResult<SessionResponse>> Session()
    {
        var user = await userManager.FindByIdAsync(CurrentUserId().ToString());
        return user is null ? Unauthorized() : Ok(new SessionResponse(user.Id.ToString(), user.Email!, user.DisplayName));
    }

    [HttpDelete("account")]
    [Authorize]
    public async Task<IActionResult> DeleteAccount(CancellationToken cancellationToken)
    {
        var user = await userManager.FindByIdAsync(CurrentUserId().ToString());
        if (user is null) return NoContent();
        var tokens = database.RefreshTokens.Where(token => token.UserId == user.Id);
        database.RefreshTokens.RemoveRange(tokens);
        var result = await userManager.DeleteAsync(user);
        if (!result.Succeeded) return Problem("Não foi possível excluir a conta.");
        await database.SaveChangesAsync(cancellationToken);
        return NoContent();
    }

    private async Task<AuthResponse> IssueTokens(AppUser user, CancellationToken cancellationToken)
    {
        var access = tokenService.CreateAccessToken(user, await userManager.GetRolesAsync(user));
        var rawRefreshToken = JwtTokenService.NewRefreshToken();
        database.RefreshTokens.Add(new RefreshToken { UserId = user.Id, TokenHash = JwtTokenService.HashRefreshToken(rawRefreshToken), ExpiresAt = DateTimeOffset.UtcNow.Add(RefreshLifetime) });
        await database.SaveChangesAsync(cancellationToken);
        return new AuthResponse(access.Token, rawRefreshToken, access.ExpiresAt, user.Id.ToString(), user.Email!, user.DisplayName);
    }

    private Guid CurrentUserId() => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}
