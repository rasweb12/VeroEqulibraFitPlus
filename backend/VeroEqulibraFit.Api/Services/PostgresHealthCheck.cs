using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using VeroEqulibraFit.Infrastructure.Data;

namespace VeroEqulibraFit.Api.Services;

/// <summary>Checks only database reachability for deployment readiness.</summary>
public sealed class PostgresHealthCheck(IServiceScopeFactory scopeFactory) : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await using var scope = scopeFactory.CreateAsyncScope();
            var database = scope.ServiceProvider.GetRequiredService<VeroEqulibraFitDbContext>();
            return await database.Database.CanConnectAsync(cancellationToken)
                ? HealthCheckResult.Healthy("PostgreSQL is reachable.")
                : HealthCheckResult.Unhealthy("PostgreSQL is unavailable.");
        }
        catch (Exception)
        {
            // Do not disclose connection details, credentials, or provider errors.
            return HealthCheckResult.Unhealthy("PostgreSQL is unavailable.");
        }
    }
}
