using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VeroEqulibraFit.Contracts.Nutrition;
using VeroEqulibraFit.Domain.Nutrition;
using VeroEqulibraFit.Infrastructure.Data;
using VeroEqulibraFit.Api.Services;

namespace VeroEqulibraFit.Api.Controllers;

[ApiController, Authorize, Route("api/v1/meals")]
public sealed class MealsController(VeroEqulibraFitDbContext database, GeminiAiClient gemini) : ControllerBase
{
    private const int MaxImageBytes = 5 * 1024 * 1024;

    [HttpPost("analyze-photo")]
    public async Task<ActionResult<AnalyzeMealPhotoResponse>> AnalyzePhoto([FromBody] AnalyzeMealPhotoRequest request, CancellationToken cancellationToken)
    {
        if (!IsAllowedImageMimeType(request.MimeType) || string.IsNullOrWhiteSpace(request.ImageBase64))
            return BadRequest(new { error = "Envie uma imagem JPEG, PNG ou WebP válida." });
        byte[] image;
        try { image = Convert.FromBase64String(request.ImageBase64); }
        catch (FormatException) { return BadRequest(new { error = "A imagem está inválida." }); }
        if (image.Length == 0 || image.Length > MaxImageBytes || !HasExpectedImageSignature(image, request.MimeType))
            return BadRequest(new { error = "A imagem deve ter até 5 MB." });
        try { return Ok(await gemini.AnalyzeMealPhotoAsync(request, cancellationToken)); }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested) { return StatusCode(504, new { error = "A análise demorou mais que o limite." }); }
        catch (HttpRequestException) { return StatusCode(503, new { error = "O serviço de análise está indisponível." }); }
        catch (InvalidOperationException) { return StatusCode(502, new { error = "A resposta da análise não foi aceita." }); }
    }

    [HttpPost("estimate-text")]
    public async Task<ActionResult<EstimateMealTextResponse>> EstimateText([FromBody] EstimateMealTextRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Description) || request.Description.Trim().Length is < 3 or > 600)
            return BadRequest(new { error = "Informe uma descrição entre 3 e 600 caracteres." });
        try { return Ok(await gemini.EstimateMealTextAsync(request with { Description = request.Description.Trim() }, cancellationToken)); }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested) { return StatusCode(504, new { error = "A estimativa demorou mais que o limite." }); }
        catch (HttpRequestException) { return StatusCode(503, new { error = "O serviço de estimativa está indisponível." }); }
        catch (InvalidOperationException) { return StatusCode(502, new { error = "A resposta da estimativa não foi aceita." }); }
    }
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<MealEntryResponse>>> List(CancellationToken cancellationToken)
    {
        var ownerId = GetOwnerId();
        if (ownerId is null) return Unauthorized();
        var meals = await database.MealEntries.AsNoTracking().Where(meal => meal.OwnerId == ownerId && meal.DeletedAt == null)
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
    private static bool IsAllowedImageMimeType(string mimeType) => mimeType.Equals("image/jpeg", StringComparison.OrdinalIgnoreCase)
        || mimeType.Equals("image/png", StringComparison.OrdinalIgnoreCase)
        || mimeType.Equals("image/webp", StringComparison.OrdinalIgnoreCase);
    private static bool HasExpectedImageSignature(byte[] image, string mimeType) => mimeType.ToLowerInvariant() switch
    {
        "image/jpeg" => image.Length >= 3 && image[0] == 0xFF && image[1] == 0xD8 && image[2] == 0xFF,
        "image/png" => image.Length >= 8 && image[0] == 0x89 && image[1] == 0x50 && image[2] == 0x4E && image[3] == 0x47,
        "image/webp" => image.Length >= 12 && image[0] == 0x52 && image[1] == 0x49 && image[2] == 0x46 && image[3] == 0x46
            && image[8] == 0x57 && image[9] == 0x45 && image[10] == 0x42 && image[11] == 0x50,
        _ => false,
    };
    private static MealEntryResponse ToResponse(MealEntry meal) => new(meal.Id, meal.Description, meal.ConsumedAt, meal.EstimatedCalories, meal.ProteinGrams, meal.CarbohydrateGrams, meal.FatGrams, meal.RequiresUserReview);
}
