using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;

namespace VeroEqulibraFit.Admin.Services;

/// <summary>Server-side, per-circuit session for the administrative API.</summary>
public sealed class AdminApiSession(IHttpClientFactory clients)
{
    private const string ClientName = "vero-api";
    private string? _accessToken;
    public bool IsAuthenticated => !string.IsNullOrWhiteSpace(_accessToken);
    public AdminOverview? Overview { get; private set; }

    public async Task<string?> SignInAsync(string email, string password, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password)) return "Informe e-mail e senha.";
        var client = clients.CreateClient(ClientName);
        using var response = await client.PostAsJsonAsync("api/v1/auth/login", new { email = email.Trim(), password }, cancellationToken);
        if (response.StatusCode is HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden) return "Não foi possível autenticar esta conta administrativa.";
        if (!response.IsSuccessStatusCode) return "A autenticação administrativa está indisponível. Tente novamente.";
        var token = await response.Content.ReadFromJsonAsync<AuthToken>(cancellationToken: cancellationToken);
        if (string.IsNullOrWhiteSpace(token?.AccessToken)) return "A API retornou uma sessão inválida.";
        _accessToken = token.AccessToken;
        var error = await RefreshAsync(cancellationToken);
        if (error is null) return null;
        SignOut();
        return error;
    }

    public async Task<string?> RefreshAsync(CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(_accessToken)) return "Entre para acessar a operação.";
        var client = clients.CreateClient(ClientName);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _accessToken);
        using var response = await client.GetAsync("api/v1/admin/overview", cancellationToken);
        if (response.StatusCode is HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden) return "Esta conta não tem permissão administrativa.";
        if (!response.IsSuccessStatusCode) return "Não foi possível carregar os indicadores operacionais.";
        Overview = await response.Content.ReadFromJsonAsync<AdminOverview>(cancellationToken: cancellationToken);
        return Overview is null ? "A API retornou indicadores inválidos." : null;
    }

    public void SignOut() { _accessToken = null; Overview = null; }
    public static Uri ReadBaseUrl(IConfiguration configuration)
    {
        var value = configuration["Api:BaseUrl"];
        if (!Uri.TryCreate(value, UriKind.Absolute, out var uri)) throw new InvalidOperationException("Admin Api:BaseUrl deve ser uma URL HTTPS válida.");
        return new Uri(uri.AbsoluteUri.TrimEnd('/') + '/');
    }
    private sealed record AuthToken(string AccessToken);
}

public sealed record AdminOverview(int Users, int TrainingPlans, int MealEntries, int NutritionPlans, int CustomExercises);
