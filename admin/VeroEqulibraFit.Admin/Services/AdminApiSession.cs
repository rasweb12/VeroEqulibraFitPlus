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
        if (!IsAuthenticated) return "Entre para acessar a operação.";
        using var response = await AuthorizedClient().GetAsync("api/v1/admin/overview", cancellationToken);
        if (response.StatusCode is HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden) return "Esta conta não tem permissão administrativa.";
        if (!response.IsSuccessStatusCode) return "Não foi possível carregar os indicadores operacionais.";
        Overview = await response.Content.ReadFromJsonAsync<AdminOverview>(cancellationToken: cancellationToken);
        return Overview is null ? "A API retornou indicadores inválidos." : null;
    }

    public async Task<AdminUserPageResult> ListUsersAsync(int page, string? search, string status, string? role, CancellationToken cancellationToken = default)
    {
        if (!IsAuthenticated) return new(null, "Entre para acessar os usuários.");
        var uri = $"api/v1/admin/users?page={page}&pageSize=25&status={Uri.EscapeDataString(status)}";
        if (!string.IsNullOrWhiteSpace(search)) uri += $"&query={Uri.EscapeDataString(search.Trim())}";
        if (!string.IsNullOrWhiteSpace(role)) uri += $"&role={Uri.EscapeDataString(role.Trim())}";
        using var response = await AuthorizedClient().GetAsync(uri, cancellationToken);
        if (response.StatusCode is HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden) return new(null, "Sua sessão não tem permissão administrativa.");
        if (!response.IsSuccessStatusCode) return new(null, "Não foi possível carregar os usuários.");
        return new(await response.Content.ReadFromJsonAsync<AdminUserPage>(cancellationToken: cancellationToken), null);
    }

    public async Task<AdminUserDetailResult> GetUserAsync(Guid id, CancellationToken cancellationToken = default)
    {
        if (!IsAuthenticated) return new(null, "Entre para acessar os usuários.");
        using var response = await AuthorizedClient().GetAsync($"api/v1/admin/users/{id}", cancellationToken);
        if (response.StatusCode == HttpStatusCode.NotFound) return new(null, "Usuário não encontrado.");
        if (!response.IsSuccessStatusCode) return new(null, "Não foi possível carregar o usuário.");
        return new(await response.Content.ReadFromJsonAsync<AdminUserDetail>(cancellationToken: cancellationToken), null);
    }

    public async Task<IReadOnlyList<AdminRole>> GetRolesAsync(CancellationToken cancellationToken = default)
    {
        if (!IsAuthenticated) return [];
        using var response = await AuthorizedClient().GetAsync("api/v1/admin/users/roles", cancellationToken);
        return response.IsSuccessStatusCode ? await response.Content.ReadFromJsonAsync<IReadOnlyList<AdminRole>>(cancellationToken: cancellationToken) ?? [] : [];
    }

    public async Task<string?> ChangeUserStatusAsync(Guid id, string status, string reason, bool confirmed, CancellationToken cancellationToken = default) =>
        await MutateAsync($"api/v1/admin/users/{id}/status", new { status, reason, confirmed }, cancellationToken);

    public async Task<string?> ChangeUserRolesAsync(Guid id, IReadOnlyList<string> roles, string reason, bool confirmed, CancellationToken cancellationToken = default) =>
        await MutateAsync($"api/v1/admin/users/{id}/roles", new { roles, reason, confirmed }, cancellationToken);

    private async Task<string?> MutateAsync(string path, object body, CancellationToken cancellationToken)
    {
        if (!IsAuthenticated) return "Entre para executar esta ação.";
        using var response = await AuthorizedClient().PutAsJsonAsync(path, body, cancellationToken);
        if (response.IsSuccessStatusCode) return null;
        if (response.StatusCode is HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden) return "Sua sessão não tem permissão para esta ação.";
        if (response.StatusCode == HttpStatusCode.Conflict) return "A operação foi bloqueada para preservar o último administrador ativo.";
        var problem = await response.Content.ReadFromJsonAsync<ApiProblem>(cancellationToken: cancellationToken);
        return problem?.Title ?? "Não foi possível concluir a alteração.";
    }

    public void SignOut() { _accessToken = null; Overview = null; }
    public static Uri ReadBaseUrl(IConfiguration configuration)
    {
        var value = configuration["Api:BaseUrl"];
        if (!Uri.TryCreate(value, UriKind.Absolute, out var uri)) throw new InvalidOperationException("Admin Api:BaseUrl deve ser uma URL HTTPS válida.");
        return new Uri(uri.AbsoluteUri.TrimEnd('/') + '/');
    }
    private HttpClient AuthorizedClient()
    {
        var client = clients.CreateClient(ClientName);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _accessToken);
        return client;
    }
    private sealed record AuthToken(string AccessToken);
    private sealed record ApiProblem(string? Title);
}

public sealed record AdminOverview(int Users, int TrainingPlans, int MealEntries, int NutritionPlans, int? CustomExercises);
public sealed record AdminUserPage(IReadOnlyList<AdminUserListItem> Items, int Page, int PageSize, int TotalCount);
public sealed record AdminUserListItem(Guid Id, string? DisplayName, string Email, DateTimeOffset? RegisteredAt, DateTimeOffset? LastAccessAt, bool IsBlocked, IReadOnlyList<string> Roles);
public sealed record AdminAuditEvent(Guid Id, Guid ActorUserId, string Action, string Result, string? Reason, DateTimeOffset OccurredAt);
public sealed record AdminUserDetail(Guid Id, string? DisplayName, string Email, DateTimeOffset? RegisteredAt, DateTimeOffset? LastAccessAt, bool IsBlocked, IReadOnlyList<string> Roles, IReadOnlyList<AdminAuditEvent> AuditEvents);
public sealed record AdminRole(string Name);
public sealed record AdminUserPageResult(AdminUserPage? Page, string? Error);
public sealed record AdminUserDetailResult(AdminUserDetail? User, string? Error);
