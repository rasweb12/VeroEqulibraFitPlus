using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VeroEqulibraFit.Infrastructure.Data;

namespace VeroEqulibraFit.Api.Controllers;

/// <summary>Operational aggregate data. It intentionally excludes user profiles and private records.</summary>
[ApiController]
[Authorize(Policy = "admin")]
[Route("api/v1/admin/overview")]
public sealed class AdminOverviewController(VeroEqulibraFitDbContext database) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<AdminOverviewResponse>> Get(CancellationToken cancellationToken)
    {
        var result = new AdminOverviewResponse(
            await database.Users.CountAsync(cancellationToken),
            await database.TrainingPlans.IgnoreQueryFilters().CountAsync(cancellationToken),
            await database.MealEntries.IgnoreQueryFilters().CountAsync(cancellationToken),
            await database.NutritionPlans.IgnoreQueryFilters().CountAsync(cancellationToken),
            await database.CustomExercises.IgnoreQueryFilters().CountAsync(cancellationToken));
        return Ok(result);
    }
}

public sealed record AdminOverviewResponse(
    int Users,
    int TrainingPlans,
    int MealEntries,
    int NutritionPlans,
    int CustomExercises);
