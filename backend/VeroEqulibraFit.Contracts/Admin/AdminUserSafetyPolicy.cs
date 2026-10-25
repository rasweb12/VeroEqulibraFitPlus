namespace VeroEqulibraFit.Contracts.Admin;

/// <summary>Pure safeguards shared by administrative identity mutations.</summary>
public static class AdminUserSafetyPolicy
{
    public static bool CanChangeTarget(Guid actorId, Guid targetId) => actorId != targetId;

    public static bool CanRemoveAdministrator(
        IEnumerable<string> currentRoles,
        IEnumerable<string> desiredRoles,
        int administratorCount,
        string administratorRole)
    {
        var comparer = StringComparer.OrdinalIgnoreCase;
        return !(currentRoles.Contains(administratorRole, comparer)
            && !desiredRoles.Contains(administratorRole, comparer)
            && administratorCount <= 1);
    }
}
