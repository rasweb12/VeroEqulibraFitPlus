namespace VeroEqulibraFit.Contracts.Admin;

public sealed record AdminUserListResponse(
    IReadOnlyList<AdminUserListItem> Items,
    int Page,
    int PageSize,
    int TotalCount);

public sealed record AdminUserListItem(
    Guid Id,
    string? DisplayName,
    string Email,
    DateTimeOffset? RegisteredAt,
    DateTimeOffset? LastAccessAt,
    bool IsBlocked,
    IReadOnlyList<string> Roles);

public sealed record AdminUserDetailResponse(
    Guid Id,
    string? DisplayName,
    string Email,
    DateTimeOffset? RegisteredAt,
    DateTimeOffset? LastAccessAt,
    bool IsBlocked,
    IReadOnlyList<string> Roles,
    IReadOnlyList<AdminAuditEventResponse> AuditEvents);

public sealed record AdminAuditEventResponse(
    Guid Id,
    Guid ActorUserId,
    string Action,
    string Result,
    string? Reason,
    DateTimeOffset OccurredAt);

public sealed record ChangeAdminUserStatusRequest(string Status, string Reason, bool Confirmed);
public sealed record ChangeAdminUserRolesRequest(IReadOnlyList<string> Roles, string Reason, bool Confirmed);
public sealed record AdminUserMutationResponse(Guid UserId, bool IsBlocked, IReadOnlyList<string> Roles);
public sealed record AdminRoleResponse(string Name);
