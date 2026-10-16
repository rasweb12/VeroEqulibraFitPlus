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

public sealed record AnalyzeMealPhotoRequest(string ImageBase64, string MimeType, string? MealContext);
public sealed record RecognizedMealItemResponse(
    string Name,
    decimal Portion,
    string Unit,
    decimal Calories,
    decimal ProteinGrams,
    decimal CarbohydrateGrams,
    decimal FatGrams,
    decimal Confidence);
public sealed record AnalyzeMealPhotoResponse(
    decimal Confidence,
    IReadOnlyList<RecognizedMealItemResponse> Items,
    bool RequiresUserReview,
    string Model,
    bool FallbackUsed,
    string Message);
