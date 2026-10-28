using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VeroEqulibraFit.Api.Services;
using VeroEqulibraFit.Contracts.Admin;
using VeroEqulibraFit.Domain.Training;
using VeroEqulibraFit.Infrastructure.Data;

namespace VeroEqulibraFit.Api.Controllers;

[ApiController]
[Authorize(Policy = "admin")]
[Route("api/v1/admin/catalog")]
public sealed class AdminCatalogController(VeroEqulibraFitDbContext database) : ControllerBase
{
    [HttpGet("exercises")]
    public async Task<ActionResult<AdminCatalogExercisePage>> ListExercises(
        [FromQuery] int page = 1, [FromQuery] int pageSize = 25, [FromQuery] string? query = null,
        [FromQuery] string? muscle = null, [FromQuery] string? equipment = null, [FromQuery] string? publication = null,
        CancellationToken cancellationToken = default)
    {
        if (page < 1) return BadRequest(new { error = "page deve ser maior que zero." });
        pageSize = Math.Clamp(pageSize, 1, 100);
        var items = database.ExerciseCatalogItems.AsNoTracking();
        if (!string.IsNullOrWhiteSpace(query))
        {
            var term = query.Trim();
            if (term.Length > 160) return BadRequest(new { error = "pesquisa longa demais." });
            items = items.Where(item => EF.Functions.ILike(item.Name, $"%{term}%"));
        }
        if (!string.IsNullOrWhiteSpace(muscle)) items = items.Where(item => item.PrimaryMuscle == muscle.Trim());
        if (!string.IsNullOrWhiteSpace(equipment)) items = items.Where(item => item.Equipment == equipment.Trim());
        if (string.Equals(publication, "published", StringComparison.OrdinalIgnoreCase)) items = items.Where(item => item.IsPublished);
        if (string.Equals(publication, "unpublished", StringComparison.OrdinalIgnoreCase)) items = items.Where(item => !item.IsPublished);
        var total = await items.CountAsync(cancellationToken);
        var pageItems = await items.OrderBy(item => item.Name).ThenBy(item => item.Id).Skip((page - 1) * pageSize).Take(pageSize)
            .Select(item => new AdminCatalogExerciseListItem(item.Id, item.Name, item.PrimaryMuscle, item.Equipment, item.IsPublished, item.Media.Count, item.UpdatedAt))
            .ToListAsync(cancellationToken);
        return Ok(new AdminCatalogExercisePage(pageItems, page, pageSize, total));
    }

    [HttpGet("exercises/{id}")]
    public async Task<ActionResult<AdminCatalogExerciseDetail>> GetExercise(string id, CancellationToken cancellationToken)
    {
        var item = await database.ExerciseCatalogItems.AsNoTracking().Include(entry => entry.Media)
            .SingleOrDefaultAsync(entry => entry.Id == id, cancellationToken);
        return item is null ? NotFound() : Ok(ToDetail(item));
    }

    [HttpPut("exercises/{id}")]
    public async Task<ActionResult<AdminCatalogExerciseDetail>> SaveExercise(string id, SaveAdminCatalogExerciseRequest request, CancellationToken cancellationToken)
    {
        if (!Confirmed(request.Reason, request.Confirmed) || !ValidId(id) || !string.Equals(id, request.Id, StringComparison.Ordinal))
            return BadRequest(new { error = "ID estável, confirmação e justificativa entre 3 e 500 caracteres são obrigatórios." });
        if (!ValidText(request.Name, 160) || !ValidText(request.PrimaryMuscle, 80) || !ValidText(request.Equipment, 80) || request.Instructions?.Trim().Length > 4000)
            return BadRequest(new { error = "Revise os campos obrigatórios e seus limites." });
        var item = await database.ExerciseCatalogItems.Include(entry => entry.Media).SingleOrDefaultAsync(entry => entry.Id == id, cancellationToken);
        var action = item is null ? "catalog.exercise.create" : "catalog.exercise.update";
        if (item is null)
        {
            item = new ExerciseCatalogItem { Id = id };
            database.ExerciseCatalogItems.Add(item);
        }
        item.Name = request.Name.Trim();
        item.PrimaryMuscle = request.PrimaryMuscle.Trim();
        item.Equipment = request.Equipment.Trim();
        item.Instructions = request.Instructions?.Trim() ?? string.Empty;
        item.IsPublished = request.IsPublished;
        item.UpdatedAt = DateTimeOffset.UtcNow;
        await AuditAsync(action, request.Reason, cancellationToken);
        await database.SaveChangesAsync(cancellationToken);
        return Ok(ToDetail(item));
    }

