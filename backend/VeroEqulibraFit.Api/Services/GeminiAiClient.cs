using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Serialization;
using VeroEqulibraFit.Contracts.Ai;
using VeroEqulibraFit.Contracts.Nutrition;

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

    public async Task<AnalyzeMealPhotoResponse> AnalyzeMealPhotoAsync(AnalyzeMealPhotoRequest request, CancellationToken cancellationToken)
    {
        var response = await SendAsync("/api/v1/meals/recognize", new
        {
            image_base64 = request.ImageBase64,
            meal_context = request.MealContext,
        }, cancellationToken);
        return new AnalyzeMealPhotoResponse(
            response.Confidence ?? 0,
            (response.Items ?? []).Select(item => new RecognizedMealItemResponse(
                item.Name ?? "Alimento não identificado",
                item.Portion ?? 0,
                item.Unit ?? "porção",
                item.Calories ?? 0,
                item.ProteinGrams ?? 0,
                item.CarbohydrateGrams ?? 0,
                item.FatGrams ?? 0,
                item.Confidence ?? 0)).ToList(),
            true,
            response.Model ?? "gemini",
            response.FallbackUsed,
            response.Message ?? "Revise os alimentos e porções antes de salvar.");
    }

    public async Task<string> GenerateNutritionPlanAsync(GenerateNutritionPlanRequest request, CancellationToken cancellationToken)
    {
        using var message = new HttpRequestMessage(HttpMethod.Post, "/api/v1/plans/generate") { Content = JsonContent.Create(new { objective = request.Objective, routine = request.Routine, preferences = request.Preferences ?? [], restrictions = request.Restrictions ?? [], min_calories = request.MinCalories, max_calories = request.MaxCalories, protein_target_g = request.ProteinTargetGrams }) };
        message.Headers.Add("X-Internal-Api-Key", _internalKey ?? string.Empty);
        using var response = await httpClient.SendAsync(message, cancellationToken);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadAsStringAsync(cancellationToken);
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
        [property: JsonPropertyName("requires_user_confirmation")] bool RequiresUserConfirmation = true,
        [property: JsonPropertyName("confidence")] decimal? Confidence = null,
        [property: JsonPropertyName("items")] IReadOnlyList<MealGatewayItem>? Items = null,
        [property: JsonPropertyName("requires_user_review")] bool RequiresUserReview = true,
        [property: JsonPropertyName("message")] string? Message = null);

    private sealed record MealGatewayItem(
        [property: JsonPropertyName("name")] string? Name = null,
        [property: JsonPropertyName("portion")] decimal? Portion = null,
        [property: JsonPropertyName("unit")] string? Unit = null,
        [property: JsonPropertyName("calories")] decimal? Calories = null,
        [property: JsonPropertyName("protein_g")] decimal? ProteinGrams = null,
        [property: JsonPropertyName("carbs_g")] decimal? CarbohydrateGrams = null,
        [property: JsonPropertyName("fat_g")] decimal? FatGrams = null,
        [property: JsonPropertyName("confidence")] decimal? Confidence = null);
}
