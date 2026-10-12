using Microsoft.AspNetCore.Mvc;
using VeroEqulibraFit.Application.Exercises;
using VeroEqulibraFit.Contracts.Exercises;
namespace VeroEqulibraFit.Api.Controllers;
[ApiController, Route("api/v1/exercises")]
public sealed class ExercisesController(ExerciseSearchService searchService) : ControllerBase
{
    [HttpPost("search-before-ai")]
    public ActionResult<ExerciseSuggestionResponse> SearchBeforeAi([FromBody] ExerciseSuggestionRequest request)
    { if (string.IsNullOrWhiteSpace(request.Query) || request.Query.Length > 160) return BadRequest(new { error = "Informe entre 1 e 160 caracteres." }); return Ok(searchService.SearchBeforeAi(request)); }
}
