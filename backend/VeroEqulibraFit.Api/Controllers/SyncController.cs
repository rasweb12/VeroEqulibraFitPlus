using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VeroEqulibraFit.Contracts.Nutrition;
using VeroEqulibraFit.Contracts.Sync;
using VeroEqulibraFit.Contracts.Training;
using VeroEqulibraFit.Domain.Nutrition;
using VeroEqulibraFit.Domain.Training;
using VeroEqulibraFit.Infrastructure.Data;

namespace VeroEqulibraFit.Api.Controllers;

[ApiController, Authorize, Route("api/v1/sync")]
public sealed class SyncController(VeroEqulibraFitDbContext database) : ControllerBase
{
    private const int MaxBatchSize = 50;
    private const int MaxPayloadBytes = 64 * 1024;

    [HttpPost("push")]
    public async Task<ActionResult<SyncPushResponse>> Push([FromBody] SyncPushRequest request, CancellationToken cancellationToken)
    {
        var ownerId = GetOwnerId();
        if (ownerId is null) return Unauthorized();
        if (request.Operations is null || request.Operations.Count is < 1 or > MaxBatchSize)
            return BadRequest(new { error = "Envie entre uma e cinquenta operações." });

        var results = new List<SyncPushOperationResponse>(request.Operations.Count);
        foreach (var operation in request.Operations)
            results.Add(await Apply(ownerId.Value, operation, cancellationToken));
        return Ok(new SyncPushResponse(results));
    }

    private async Task<SyncPushOperationResponse> Apply(Guid ownerId, SyncPushOperationRequest operation, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(operation.OperationId) || operation.OperationId.Length > 128 ||
            string.IsNullOrWhiteSpace(operation.EntityType) || operation.EntityType.Length > 64 ||
            string.IsNullOrWhiteSpace(operation.OperationType) || operation.OperationType.Length > 80 ||
            string.IsNullOrWhiteSpace(operation.ClientVersion) || operation.ClientVersion.Length > 80)
            return new(operation.OperationId, "rejected", "invalid_operation");