    [HttpPut("exercises/{id}/media/{mediaId:guid}")]
    public async Task<ActionResult<AdminCatalogExerciseDetail>> SaveMedia(string id, Guid mediaId, SaveAdminCatalogMediaRequest request, CancellationToken cancellationToken)
    {
        if (!Confirmed(request.Reason, request.Confirmed)) return BadRequest(new { error = "Confirmação e justificativa entre 3 e 500 caracteres são obrigatórias." });
        if (!ExerciseMediaInventory.Assets.Contains(request.AssetPath, StringComparer.Ordinal)) return BadRequest(new { error = "O arquivo não pertence ao inventário original de vídeos." });
        var item = await database.ExerciseCatalogItems.Include(entry => entry.Media).SingleOrDefaultAsync(entry => entry.Id == id, cancellationToken);
        if (item is null) return NotFound();
        var media = mediaId == Guid.Empty ? null : item.Media.SingleOrDefault(entry => entry.Id == mediaId);
        if (mediaId != Guid.Empty && media is null) return NotFound();
        if (media is null) { media = new ExerciseCatalogMedia { ExerciseId = item.Id }; item.Media.Add(media); }
        if (request.IsPrimary)
            foreach (var other in item.Media) other.IsPrimary = false;
        media.AssetPath = request.AssetPath;
        media.Label = request.Label?.Trim();
        media.IsPrimary = request.IsPrimary;
        item.UpdatedAt = DateTimeOffset.UtcNow;
        await AuditAsync("catalog.media.upsert", request.Reason, cancellationToken);
        await database.SaveChangesAsync(cancellationToken);
        return Ok(ToDetail(item));
    }

    [HttpGet("media-inventory")]
    public async Task<ActionResult<CatalogMediaInventoryResponse>> MediaInventory(CancellationToken cancellationToken)
    {
        var mapped = await database.ExerciseCatalogMedia.AsNoTracking().Select(media => media.AssetPath).ToListAsync(cancellationToken);
        var unmapped = ExerciseMediaInventory.Assets.Except(mapped, StringComparer.Ordinal).ToList();
        return Ok(new CatalogMediaInventoryResponse(ExerciseMediaInventory.Assets, unmapped));
    }

    private async Task AuditAsync(string action, string reason, CancellationToken cancellationToken)
    {
        database.AdminAuditEvents.Add(new AdminAuditEvent { ActorUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!), Action = action, Result = "accepted", Reason = reason.Trim() });
        await Task.CompletedTask;
    }
    private static bool Confirmed(string? reason, bool confirmed) => confirmed && reason?.Trim().Length is >= 3 and <= 500;
    private static bool ValidText(string? value, int max) => !string.IsNullOrWhiteSpace(value) && value.Trim().Length <= max;
    private static bool ValidId(string value) => System.Text.RegularExpressions.Regex.IsMatch(value, "^[a-z0-9]+(?:-[a-z0-9]+)*$");
    private static AdminCatalogExerciseDetail ToDetail(ExerciseCatalogItem item) => new(item.Id, item.Name, item.PrimaryMuscle, item.Equipment, item.Instructions, item.IsPublished, item.Media.OrderByDescending(media => media.IsPrimary).ThenBy(media => media.AssetPath).Select(media => new AdminCatalogMediaItem(media.Id, media.AssetPath, media.Label, media.IsPrimary)).ToList());
}
