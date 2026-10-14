namespace VeroEqulibraFit.Contracts.Nutrition;

public sealed record CreateMealEntryRequest(
    string Description,
    DateTimeOffset? ConsumedAt,
    decimal? EstimatedCalories,
    decimal? ProteinGrams,
    decimal? CarbohydrateGrams,
    decimal? FatGrams);

public sealed record MealEntryResponse(
    Guid Id,
    string Description,
    DateTimeOffset ConsumedAt,
    decimal? EstimatedCalories,
    decimal? ProteinGrams,
    decimal? CarbohydrateGrams,
    decimal? FatGrams,
    bool RequiresUserReview);
