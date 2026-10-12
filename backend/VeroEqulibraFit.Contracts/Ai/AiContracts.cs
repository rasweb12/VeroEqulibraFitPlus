namespace VeroEqulibraFit.Contracts.Ai;

public sealed record CoachMessageRequest(string Message, string? SessionId = null);
public sealed record CoachMessageResponse(string Content, string Model, bool FallbackUsed, string? SessionId);

public sealed record ExerciseAiSuggestionRequest(string Query);
public sealed record ExerciseAiSuggestionResponse(
    string Status,
    string? ExistingExerciseId,
    string? Name,
    IReadOnlyList<string> Aliases,
    string? PrimaryMuscle,
    IReadOnlyList<string> SecondaryMuscles,
    string? Equipment,
    string? Difficulty,
    IReadOnlyList<string> Instructions,
    IReadOnlyList<string> CommonErrors,
    IReadOnlyList<string> SafetyTips,
    IReadOnlyList<string> Alternatives,
    bool RequiresUserConfirmation);
