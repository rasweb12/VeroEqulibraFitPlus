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

    [HttpGet("pull")]
    public async Task<ActionResult<SyncPullResponse>> Pull(
        [FromQuery] string? cursor,
        [FromQuery] int limit = 50,
        CancellationToken cancellationToken = default)
    {
        var ownerId = GetOwnerId();
        if (ownerId is null) return Unauthorized();
        limit = Math.Clamp(limit, 1, MaxBatchSize);
        if (!TryReadCursor(cursor, out var parsedCursor))
            return BadRequest(new { error = "cursor inválido" });
        var from = parsedCursor?.ChangedAt ?? DateTimeOffset.MinValue;
        var plans = await database.TrainingPlans.IgnoreQueryFilters().AsNoTracking().Include(plan => plan.Exercises)
            .Where(plan => plan.OwnerId == ownerId && plan.UpdatedAt >= from)
            .Select(plan => new { Plan = plan, ChangedAt = plan.UpdatedAt })
            .ToListAsync(cancellationToken);
        var meals = await database.MealEntries.IgnoreQueryFilters().AsNoTracking()
            .Where(meal => meal.OwnerId == ownerId && meal.UpdatedAt >= from)
            .Select(meal => new { Meal = meal, ChangedAt = meal.UpdatedAt })
            .ToListAsync(cancellationToken);
        var changes = plans.Select(item => ToPlanChange(item.Plan))
            .Concat(meals.Select(item => ToMealChange(item.Meal)))
            .OrderBy(change => change.ChangedAt)
            .ThenBy(change => change.EntityType, StringComparer.Ordinal)
            .ThenBy(change => change.EntityId)
            .Where(change => parsedCursor is null || IsAfter(change, parsedCursor))
            .Take(limit)
            .ToList();
        return Ok(new SyncPullResponse(
            changes,
            changes.Count == 0 ? cursor : WriteCursor(changes[^1]),
            changes.Count == limit));
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
                "training-plan.update" when operation.EntityType == "training-plan" => await UpdateTrainingPlan(ownerId, operation.EntityId, rawPayload, cancellationToken),
                "training-plan.delete" when operation.EntityType == "training-plan" => await DeleteTrainingPlan(ownerId, operation.EntityId, cancellationToken),
                "meal.create" when operation.EntityType == "meal" => await CreateMeal(ownerId, operation.EntityId, rawPayload, cancellationToken),
                "meal.update" when operation.EntityType == "meal" => await UpdateMeal(ownerId, operation.EntityId, rawPayload, cancellationToken),
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

    private async Task<SyncPushOperationResponse> UpdateTrainingPlan(Guid ownerId, Guid entityId, string payload, CancellationToken cancellationToken)
    {
        var request = JsonSerializer.Deserialize<UpdateTrainingPlanRequest>(payload, JsonOptions);
        if (request is null || request.BaseRevision < 1 || string.IsNullOrWhiteSpace(request.Name) || string.IsNullOrWhiteSpace(request.Objective)) return new(string.Empty, "rejected", "invalid_training_plan");
        var plan = await database.TrainingPlans.IgnoreQueryFilters().Include(item => item.Exercises).SingleOrDefaultAsync(item => item.Id == entityId && item.OwnerId == ownerId, cancellationToken);
        if (plan is null || plan.DeletedAt is not null) return new(string.Empty, "conflict", "entity_not_found");
        if (plan.Revision != request.BaseRevision) return new(string.Empty, "conflict", "revision_conflict");
        var exercises = request.Exercises ?? [];
        if (exercises.Count > 100 || exercises.Any(item => string.IsNullOrWhiteSpace(item.ExerciseId) || item.Sets is < 0 or > 100 || item.RestSeconds is < 0 or > 3600 || string.IsNullOrWhiteSpace(item.Repetitions))) return new(string.Empty, "rejected", "invalid_training_plan");
        database.TrainingPlanExercises.RemoveRange(plan.Exercises);
        plan.Exercises = exercises.OrderBy(item => item.Position).Select((item, position) => new TrainingPlanExercise { TrainingPlanId = plan.Id, ExerciseId = item.ExerciseId.Trim(), Position = position, Sets = item.Sets, Repetitions = item.Repetitions.Trim(), TargetLoadKg = item.TargetLoadKg, RestSeconds = item.RestSeconds, Notes = item.Notes?.Trim() }).ToList();
        plan.Name = request.Name.Trim(); plan.Objective = request.Objective.Trim(); plan.UpdatedAt = DateTimeOffset.UtcNow; plan.Revision++;
        return new(string.Empty, "accepted");
    }

    private async Task<SyncPushOperationResponse> UpdateMeal(Guid ownerId, Guid entityId, string payload, CancellationToken cancellationToken)
    {
        var request = JsonSerializer.Deserialize<UpdateMealEntryRequest>(payload, JsonOptions);
        if (request is null || request.BaseRevision < 1 || string.IsNullOrWhiteSpace(request.Description) || new[] { request.EstimatedCalories, request.ProteinGrams, request.CarbohydrateGrams, request.FatGrams }.Any(value => value is < 0)) return new(string.Empty, "rejected", "invalid_meal");
        var meal = await database.MealEntries.IgnoreQueryFilters().SingleOrDefaultAsync(item => item.Id == entityId && item.OwnerId == ownerId, cancellationToken);
        if (meal is null || meal.DeletedAt is not null) return new(string.Empty, "conflict", "entity_not_found");
        if (meal.Revision != request.BaseRevision) return new(string.Empty, "conflict", "revision_conflict");
        meal.Description = request.Description.Trim(); meal.ConsumedAt = request.ConsumedAt ?? meal.ConsumedAt; meal.EstimatedCalories = request.EstimatedCalories; meal.ProteinGrams = request.ProteinGrams; meal.CarbohydrateGrams = request.CarbohydrateGrams; meal.FatGrams = request.FatGrams; meal.UpdatedAt = DateTimeOffset.UtcNow; meal.Revision++;
        return new(string.Empty, "accepted");
    }

    private async Task<SyncPushOperationResponse> DeleteTrainingPlan(Guid ownerId, Guid entityId, CancellationToken cancellationToken)
    {
        var plan = await database.TrainingPlans.IgnoreQueryFilters()
            .SingleOrDefaultAsync(item => item.Id == entityId && item.OwnerId == ownerId, cancellationToken);
        if (plan is null) return new(string.Empty, "conflict", "entity_not_found");
        if (plan.DeletedAt is null)
        {
            plan.DeletedAt = DateTimeOffset.UtcNow;
            plan.UpdatedAt = plan.DeletedAt.Value;
            plan.Revision += 1;
        }
        return new(string.Empty, "accepted");
    }

    private async Task<SyncPushOperationResponse> DeleteMeal(Guid ownerId, Guid entityId, CancellationToken cancellationToken)
    {
        var meal = await database.MealEntries.IgnoreQueryFilters()
            .SingleOrDefaultAsync(item => item.Id == entityId && item.OwnerId == ownerId, cancellationToken);
        if (meal is null) return new(string.Empty, "conflict", "entity_not_found");
        if (meal.DeletedAt is null)
        {
            meal.DeletedAt = DateTimeOffset.UtcNow;
            meal.UpdatedAt = meal.DeletedAt.Value;
            meal.Revision += 1;
        }
        return new(string.Empty, "accepted");
    }

    private Guid? GetOwnerId() => Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub"), out var ownerId) ? ownerId : null;
    private static SyncPullChangeResponse ToPlanChange(TrainingPlan plan) => new(
        "training-plan", plan.Id, plan.DeletedAt is null ? "upsert" : "delete", plan.Revision, plan.UpdatedAt,
        JsonSerializer.SerializeToElement(new {
            id = plan.Id, name = plan.Name, objective = plan.Objective, revision = plan.Revision,
            exercises = plan.Exercises.OrderBy(exercise => exercise.Position).Select(exercise => new {
                exerciseId = exercise.ExerciseId, exercise.Position, exercise.Sets, exercise.Repetitions,
                exercise.TargetLoadKg, exercise.RestSeconds, exercise.Notes,
            }),
        }, JsonOptions));
    private static SyncPullChangeResponse ToMealChange(MealEntry meal) => new(
        "meal", meal.Id, meal.DeletedAt is null ? "upsert" : "delete", meal.Revision, meal.UpdatedAt,
        JsonSerializer.SerializeToElement(new {
            id = meal.Id, description = meal.Description, consumedAt = meal.ConsumedAt, revision = meal.Revision,
            meal.EstimatedCalories, meal.ProteinGrams, meal.CarbohydrateGrams, meal.FatGrams,
        }, JsonOptions));

    private static bool TryReadCursor(string? cursor, out SyncCursor? result)
    {
        result = null;
        if (string.IsNullOrWhiteSpace(cursor)) return true;
        try
        {
            var json = Encoding.UTF8.GetString(Convert.FromBase64String(cursor));
            var parsed = JsonSerializer.Deserialize<SyncCursor>(json, JsonOptions);
            if (parsed is null || parsed.EntityId == Guid.Empty || string.IsNullOrWhiteSpace(parsed.EntityType)) return false;
            result = parsed;
            return true;
        }
        catch (FormatException) { return false; }
        catch (JsonException) { return false; }
    }

    private static string WriteCursor(SyncPullChangeResponse change) => Convert.ToBase64String(
        Encoding.UTF8.GetBytes(JsonSerializer.Serialize(new SyncCursor(change.ChangedAt, change.EntityType, change.EntityId), JsonOptions)));

    private static bool IsAfter(SyncPullChangeResponse change, SyncCursor cursor)
    {
        var timestampComparison = change.ChangedAt.CompareTo(cursor.ChangedAt);
        if (timestampComparison != 0) return timestampComparison > 0;
        var typeComparison = string.CompareOrdinal(change.EntityType, cursor.EntityType);
        return typeComparison > 0 || typeComparison == 0 && change.EntityId.CompareTo(cursor.EntityId) > 0;
    }

    private sealed record SyncCursor(DateTimeOffset ChangedAt, string EntityType, Guid EntityId);
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
}
