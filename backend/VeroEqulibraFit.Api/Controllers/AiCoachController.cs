using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VeroEqulibraFit.Api.Services;
using VeroEqulibraFit.Contracts.Ai;

namespace VeroEqulibraFit.Api.Controllers;

[ApiController, Authorize, Route("api/v1/ai/coach")]
public sealed class AiCoachController(GeminiAiClient gemini) : ControllerBase
{
    [HttpPost("messages")]
    public async Task<ActionResult<CoachMessageResponse>> SendMessage([FromBody] CoachMessageRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Message) || request.Message.Length > 2000)
            return BadRequest(new { error = "Informe uma mensagem entre 1 e 2000 caracteres." });
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        if (string.IsNullOrWhiteSpace(userId)) return Unauthorized();
        try { return Ok(await gemini.SendCoachMessageAsync(userId, request, cancellationToken)); }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested) { return StatusCode(504, new { error = "O Gemini demorou mais que o limite." }); }
        catch (HttpRequestException) { return StatusCode(503, new { error = "O serviço Gemini está indisponível." }); }
        catch (InvalidOperationException) { return StatusCode(502, new { error = "A resposta do serviço Gemini não foi aceita." }); }
    }
}
