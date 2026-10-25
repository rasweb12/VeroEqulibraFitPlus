using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VeroEqulibraFit.Api.Services;
using VeroEqulibraFit.Contracts.Admin;
using VeroEqulibraFit.Infrastructure.Data;

namespace VeroEqulibraFit.Api.Controllers;

/// <summary>
/// Administrative identity operations. The endpoints expose only the minimum
/// operational identity data; health records, meals, plans, chat history and
/// authentication material are intentionally absent.
/// </summary>
[ApiController]
[Authorize(Policy = "admin")]
[Route("api/v1/admin/users")]
public sealed class AdminUsersController(
    VeroEqulibraFitDbContext database,
    UserManager<AppUser> userManager) : ControllerBase
{
    private const int DefaultPageSize = 25;
    private const int MaximumPageSize = 100;

    [HttpGet]
    public async Task<ActionResult<AdminUserListResponse>> List(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = DefaultPageSize,
        [FromQuery] string? query = null,
        [FromQuery] string? status = null,
        [FromQuery] string? role = null,
        CancellationToken cancellationToken = default)
    {
        if (page < 1) return BadRequest(new { error = "page deve ser maior que zero." });
        pageSize = Math.Clamp(pageSize, 1, MaximumPageSize);
        var normalizedStatus = (status ?? "all").Trim().ToLowerInvariant();
        if (normalizedStatus is not ("all" or "active" or "blocked"))
            return BadRequest(new { error = "status inválido." });

        var now = DateTimeOffset.UtcNow;
        var users = database.Users.AsNoTracking();
        if (normalizedStatus == "active")
            users = users.Where(user => !user.LockoutEnabled || user.LockoutEnd == null || user.LockoutEnd <= now);
        else if (normalizedStatus == "blocked")
            users = users.Where(user => user.LockoutEnabled && user.LockoutEnd != null && user.LockoutEnd > now);

        var search = query?.Trim();
        if (!string.IsNullOrEmpty(search))
        {
            if (search.Length > 120) return BadRequest(new { error = "pesquisa longa demais." });
            var pattern = $"%{search}%";
            users = users.Where(user =>
                EF.Functions.ILike(user.Email ?? string.Empty, pattern) ||
                EF.Functions.ILike(user.DisplayName ?? string.Empty, pattern));
        }

        var requestedRole = role?.Trim();
        if (!string.IsNullOrEmpty(requestedRole))
        {
            var roleId = await database.Roles.AsNoTracking()
                .Where(item => item.NormalizedName == requestedRole.ToUpperInvariant())
                .Select(item => (Guid?)item.Id)
                .SingleOrDefaultAsync(cancellationToken);
            if (roleId is null)
                return Ok(new AdminUserListResponse([], page, pageSize, 0));
            users = users.Where(user => database.UserRoles.Any(link => link.UserId == user.Id && link.RoleId == roleId));
        }

        var total = await users.CountAsync(cancellationToken);
        var entries = await users
            .OrderBy(user => user.Email)
            .ThenBy(user => user.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(user => new UserProjection(user.Id, user.DisplayName, user.Email ?? string.Empty, user.RegisteredAt, user.LockoutEnabled && user.LockoutEnd != null && user.LockoutEnd > now))
            .ToListAsync(cancellationToken);

        var roles = await ReadRolesAsync(entries.Select(item => item.Id), cancellationToken);
        var items = entries.Select(item => new AdminUserListItem(
            item.Id, item.DisplayName, item.Email, item.RegisteredAt,
            null, item.IsBlocked, roles.GetValueOrDefault(item.Id, []))).ToList();
        return Ok(new AdminUserListResponse(items, page, pageSize, total));
    }

    [HttpGet("roles")]
    public async Task<ActionResult<IReadOnlyList<AdminRoleResponse>>> ListRoles(CancellationToken cancellationToken)
    {
        var roles = await database.Roles.AsNoTracking().Where(role => role.Name != null)
            .OrderBy(role => role.Name).Select(role => new AdminRoleResponse(role.Name!)).ToListAsync(cancellationToken);
        return Ok(roles);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<AdminUserDetailResponse>> Get(Guid id, CancellationToken cancellationToken)
    {
        var now = DateTimeOffset.UtcNow;
        var user = await database.Users.AsNoTracking()
            .Where(item => item.Id == id)
            .Select(item => new UserProjection(item.Id, item.DisplayName, item.Email ?? string.Empty, item.RegisteredAt, item.LockoutEnabled && item.LockoutEnd != null && item.LockoutEnd > now))
            .SingleOrDefaultAsync(cancellationToken);
        if (user is null) return NotFound();
        var roles = await ReadRolesAsync([id], cancellationToken);
        var history = await database.AdminAuditEvents.AsNoTracking()
            .Where(item => item.TargetUserId == id)
            .OrderByDescending(item => item.OccurredAt)
            .Take(50)
            .Select(item => new AdminAuditEventResponse(item.Id, item.ActorUserId, item.Action, item.Result, item.Reason, item.OccurredAt))
            .ToListAsync(cancellationToken);
        return Ok(new AdminUserDetailResponse(user.Id, user.DisplayName, user.Email, user.RegisteredAt, null, user.IsBlocked, roles.GetValueOrDefault(id, []), history));
    }

    [HttpPut("{id:guid}/status")]
    public async Task<ActionResult<AdminUserMutationResponse>> ChangeStatus(Guid id, ChangeAdminUserStatusRequest request, CancellationToken cancellationToken)
    {
        if (!request.Confirmed || !TryReadReason(request.Reason, out var reason))
            return BadRequest(new { error = "Confirmação e justificativa entre 3 e 500 caracteres são obrigatórias." });
        var action = request.Status?.Trim().ToLowerInvariant();
        if (action is not ("active" or "blocked")) return BadRequest(new { error = "status inválido." });
        var actorId = CurrentUserId();
        if (!AdminUserSafetyPolicy.CanChangeTarget(actorId, id)) return BadRequest(new { error = "Uma conta administrativa não pode alterar o próprio status." });
        var target = await userManager.FindByIdAsync(id.ToString());
        if (target is null) return NotFound();

        var targetRoles = await userManager.GetRolesAsync(target);
        if (action == "blocked" && targetRoles.Contains(AdminAccessBootstrapper.AdministratorRole) && await IsLastAdministratorAsync(cancellationToken))
            return Conflict(new { error = "Não é possível bloquear o último administrador ativo." });

        await using var transaction = await database.Database.BeginTransactionAsync(cancellationToken);
        if (action == "blocked")
        {
            target.LockoutEnabled = true;
            target.LockoutEnd = DateTimeOffset.UtcNow.AddYears(100);
        }
        else
        {
            target.LockoutEnd = null;
        }
        var update = await userManager.UpdateAsync(target);
        if (!update.Succeeded)
        {
            await transaction.RollbackAsync(cancellationToken);
            return BadRequest(new ValidationProblemDetails(update.Errors.GroupBy(error => error.Code).ToDictionary(group => group.Key, group => group.Select(error => error.Description).ToArray())));
        }
        await database.RefreshTokens
            .Where(token => token.UserId == target.Id && token.RevokedAt == null)
            .ExecuteUpdateAsync(setters => setters.SetProperty(token => token.RevokedAt, DateTimeOffset.UtcNow), cancellationToken);
        await WriteAuditAsync(actorId, target.Id, action == "blocked" ? "user.block" : "user.activate", "accepted", reason, cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return Ok(new AdminUserMutationResponse(target.Id, action == "blocked", targetRoles.OrderBy(role => role, StringComparer.Ordinal).ToList()));
    }

    [HttpPut("{id:guid}/roles")]
    public async Task<ActionResult<AdminUserMutationResponse>> ChangeRoles(Guid id, ChangeAdminUserRolesRequest request, CancellationToken cancellationToken)
    {
        if (!request.Confirmed || !TryReadReason(request.Reason, out var reason))
            return BadRequest(new { error = "Confirmação e justificativa entre 3 e 500 caracteres são obrigatórias." });
        var actorId = CurrentUserId();
        if (!AdminUserSafetyPolicy.CanChangeTarget(actorId, id)) return BadRequest(new { error = "Uma conta administrativa não pode alterar os próprios papéis." });
        var target = await userManager.FindByIdAsync(id.ToString());
        if (target is null) return NotFound();

        var desired = (request.Roles ?? []).Where(role => !string.IsNullOrWhiteSpace(role))
            .Select(role => role.Trim()).Distinct(StringComparer.OrdinalIgnoreCase).ToHashSet(StringComparer.OrdinalIgnoreCase);
        var available = await database.Roles.AsNoTracking().Select(item => item.Name!).ToListAsync(cancellationToken);
        if (desired.Any(role => !available.Contains(role, StringComparer.OrdinalIgnoreCase)))
            return BadRequest(new { error = "Um ou mais papéis não existem no servidor." });

        var current = (await userManager.GetRolesAsync(target)).ToHashSet(StringComparer.OrdinalIgnoreCase);
        if (!AdminUserSafetyPolicy.CanRemoveAdministrator(current, desired, await AdministratorCountAsync(cancellationToken), AdminAccessBootstrapper.AdministratorRole))
            return Conflict(new { error = "Não é possível remover o último administrador ativo." });

        await using var transaction = await database.Database.BeginTransactionAsync(cancellationToken);
        var remove = await userManager.RemoveFromRolesAsync(target, current.Except(desired, StringComparer.OrdinalIgnoreCase));
        if (!remove.Succeeded)
        {
            await transaction.RollbackAsync(cancellationToken);
            return BadRequest(new ValidationProblemDetails(remove.Errors.GroupBy(error => error.Code).ToDictionary(group => group.Key, group => group.Select(error => error.Description).ToArray())));
        }
        var add = await userManager.AddToRolesAsync(target, desired.Except(current, StringComparer.OrdinalIgnoreCase));
        if (!add.Succeeded)
        {
            await transaction.RollbackAsync(cancellationToken);
            return BadRequest(new ValidationProblemDetails(add.Errors.GroupBy(error => error.Code).ToDictionary(group => group.Key, group => group.Select(error => error.Description).ToArray())));
        }
        await database.RefreshTokens
            .Where(token => token.UserId == target.Id && token.RevokedAt == null)
            .ExecuteUpdateAsync(setters => setters.SetProperty(token => token.RevokedAt, DateTimeOffset.UtcNow), cancellationToken);
        await WriteAuditAsync(actorId, target.Id, "user.roles.update", "accepted", reason, cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return Ok(new AdminUserMutationResponse(target.Id, target.LockoutEnabled && target.LockoutEnd > DateTimeOffset.UtcNow, desired.OrderBy(role => role, StringComparer.Ordinal).ToList()));
    }

    private async Task<Dictionary<Guid, IReadOnlyList<string>>> ReadRolesAsync(IEnumerable<Guid> userIds, CancellationToken cancellationToken)
    {
        var ids = userIds.Distinct().ToArray();
        if (ids.Length == 0) return [];
        var links = await (from link in database.UserRoles.AsNoTracking()
                           join role in database.Roles.AsNoTracking() on link.RoleId equals role.Id
                           where ids.Contains(link.UserId)
                           select new { link.UserId, Name = role.Name! }).ToListAsync(cancellationToken);
        return links.GroupBy(link => link.UserId).ToDictionary(
            group => group.Key,
            group => (IReadOnlyList<string>)group.Select(item => item.Name).OrderBy(name => name, StringComparer.Ordinal).ToList());
    }

    private async Task<bool> IsLastAdministratorAsync(CancellationToken cancellationToken) => await AdministratorCountAsync(cancellationToken) <= 1;

    private async Task<int> AdministratorCountAsync(CancellationToken cancellationToken)
    {
        var roleId = await database.Roles.AsNoTracking().Where(role => role.NormalizedName == AdminAccessBootstrapper.AdministratorRole.ToUpperInvariant())
            .Select(role => (Guid?)role.Id).SingleOrDefaultAsync(cancellationToken);
        return roleId is null ? 0 : await database.UserRoles.CountAsync(link => link.RoleId == roleId, cancellationToken);
    }

    private async Task WriteAuditAsync(Guid actorId, Guid targetId, string action, string result, string reason, CancellationToken cancellationToken)
    {
        database.AdminAuditEvents.Add(new AdminAuditEvent { ActorUserId = actorId, TargetUserId = targetId, Action = action, Result = result, Reason = reason });
        await database.SaveChangesAsync(cancellationToken);
    }

    private Guid CurrentUserId() => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    private static bool TryReadReason(string? value, out string reason)
    {
        reason = value?.Trim() ?? string.Empty;
        return reason.Length is >= 3 and <= 500;
    }

    private sealed record UserProjection(Guid Id, string? DisplayName, string Email, DateTimeOffset? RegisteredAt, bool IsBlocked);
}
