using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Serialization;
using VeroEqulibraFit.Contracts.Ai;

namespace VeroEqulibraFit.Api.Services;

public sealed class GeminiAiClient(HttpClient httpClient, IConfiguration configuration)
{
    private readonly string? _internalKey = configuration["AI:InternalApiKey"];

    public async Task<CoachMessageResponse> SendCoachMessageAsync(string userId, CoachMessageRequest request, CancellationToken cancellationToken)
    {
        var response = await SendAsync("/api/v1/coach/chat", new CoachGatewayRequest(userId, request.SessionId, request.Message), cancellationToken);
        return new CoachMessageResponse(response.Content ?? response.Conteudo ?? "", response.Model ?? response.Modelo ?? "gemini", response.FallbackUsed, request.SessionId);
    }

    public async Task<ExerciseAiSuggestionResponse> SuggestExerciseAsync(ExerciseAiSuggestionRequest request, CancellationToken cancellationToken)
    {
        var response = await SendAsync("/api/v1/exercises/suggest", new { query = request.Query, known_catalog_names = Array.Empty<string>() }, cancellationToken);
        return new ExerciseAiSuggestionResponse(response.Status ?? "needs_clarification", null, response.Name, response.Aliases ?? [], response.PrimaryMuscle, response.SecondaryMuscles ?? [], response.Equipment, response.Difficulty, response.Instructions ?? [], response.CommonErrors ?? [], response.SafetyTips ?? [], response.Alternatives ?? [], response.RequiresUserConfirmation);
    }

    private async Task<GatewayResponse> SendAsync(string path, object payload, CancellationToken cancellationToken)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, path) { Content = JsonContent.Create(payload) };
        request.Headers.Add("X-Internal-Api-Key", _internalKey ?? string.Empty);
        using var response = await httpClient.SendAsync(request, cancellationToken);
        if (response.StatusCode is HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden)
            throw new InvalidOperationException("AI service authentication failed.");
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<GatewayResponse>(cancellationToken: cancellationToken)
            ?? throw new InvalidOperationException("AI service returned an empty response.");
    }

    private sealed record CoachGatewayRequest(string usuario_id, string? sessao_id, string mensagem);
    private sealed record GatewayResponse(
        [property: JsonPropertyName("conteudo")] string? Conteudo = null,
        [property: JsonPropertyName("content")] string? Content = null,
        [property: JsonPropertyName("modelo")] string? Modelo = null,
        [property: JsonPropertyName("model")] string? Model = null,
        [property: JsonPropertyName("fallback_used")] bool FallbackUsed = false,
        [property: JsonPropertyName("status")] string? Status = null,
        [property: JsonPropertyName("name")] string? Name = null,
        [property: JsonPropertyName("aliases")] IReadOnlyList<string>? Aliases = null,
        [property: JsonPropertyName("primary_muscle")] string? PrimaryMuscle = null,
        [property: JsonPropertyName("secondary_muscles")] IReadOnlyList<string>? SecondaryMuscles = null,
        [property: JsonPropertyName("equipment")] string? Equipment = null,
        [property: JsonPropertyName("difficulty")] string? Difficulty = null,
        [property: JsonPropertyName("instructions")] IReadOnlyList<string>? Instructions = null,
        [property: JsonPropertyName("common_errors")] IReadOnlyList<string>? CommonErrors = null,
        [property: JsonPropertyName("safety_tips")] IReadOnlyList<string>? SafetyTips = null,
        [property: JsonPropertyName("alternatives")] IReadOnlyList<string>? Alternatives = null,
        [property: JsonPropertyName("requires_user_confirmation")] bool RequiresUserConfirmation = true);
}
