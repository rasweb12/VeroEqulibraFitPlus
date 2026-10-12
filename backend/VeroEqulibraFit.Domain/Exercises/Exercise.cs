namespace VeroEqulibraFit.Domain.Exercises;
public sealed record Exercise(string Id, string Name, string PrimaryMuscle, IReadOnlyList<string> Aliases, IReadOnlyList<string> Equipment, bool IsOfficial, Guid? OwnerId = null);
