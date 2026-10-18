namespace VeroEqulibraFit.Contracts.Nutrition;

public sealed record FoodProductResponse(Guid Id, string Name, string? Brand, string Gtin, decimal ReferenceQuantity, string ReferenceUnit, decimal? Calories, decimal? ProteinGrams, decimal? CarbohydrateGrams, decimal? FatGrams, decimal? FiberGrams, string Source, DateTimeOffset UpdatedAt);
public sealed record CreateFoodProductRequest(string Name, string? Brand, string Gtin, decimal ReferenceQuantity, string ReferenceUnit, decimal? Calories, decimal? ProteinGrams, decimal? CarbohydrateGrams, decimal? FatGrams, decimal? FiberGrams, string Source);
