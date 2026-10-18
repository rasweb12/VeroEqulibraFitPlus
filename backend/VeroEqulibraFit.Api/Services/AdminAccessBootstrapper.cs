using Microsoft.AspNetCore.Identity;
using VeroEqulibraFit.Infrastructure.Data;

namespace VeroEqulibraFit.Api.Services;

/// <summary>
/// Grants the first administrator only when the deployment explicitly opts in.
/// There is no default account, password, or implicit administrator.
/// </summary>
public static class AdminAccessBootstrapper
{
    public const string AdministratorRole = "Administrator";

    public static async Task ApplyAsync(IServiceProvider services, IConfiguration configuration, ILogger logger)
    {
        if (!bool.TryParse(configuration["AdminBootstrap:Enabled"], out var enabled) || !enabled)
            return;

        var email = configuration["AdminBootstrap:Email"]?.Trim();
        if (string.IsNullOrWhiteSpace(email))
        {
            logger.LogWarning("admin.bootstrap_skipped reason=missing_email");
            return;
        }

        using var scope = services.CreateScope();
        var roles = scope.ServiceProvider.GetRequiredService<RoleManager<AppRole>>();
        var users = scope.ServiceProvider.GetRequiredService<UserManager<AppUser>>();
        if (!await roles.RoleExistsAsync(AdministratorRole))
        {
            var createRole = await roles.CreateAsync(new AppRole { Name = AdministratorRole });
            if (!createRole.Succeeded)
            {
                logger.LogError("admin.bootstrap_failed action=create_role");
                return;
            }
        }

        var user = await users.FindByEmailAsync(email);
        if (user is null)
        {
            logger.LogWarning("admin.bootstrap_skipped reason=user_not_found");
            return;
        }
        if (await users.IsInRoleAsync(user, AdministratorRole))
            return;

        var grant = await users.AddToRoleAsync(user, AdministratorRole);
        if (grant.Succeeded)
            logger.LogInformation("admin.bootstrap_granted");
        else
            logger.LogError("admin.bootstrap_failed action=grant_role");
    }
}
