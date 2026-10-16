using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VeroEqulibraFit.Contracts.Training;
using VeroEqulibraFit.Domain.Training;
using VeroEqulibraFit.Infrastructure.Data;

namespace VeroEqulibraFit.Api.Controllers;

[ApiController, Authorize, Route("api/v1/training-plans")]
public sealed class TrainingPlansController(VeroEqulibraFitDbContext database) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<TrainingPlanResponse>>> List(CancellationToken cancellationToken)
    {
        var ownerId = GetOwnerId();
        if (ownerId is null) return Unauthorized();
        var plans = await database.TrainingPlans.AsNoTracking().Include(plan => plan.Exercises)
            .Where(plan => plan.OwnerId == ownerId && plan.DeletedAt == null).OrderByDescending(plan => plan.CreatedAt)
            .ToListAsync(cancellationToken);
        return Ok(plans.Select(ToResponse).ToList());
    }

    [HttpPost]
    public async Task<ActionResult<TrainingPlanResponse>> Create([FromBody] CreateTrainingPlanRequest request, CancellationToken cancellationToken)
    {
        var ownerId = GetOwnerId();
        if (ownerId is null) return Unauthorized();
        if (string.IsNullOrWhiteSpace(request.Name) || request.Name.Length > 160 || string.IsNullOrWhiteSpace(request.Objective) || request.Objective.Length > 500)
            return BadRequest(new { error = "Nome e objetivo são obrigatórios e possuem tamanho inválido." });
        var exercises = request.Exercises ?? [];
        if (exercises.Count > 100 || exercises.Any(exercise => string.IsNullOrWhiteSpace(exercise.ExerciseId) || exercise.ExerciseId.Length > 120 || exercise.Sets is < 0 or > 100 || exercise.RestSeconds is < 0 or > 3600 || string.IsNullOrWhiteSpace(exercise.Repetitions) || exercise.Repetitions.Length > 32))
            return BadRequest(new { error = "Um ou mais exercícios são inválidos." });
        var plan = new TrainingPlan { OwnerId = ownerId.Value, Name = request.Name.Trim(), Objective = request.Objective.Trim() };
        plan.Exercises = exercises.OrderBy(exercise => exercise.Position).Select((exercise, position) => new TrainingPlanExercise
        {
            ExerciseId = exercise.ExerciseId.Trim(), Position = position, Sets = exercise.Sets,
            Repetitions = exercise.Repetitions.Trim(), TargetLoadKg = exercise.TargetLoadKg,
            RestSeconds = exercise.RestSeconds, Notes = exercise.Notes?.Trim()
        }).ToList();
        database.TrainingPlans.Add(plan);
        await database.SaveChangesAsync(cancellationToken);
        return CreatedAtAction(nameof(List), new { id = plan.Id }, ToResponse(plan));
    }

    [HttpPost("{id:guid}/duplicate")]
    public async Task<ActionResult<TrainingPlanResponse>> Duplicate(Guid id, CancellationToken cancellationToken)
    {
        var ownerId = GetOwnerId();
        if (ownerId is null) return Unauthorized();
        var source = await database.TrainingPlans.Include(plan => plan.Exercises)
            .SingleOrDefaultAsync(plan => plan.Id == id && plan.OwnerId == ownerId && plan.DeletedAt == null, cancellationToken);
        if (source is null) return NotFound();
        var copy = new TrainingPlan { OwnerId = ownerId.Value, Name = $"{source.Name} (cópia)", Objective = source.Objective };
        copy.Exercises = source.Exercises.OrderBy(exercise => exercise.Position).Select((exercise, position) => new TrainingPlanExercise
        {
            ExerciseId = exercise.ExerciseId, Position = position, Sets = exercise.Sets, Repetitions = exercise.Repetitions,
            TargetLoadKg = exercise.TargetLoadKg, RestSeconds = exercise.RestSeconds, Notes = exercise.Notes
        }).ToList();
        database.TrainingPlans.Add(copy);
        await database.SaveChangesAsync(cancellationToken);
        return Ok(ToResponse(copy));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        var ownerId = GetOwnerId();
        if (ownerId is null) return Unauthorized();
        var plan = await database.TrainingPlans.SingleOrDefaultAsync(plan => plan.Id == id && plan.OwnerId == ownerId && plan.DeletedAt == null, cancellationToken);
        if (plan is null) return NotFound();
        plan.DeletedAt = DateTimeOffset.UtcNow;
        await database.SaveChangesAsync(cancellationToken);
        return NoContent();
    }

    private Guid? GetOwnerId() => Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub"), out var ownerId) ? ownerId : null;
    private static TrainingPlanResponse ToResponse(TrainingPlan plan) => new(plan.Id, plan.Name, plan.Objective, plan.CreatedAt,
        plan.Exercises.OrderBy(exercise => exercise.Position).Select(exercise => new TrainingPlanExerciseRequest(exercise.ExerciseId, exercise.Position, exercise.Sets, exercise.Repetitions, exercise.TargetLoadKg, exercise.RestSeconds, exercise.Notes)).ToList());
}
