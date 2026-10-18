namespace VeroEqulibraFit.Domain.Journal;

/// <summary>
/// Owner-scoped diary event used for habits, private notes and mission progress.
/// The payload is intentionally opaque to the sync layer; each client validates
/// its own kind-specific fields before queueing an operation.
/// </summary>
public sealed class JournalRecord
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid OwnerId { get; set; }
    public string Kind { get; set; } = string.Empty;
    public DateTimeOffset OccurredAt { get; set; } = DateTimeOffset.UtcNow;
    public string PayloadJson { get; set; } = "{}";
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
    public int Revision { get; set; } = 1;
    public DateTimeOffset? DeletedAt { get; set; }
}
