namespace VeroEqulibraFit.Contracts.Admin;

public sealed record AdminCatalogExerciseListItem(string Id, string Name, string PrimaryMuscle, string Equipment, bool IsPublished, int MediaCount, DateTimeOffset UpdatedAt);
public sealed record AdminCatalogExercisePage(IReadOnlyList<AdminCatalogExerciseListItem> Items, int Page, int PageSize, int TotalCount);
public sealed record AdminCatalogMediaItem(Guid Id, string AssetPath, string? Label, bool IsPrimary);
public sealed record AdminCatalogExerciseDetail(string Id, string Name, string PrimaryMuscle, string Equipment, string Instructions, bool IsPublished, IReadOnlyList<AdminCatalogMediaItem> Media);
public sealed record SaveAdminCatalogExerciseRequest(string Id, string Name, string PrimaryMuscle, string Equipment, string Instructions, bool IsPublished, string Reason, bool Confirmed);
public sealed record SaveAdminCatalogMediaRequest(string AssetPath, string? Label, bool IsPrimary, string Reason, bool Confirmed);
public sealed record CatalogMediaInventoryResponse(IReadOnlyList<string> RegisteredAssets, IReadOnlyList<string> UnmappedAssets);
