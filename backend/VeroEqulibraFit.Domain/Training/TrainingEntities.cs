namespace VeroEqulibraFit.Domain.Training;

public sealed class TrainingPlan
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid OwnerId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Objective { get; set; } = string.Empty;
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
    public int Revision { get; set; } = 1;
    public DateTimeOffset? DeletedAt { get; set; }
    public List<TrainingPlanExercise> Exercises { get; set; } = [];
}

public sealed class TrainingPlanExercise
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid TrainingPlanId { get; set; }
    public string ExerciseId { get; set; } = string.Empty;
    public int Position { get; set; }
    public int Sets { get; set; }
    public string Repetitions { get; set; } = string.Empty;
    public decimal? TargetLoadKg { get; set; }
    public int RestSeconds { get; set; }
    public string? Notes { get; set; }
}

public sealed class TrainingSession
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid OwnerId { get; set; }
    public Guid TrainingPlanId { get; set; }
    public DateTimeOffset StartedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? FinishedAt { get; set; }
    public string SnapshotJson { get; set; } = "{}";
}

public sealed class SyncOperation
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid OwnerId { get; set; }
    public string IdempotencyKey { get; set; } = string.Empty;
    public string OperationType { get; set; } = string.Empty;
    public string PayloadHash { get; set; } = string.Empty;
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
