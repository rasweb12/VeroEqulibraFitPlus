using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using VeroEqulibraFit.Application.Exercises;
using VeroEqulibraFit.Contracts.Exercises;
using VeroEqulibraFit.Contracts.Ai;
using VeroEqulibraFit.Api.Services;
namespace VeroEqulibraFit.Api.Controllers;
[ApiController, Authorize, Route("api/v1/exercises")]
public sealed class ExercisesController(ExerciseSearchService searchService, GeminiAiClient gemini) : ControllerBase
{
    [HttpPost("search-before-ai")]
    public ActionResult<ExerciseSuggestionResponse> SearchBeforeAi([FromBody] ExerciseSuggestionRequest request)
    { if (string.IsNullOrWhiteSpace(request.Query) || request.Query.Length > 160) return BadRequest(new { error = "Informe entre 1 e 160 caracteres." }); return Ok(searchService.SearchBeforeAi(request)); }

    [HttpPost("suggest")]
    public async Task<ActionResult<ExerciseAiSuggestionResponse>> Suggest([FromBody] ExerciseAiSuggestionRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Query) || request.Query.Length > 160)
            return BadRequest(new { error = "Informe entre 1 e 160 caracteres." });
        var catalogResult = searchService.SearchBeforeAi(new ExerciseSuggestionRequest(request.Query));
        if (catalogResult.Status == "existing_match")
            return Ok(new ExerciseAiSuggestionResponse(catalogResult.Status, catalogResult.ExistingExerciseId, catalogResult.Name, catalogResult.Aliases, catalogResult.PrimaryMuscle, catalogResult.SecondaryMuscles, catalogResult.Equipment, catalogResult.Difficulty, catalogResult.Instructions, catalogResult.CommonErrors, catalogResult.SafetyTips, catalogResult.Alternatives, true));
        try { return Ok(await gemini.SuggestExerciseAsync(request, cancellationToken)); }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested) { return StatusCode(504, new { error = "O Gemini demorou mais que o limite." }); }
        catch (HttpRequestException) { return StatusCode(503, new { error = "O serviço Gemini está indisponível." }); }
        catch (InvalidOperationException) { return StatusCode(502, new { error = "A resposta do serviço Gemini não foi aceita." }); }
    }
}