        var rawPayload = operation.Payload.GetRawText();
        if (Encoding.UTF8.GetByteCount(rawPayload) > MaxPayloadBytes)
            return new(operation.OperationId, "rejected", "payload_too_large");
        var hash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(rawPayload)));

        await using var transaction = await database.Database.BeginTransactionAsync(cancellationToken);
        var receipt = await database.SyncOperations.SingleOrDefaultAsync(item =>
            item.OwnerId == ownerId && item.IdempotencyKey == operation.OperationId, cancellationToken);
        if (receipt is not null)
        {
            await transaction.RollbackAsync(cancellationToken);
            return receipt.OperationType == operation.OperationType && receipt.PayloadHash == hash
                ? new(operation.OperationId, "duplicate")
                : new(operation.OperationId, "conflict", "idempotency_key_reused");
        }

        SyncPushOperationResponse result;
        try
        {
            result = operation.OperationType switch
            {
                "training-plan.create" when operation.EntityType == "training-plan" => await CreateTrainingPlan(ownerId, operation.EntityId, rawPayload, cancellationToken),
                "training-plan.delete" when operation.EntityType == "training-plan" => await DeleteTrainingPlan(ownerId, operation.EntityId, cancellationToken),
                "meal.create" when operation.EntityType == "meal" => await CreateMeal(ownerId, operation.EntityId, rawPayload, cancellationToken),
                "meal.delete" when operation.EntityType == "meal" => await DeleteMeal(ownerId, operation.EntityId, cancellationToken),
                _ => new(string.Empty, "rejected", "unsupported_operation"),
            };
        }
        catch (JsonException)
        {
            await transaction.RollbackAsync(cancellationToken);
            return new(operation.OperationId, "rejected", "invalid_payload");
        }
        if (result.Status != "accepted")
        {
            await transaction.RollbackAsync(cancellationToken);
            return result with { OperationId = operation.OperationId };
        }

        database.SyncOperations.Add(new SyncOperation
        {
            OwnerId = ownerId,
            IdempotencyKey = operation.OperationId,
            OperationType = operation.OperationType,
            PayloadHash = hash,
        });
        try
        {
            await database.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
            return result with { OperationId = operation.OperationId };
        }
        catch (DbUpdateException)
        {
            await transaction.RollbackAsync(cancellationToken);
            return new(operation.OperationId, "conflict", "concurrent_operation");
        }
    }

    private async Task<SyncPushOperationResponse> CreateTrainingPlan(Guid ownerId, Guid entityId, string payload, CancellationToken cancellationToken)
    {
        var request = JsonSerializer.Deserialize<CreateTrainingPlanRequest>(payload, JsonOptions);
        if (request is null || request.ClientId is not null && request.ClientId != entityId || string.IsNullOrWhiteSpace(request.Name) || request.Name.Length > 160 || string.IsNullOrWhiteSpace(request.Objective) || request.Objective.Length > 500)
            return new(string.Empty, "rejected", "invalid_training_plan");
        var exercises = request.Exercises ?? [];
        if (exercises.Count > 100 || exercises.Any(exercise => string.IsNullOrWhiteSpace(exercise.ExerciseId) || exercise.ExerciseId.Length > 120 || exercise.Sets is < 0 or > 100 || exercise.RestSeconds is < 0 or > 3600 || string.IsNullOrWhiteSpace(exercise.Repetitions) || exercise.Repetitions.Length > 32))
            return new(string.Empty, "rejected", "invalid_training_plan");
        if (await database.TrainingPlans.IgnoreQueryFilters().AnyAsync(plan => plan.Id == entityId, cancellationToken))
            return new(string.Empty, "conflict", "entity_already_exists");
        database.TrainingPlans.Add(new TrainingPlan
        {
            Id = entityId, OwnerId = ownerId, Name = request.Name.Trim(), Objective = request.Objective.Trim(),
            Exercises = exercises.OrderBy(exercise => exercise.Position).Select((exercise, position) => new TrainingPlanExercise
            {
                ExerciseId = exercise.ExerciseId.Trim(), Position = position, Sets = exercise.Sets, Repetitions = exercise.Repetitions.Trim(),
                TargetLoadKg = exercise.TargetLoadKg, RestSeconds = exercise.RestSeconds, Notes = exercise.Notes?.Trim(),
            }).ToList(),
        });
        return new(string.Empty, "accepted");
    }

    private async Task<SyncPushOperationResponse> CreateMeal(Guid ownerId, Guid entityId, string payload, CancellationToken cancellationToken)
    {
        var request = JsonSerializer.Deserialize<CreateMealEntryRequest>(payload, JsonOptions);
        if (request is null || request.ClientId is not null && request.ClientId != entityId || string.IsNullOrWhiteSpace(request.Description) || request.Description.Length > 1000 || new[] { request.EstimatedCalories, request.ProteinGrams, request.CarbohydrateGrams, request.FatGrams }.Any(value => value is < 0))
            return new(string.Empty, "rejected", "invalid_meal");
        if (await database.MealEntries.IgnoreQueryFilters().AnyAsync(meal => meal.Id == entityId, cancellationToken))
            return new(string.Empty, "conflict", "entity_already_exists");
        database.MealEntries.Add(new MealEntry
        {
            Id = entityId, OwnerId = ownerId, Description = request.Description.Trim(), ConsumedAt = request.ConsumedAt ?? DateTimeOffset.UtcNow,
            EstimatedCalories = request.EstimatedCalories, ProteinGrams = request.ProteinGrams, CarbohydrateGrams = request.CarbohydrateGrams,
            FatGrams = request.FatGrams, RequiresUserReview = true,
        });
        return new(string.Empty, "accepted");
    }

    private async Task<SyncPushOperationResponse> DeleteTrainingPlan(Guid ownerId, Guid entityId, CancellationToken cancellationToken)
    {
        var plan = await database.TrainingPlans.IgnoreQueryFilters()
            .SingleOrDefaultAsync(item => item.Id == entityId && item.OwnerId == ownerId, cancellationToken);
        if (plan is null) return new(string.Empty, "conflict", "entity_not_found");
        if (plan.DeletedAt is null) plan.DeletedAt = DateTimeOffset.UtcNow;
        return new(string.Empty, "accepted");
    }

    private async Task<SyncPushOperationResponse> DeleteMeal(Guid ownerId, Guid entityId, CancellationToken cancellationToken)
    {
        var meal = await database.MealEntries.IgnoreQueryFilters()
            .SingleOrDefaultAsync(item => item.Id == entityId && item.OwnerId == ownerId, cancellationToken);
        if (meal is null) return new(string.Empty, "conflict", "entity_not_found");
        if (meal.DeletedAt is null) meal.DeletedAt = DateTimeOffset.UtcNow;
        return new(string.Empty, "accepted");
    }

    private Guid? GetOwnerId() => Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub"), out var ownerId) ? ownerId : null;
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
}
