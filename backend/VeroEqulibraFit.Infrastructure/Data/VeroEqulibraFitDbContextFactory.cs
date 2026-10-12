using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace VeroEqulibraFit.Infrastructure.Data;

public sealed class VeroEqulibraFitDbContextFactory : IDesignTimeDbContextFactory<VeroEqulibraFitDbContext>
{
    public VeroEqulibraFitDbContext CreateDbContext(string[] args)
    {
        var options = new DbContextOptionsBuilder<VeroEqulibraFitDbContext>()
            .UseNpgsql("Host=localhost;Port=5432;Database=vero_equilibrafit_design;Username=design;Password=design")
            .Options;
        return new VeroEqulibraFitDbContext(options);
    }
}
