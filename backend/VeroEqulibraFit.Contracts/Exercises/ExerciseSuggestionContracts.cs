namespace VeroEqulibraFit.Contracts.Exercises;
public sealed record ExerciseSuggestionRequest(string Query);
public sealed record ExerciseSuggestionResponse(string Status, string? ExistingExerciseId, string? Name, IReadOnlyList<string> Aliases, string? PrimaryMuscle, IReadOnlyList<string> SecondaryMuscles, string? Equipment, string? Difficulty, IReadOnlyList<string> Instructions, IReadOnlyList<string> CommonErrors, IReadOnlyList<string> SafetyTips, IReadOnlyList<string> Alternatives, bool RequiresUserConfirmation);
