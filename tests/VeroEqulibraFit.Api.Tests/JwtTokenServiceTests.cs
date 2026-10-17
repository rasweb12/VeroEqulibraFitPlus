using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using VeroEqulibraFit.Api.Services;
using VeroEqulibraFit.Infrastructure.Data;

namespace VeroEqulibraFit.Api.Tests;

public sealed class JwtTokenServiceTests
{
    private const string SigningKey = "test-signing-key-with-at-least-sixty-four-bytes-for-hs512-validation-0001";
    private const string Issuer = "vero-equilibrafit-api-tests";
    private const string Audience = "vero-equilibrafit-mobile-tests";

    [Fact]
    public void ValidateConfiguration_RejectsMissingSigningKey()
    {
        var configuration = Configuration(false, [("Jwt:Issuer", Issuer)]);

        var exception = Assert.Throws<InvalidOperationException>(() => JwtTokenService.ValidateConfiguration(configuration));

        Assert.Contains("Jwt:SigningKey", exception.Message);
    }

    [Fact]
    public void ValidateConfiguration_RejectsMissingIssuer()
    {
        var configuration = Configuration(false, [("Jwt:SigningKey", SigningKey)]);

        var exception = Assert.Throws<InvalidOperationException>(() => JwtTokenService.ValidateConfiguration(configuration));

        Assert.Contains("Jwt:Issuer", exception.Message);
    }

    [Fact]
    public void ValidateConfiguration_RejectsMissingAudience()
    {
        var configuration = Configuration(false, [("Jwt:Issuer", Issuer), ("Jwt:SigningKey", SigningKey)]);

        var exception = Assert.Throws<InvalidOperationException>(() => JwtTokenService.ValidateConfiguration(configuration));

        Assert.Contains("Jwt:Audience", exception.Message);
    }

    [Fact]
    public void ValidateConfiguration_RejectsShortSigningKey()
    {
        var configuration = Configuration(true, [("Jwt:Issuer", Issuer), ("Jwt:SigningKey", "short")]);

        var exception = Assert.Throws<InvalidOperationException>(() => JwtTokenService.ValidateConfiguration(configuration));

        Assert.Contains("at least 64 bytes", exception.Message);
    }

    [Fact]
    public async Task CreateAccessToken_ProducesValidSignedToken()
    {
        var service = new JwtTokenService(Configuration());
        var user = new AppUser { Id = Guid.NewGuid(), Email = "user@example.test" };
        var (token, _) = service.CreateAccessToken(user, ["member"]);

        var result = await new JwtSecurityTokenHandler().ValidateTokenAsync(token, ValidationParameters(service));

        Assert.True(result.IsValid);
        Assert.Equal(user.Id.ToString(), result.ClaimsIdentity!.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        Assert.Contains(result.ClaimsIdentity.Claims, claim => claim.Type == ClaimTypes.Role && claim.Value == "member");
    }

    [Fact]
    public async Task ValidateToken_RejectsInvalidSignature()
    {
        var service = new JwtTokenService(Configuration());
        var token = new JwtSecurityTokenHandler().WriteToken(new JwtSecurityToken(
            service.Issuer,
            service.Audience,
            expires: DateTime.UtcNow.AddMinutes(5),
            signingCredentials: new SigningCredentials(
                new SymmetricSecurityKey(System.Text.Encoding.UTF8.GetBytes("different-signing-key-with-at-least-sixty-four-bytes-for-hs512-validation")),
                SecurityAlgorithms.HmacSha512)));

        var result = await new JwtSecurityTokenHandler().ValidateTokenAsync(token, ValidationParameters(service));

        Assert.False(result.IsValid);
        Assert.IsType<SecurityTokenSignatureKeyNotFoundException>(result.Exception);
    }

    [Fact]
    public async Task ValidateToken_RejectsExpiredToken()
    {
        var service = new JwtTokenService(Configuration());
        var token = new JwtSecurityTokenHandler().WriteToken(new JwtSecurityToken(
            service.Issuer,
            service.Audience,
            expires: DateTime.UtcNow.AddMinutes(-1),
            signingCredentials: new SigningCredentials(service.SigningKey, SecurityAlgorithms.HmacSha512)));

        var result = await new JwtSecurityTokenHandler().ValidateTokenAsync(token, ValidationParameters(service));

        Assert.False(result.IsValid);
        Assert.IsType<SecurityTokenExpiredException>(result.Exception);
    }

    private static IConfiguration Configuration(bool includeDefaults = true, (string Key, string Value)[]? overrides = null)
    {
        var values = new Dictionary<string, string?>();
        if (includeDefaults)
        {
            values["Jwt:Issuer"] = Issuer;
            values["Jwt:Audience"] = Audience;
            values["Jwt:SigningKey"] = SigningKey;
        }
        if (overrides is not null)
            foreach (var (key, value) in overrides)
                values[key] = value;
        return new ConfigurationBuilder().AddInMemoryCollection(values).Build();
    }

    private static TokenValidationParameters ValidationParameters(JwtTokenService service) => new()
    {
        ValidateIssuer = true,
        ValidIssuer = service.Issuer,
        ValidateAudience = true,
        ValidAudience = service.Audience,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = service.SigningKey,
        ClockSkew = TimeSpan.Zero,
    };
}
