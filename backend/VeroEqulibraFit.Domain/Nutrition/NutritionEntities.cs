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
