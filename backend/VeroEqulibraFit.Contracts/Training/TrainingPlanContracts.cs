namespace VeroEqulibraFit.Contracts.Training;

public sealed record TrainingPlanExerciseRequest(
    string ExerciseId,
    int Position,
    int Sets,
    string Repetitions,
    decimal? TargetLoadKg,
    int RestSeconds,
    string? Notes);

public sealed record CreateTrainingPlanRequest(
    string Name,
    string Objective,
    IReadOnlyList<TrainingPlanExerciseRequest>? Exercises);

public sealed record TrainingPlanResponse(
    Guid Id,
    string Name,
    string Objective,
    DateTimeOffset CreatedAt,
    IReadOnlyList<TrainingPlanExerciseRequest> Exercises);
