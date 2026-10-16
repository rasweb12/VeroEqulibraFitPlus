namespace VeroEqulibraFit.Contracts.Nutrition;

public sealed record GenerateNutritionPlanRequest(string Objective, string? Routine, IReadOnlyList<string>? Preferences, IReadOnlyList<string>? Restrictions, int MinCalories = 1400, int MaxCalories = 2400, decimal? ProteinTargetGrams = null);
public sealed record ApproveNutritionPlanRequest(string Name, string ContentJson);
public sealed record NutritionPlanResponse(Guid Id, string Name, string ContentJson, bool IsAiGenerated, bool IsApprovedByUser, DateTimeOffset CreatedAt, DateTimeOffset? ArchivedAt);
