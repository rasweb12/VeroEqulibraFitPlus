using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VeroEqulibraFit.Contracts.Nutrition;
using VeroEqulibraFit.Domain.Nutrition;
using VeroEqulibraFit.Infrastructure.Data;

namespace VeroEqulibraFit.Api.Controllers;

[ApiController, Authorize, Route("api/v1/meals")]
public sealed class MealsController(VeroEqulibraFitDbContext database) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<MealEntryResponse>>> List(CancellationToken cancellationToken)
    {
        var ownerId = GetOwnerId();
        if (ownerId is null) return Unauthorized();
        var meals = await database.MealEntries.AsNoTracking().Where(meal => meal.OwnerId == ownerId)
            .OrderByDescending(meal => meal.ConsumedAt).ToListAsync(cancellationToken);
        return Ok(meals.Select(ToResponse).ToList());
    }

    [HttpPost]
    public async Task<ActionResult<MealEntryResponse>> Create([FromBody] CreateMealEntryRequest request, CancellationToken cancellationToken)
    {
        var ownerId = GetOwnerId();
        if (ownerId is null) return Unauthorized();
        if (string.IsNullOrWhiteSpace(request.Description) || request.Description.Length > 1000)
            return BadRequest(new { error = "Informe uma descrição de até 1000 caracteres." });
        if (new[] { request.EstimatedCalories, request.ProteinGrams, request.CarbohydrateGrams, request.FatGrams }.Any(value => value is < 0))
            return BadRequest(new { error = "Valores nutricionais não podem ser negativos." });
        var meal = new MealEntry
        {
            OwnerId = ownerId.Value,
            Description = request.Description.Trim(),
            ConsumedAt = request.ConsumedAt ?? DateTimeOffset.UtcNow,
            EstimatedCalories = request.EstimatedCalories,
            ProteinGrams = request.ProteinGrams,
            CarbohydrateGrams = request.CarbohydrateGrams,
            FatGrams = request.FatGrams,
            RequiresUserReview = true
        };
        database.MealEntries.Add(meal);
        await database.SaveChangesAsync(cancellationToken);
        return CreatedAtAction(nameof(List), new { id = meal.Id }, ToResponse(meal));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        var ownerId = GetOwnerId();
        if (ownerId is null) return Unauthorized();
        var meal = await database.MealEntries.SingleOrDefaultAsync(entry => entry.Id == id && entry.OwnerId == ownerId, cancellationToken);
        if (meal is null) return NotFound();
        meal.DeletedAt = DateTimeOffset.UtcNow;
        await database.SaveChangesAsync(cancellationToken);
        return NoContent();
    }

    private Guid? GetOwnerId() => Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub"), out var ownerId) ? ownerId : null;
    private static MealEntryResponse ToResponse(MealEntry meal) => new(meal.Id, meal.Description, meal.ConsumedAt, meal.EstimatedCalories, meal.ProteinGrams, meal.CarbohydrateGrams, meal.FatGrams, meal.RequiresUserReview);
}
