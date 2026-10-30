namespace VeroEqulibraFit.Domain.Training;

/// <summary>Global, administrator-managed exercise content. It never contains a user's custom exercise.</summary>
public sealed class ExerciseCatalogItem
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string PrimaryMuscle { get; set; } = string.Empty;
    public string Equipment { get; set; } = string.Empty;
    public string Instructions { get; set; } = string.Empty;
    public bool IsPublished { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
    public List<ExerciseCatalogMedia> Media { get; set; } = [];
}

/// <summary>A manually verified media association. Asset paths are stored exactly as registered.</summary>
public sealed class ExerciseCatalogMedia
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string ExerciseId { get; set; } = string.Empty;
    public string AssetPath { get; set; } = string.Empty;
    public string? Label { get; set; }
    public bool IsPrimary { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
