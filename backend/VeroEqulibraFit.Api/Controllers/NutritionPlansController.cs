using System.Security.Claims;
using System.Net;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VeroEqulibraFit.Api.Services;
using VeroEqulibraFit.Contracts.Nutrition;
using VeroEqulibraFit.Domain.Nutrition;
using VeroEqulibraFit.Infrastructure.Data;

namespace VeroEqulibraFit.Api.Controllers;

[ApiController, Authorize, Route("api/v1/nutrition-plans")]
public sealed class NutritionPlansController(
    VeroEqulibraFitDbContext database,
    GeminiAiClient gemini,
    ILogger<NutritionPlansController> logger) : ControllerBase
{
    [HttpPost("generate")]
    public async Task<ActionResult<string>> Generate(GenerateNutritionPlanRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Objective) || request.MinCalories is < 1000 or > 6000 || request.MaxCalories is < 1000 or > 6000 || request.MinCalories > request.MaxCalories)
            return BadRequest(new ProblemDetails { Title = "Os dados do plano são inválidos." });

        try
        {
            return Content(await gemini.GenerateNutritionPlanAsync(request, cancellationToken), "application/json");
        }
        catch (HttpRequestException exception)
        {
            // Never include the AI response body here: it could contain service
            // internals. The status and trace id let Render logs be correlated.
            logger.LogWarning(exception,
                "Nutrition plan gateway failed with upstream status {StatusCode}. TraceId: {TraceId}",
                exception.StatusCode, HttpContext.TraceIdentifier);
            var rateLimited = exception.StatusCode == HttpStatusCode.TooManyRequests;
            return Problem(
                statusCode: rateLimited ? StatusCodes.Status429TooManyRequests : StatusCodes.Status502BadGateway,
                title: rateLimited ? "O serviço de planos recebeu muitas solicitações." : "O serviço de planos alimentares está indisponível.",
                detail: rateLimited ? "Aguarde antes de tentar novamente." : "Tente novamente em alguns instantes.");
        }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            logger.LogWarning("Nutrition plan gateway timed out. TraceId: {TraceId}", HttpContext.TraceIdentifier);
            return Problem(
                statusCode: StatusCodes.Status504GatewayTimeout,
                title: "A geração do plano demorou mais que o esperado.",
                detail: "Tente novamente em alguns instantes.");
        }
    }
    [HttpPost]
    public async Task<ActionResult<NutritionPlanResponse>> Approve(ApproveNutritionPlanRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Name) || request.Name.Length > 160 || string.IsNullOrWhiteSpace(request.ContentJson)) return BadRequest();
        var owner = Owner(); if (owner is null) return Unauthorized();
        try { _ = System.Text.Json.JsonDocument.Parse(request.ContentJson); } catch { return BadRequest(); }
        var plan = new NutritionPlan { OwnerId = owner.Value, Name = request.Name.Trim(), ContentJson = request.ContentJson, IsAiGenerated = true, IsApprovedByUser = true };
        database.NutritionPlans.Add(plan); await database.SaveChangesAsync(cancellationToken); return Ok(ToResponse(plan));
    }
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<NutritionPlanResponse>>> List(CancellationToken cancellationToken)
    { var owner = Owner(); if (owner is null) return Unauthorized(); var plans = await database.NutritionPlans.Where(p => p.OwnerId == owner && p.DeletedAt == null).OrderByDescending(p => p.CreatedAt).ToListAsync(cancellationToken); return Ok(plans.Select(ToResponse).ToList()); }
    [HttpPut("{id:guid}")]
    public async Task<ActionResult<NutritionPlanResponse>> Update(Guid id, UpdateNutritionPlanRequest request, CancellationToken cancellationToken)
    {
        var owner = Owner();
        if (owner is null) return Unauthorized();
        if (string.IsNullOrWhiteSpace(request.Name) || request.Name.Length > 160 || string.IsNullOrWhiteSpace(request.ContentJson)) return BadRequest();
        try { _ = System.Text.Json.JsonDocument.Parse(request.ContentJson); } catch { return BadRequest(); }
        var plan = await database.NutritionPlans.SingleOrDefaultAsync(p => p.Id == id && p.OwnerId == owner, cancellationToken);
        if (plan is null || plan.ArchivedAt is not null) return NotFound();
        plan.Name = request.Name.Trim();
        plan.ContentJson = request.ContentJson;
        plan.IsApprovedByUser = true;
        await database.SaveChangesAsync(cancellationToken);
        return Ok(ToResponse(plan));
    }
    [HttpPost("{id:guid}/archive")]
    public async Task<IActionResult> Archive(Guid id, CancellationToken cancellationToken)
    { var owner = Owner(); if (owner is null) return Unauthorized(); var plan = await database.NutritionPlans.SingleOrDefaultAsync(p => p.Id == id && p.OwnerId == owner, cancellationToken); if (plan is null) return NotFound(); plan.ArchivedAt = DateTimeOffset.UtcNow; await database.SaveChangesAsync(cancellationToken); return NoContent(); }
    private Guid? Owner() => Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub"), out var id) ? id : null;
    private static NutritionPlanResponse ToResponse(NutritionPlan p) => new(p.Id, p.Name, p.ContentJson, p.IsAiGenerated, p.IsApprovedByUser, p.CreatedAt, p.ArchivedAt);
}
