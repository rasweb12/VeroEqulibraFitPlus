namespace VeroEqulibraFit.Domain.Nutrition;

public sealed class MealEntry
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid OwnerId { get; set; }
    public string Description { get; set; } = string.Empty;
    public DateTimeOffset ConsumedAt { get; set; } = DateTimeOffset.UtcNow;
    public decimal? EstimatedCalories { get; set; }
    public decimal? ProteinGrams { get; set; }
    public decimal? CarbohydrateGrams { get; set; }
    public decimal? FatGrams { get; set; }
    public bool RequiresUserReview { get; set; } = true;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
    public int Revision { get; set; } = 1;
    public DateTimeOffset? DeletedAt { get; set; }
}

public sealed class NutritionPlan
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid OwnerId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string ContentJson { get; set; } = "{}";
    public bool IsAiGenerated { get; set; }
    public bool IsApprovedByUser { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? ArchivedAt { get; set; }
    public DateTimeOffset? DeletedAt { get; set; }
}

/// <summary>Nutrition data supplied by an authorized catalog source or its owner.</summary>
public sealed class FoodProduct
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid? OwnerId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Brand { get; set; }
    public string Gtin { get; set; } = string.Empty;
    public decimal ReferenceQuantity { get; set; }
    public string ReferenceUnit { get; set; } = "g";
    public decimal? Calories { get; set; }
    public decimal? ProteinGrams { get; set; }
    public decimal? CarbohydrateGrams { get; set; }
    public decimal? FatGrams { get; set; }
    public decimal? FiberGrams { get; set; }
    public string Source { get; set; } = string.Empty;
    public bool IsApprovedCatalogItem { get; set; }
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
}
