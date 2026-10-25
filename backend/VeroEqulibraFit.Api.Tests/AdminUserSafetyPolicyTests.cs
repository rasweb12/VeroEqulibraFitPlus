using VeroEqulibraFit.Contracts.Admin;

namespace VeroEqulibraFit.Api.Tests;

public sealed class AdminUserSafetyPolicyTests
{
    private const string Administrator = "Administrator";

    [Fact]
    public void Rejects_self_mutation()
    {
        var id = Guid.NewGuid();
        Assert.False(AdminUserSafetyPolicy.CanChangeTarget(id, id));
    }

    [Fact]
    public void Allows_mutation_of_another_account()
    {
        Assert.True(AdminUserSafetyPolicy.CanChangeTarget(Guid.NewGuid(), Guid.NewGuid()));
    }

    [Fact]
    public void Prevents_removing_last_administrator()
    {
        Assert.False(AdminUserSafetyPolicy.CanRemoveAdministrator([Administrator], [], 1, Administrator));
    }

    [Fact]
    public void Allows_removing_administrator_when_another_remains()
    {
        Assert.True(AdminUserSafetyPolicy.CanRemoveAdministrator([Administrator], [], 2, Administrator));
    }

    [Fact]
    public void Allows_unrelated_role_change_for_last_administrator()
    {
        Assert.True(AdminUserSafetyPolicy.CanRemoveAdministrator([Administrator], [Administrator], 1, Administrator));
    }
}
