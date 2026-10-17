using System.Text.Json;

namespace VeroEqulibraFit.Contracts.Sync;

/// Batch sent by a single authenticated device. The owner is intentionally
/// absent: it is always obtained from the bearer token on the server.
public sealed record SyncPushRequest(IReadOnlyList<SyncPushOperationRequest> Operations);

public sealed record SyncPushOperationRequest(
    string OperationId,
    string EntityType,
    Guid EntityId,
    string OperationType,
    JsonElement Payload,
    string ClientVersion);

public sealed record SyncPushOperationResponse(
    string OperationId,
    string Status,
    string? ErrorCode = null);

public sealed record SyncPushResponse(IReadOnlyList<SyncPushOperationResponse> Operations);
