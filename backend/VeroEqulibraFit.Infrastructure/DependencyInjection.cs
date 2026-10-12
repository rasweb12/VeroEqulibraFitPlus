using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using VeroEqulibraFit.Infrastructure.Data;

namespace VeroEqulibraFit.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddVeroEqulibraFitInfrastructure(this IServiceCollection services, string connectionString)
    {
        services.AddDbContext<VeroEqulibraFitDbContext>(options => options.UseNpgsql(connectionString));
        return services;
    }
}
