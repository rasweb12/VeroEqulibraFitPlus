using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection;
using VeroEqulibraFit.Infrastructure.Data;

namespace VeroEqulibraFit.Infrastructure;

public static class DependencyInjection
{
    public static IdentityBuilder AddVeroEqulibraFitInfrastructure(this IServiceCollection services, string connectionString)
    {
        services.AddDbContext<VeroEqulibraFitDbContext>(options => options.UseNpgsql(connectionString));
        var identityBuilder = services.AddIdentityCore<AppUser>(options =>
        {
            options.User.RequireUniqueEmail = true;
            options.Password.RequiredLength = 10;
            options.Password.RequireDigit = true;
            options.Password.RequireUppercase = true;
            options.Password.RequireLowercase = true;
            options.Password.RequireNonAlphanumeric = false;
            options.SignIn.RequireConfirmedEmail = false;
        });
        identityBuilder
            .AddRoles<AppRole>()
            .AddEntityFrameworkStores<VeroEqulibraFitDbContext>();
        return identityBuilder;
    }
}
