namespace VeroEqulibraFit.Infrastructure.Data;

/// <summary>
/// A minimal, non-clinical audit record for a sensitive administrative action.
/// It intentionally stores identifiers and a human justification only; it
/// never stores credentials, health data, tokens, or request payloads.
/// </summary>
public sealed class AdminAuditEvent
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ActorUserId { get; set; }
    public Guid? TargetUserId { get; set; }
    public string Action { get; set; } = string.Empty;
    public string Result { get; set; } = string.Empty;
    public string? Reason { get; set; }
    public DateTimeOffset OccurredAt { get; set; } = DateTimeOffset.UtcNow;
}
