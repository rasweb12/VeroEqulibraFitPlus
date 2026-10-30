using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Components.Server.ProtectedBrowserStorage;

namespace VeroEqulibraFit.Admin.Services;

/// <summary>Server-side, per-circuit session for the administrative API.</summary>
public sealed class AdminApiSession(IHttpClientFactory clients, ProtectedSessionStorage storage)
{
    private const string ClientName = "vero-api";
    private const string AccessTokenStorageKey = "vero.admin.access-token";
    private string? _accessToken;
    private bool _restoreAttempted;
    public bool IsAuthenticated => !string.IsNullOrWhiteSpace(_accessToken);
    public AdminOverview? Overview { get; private set; }
    public event Action? Changed;

    public async Task<string?> SignInAsync(string email, string password, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password)) return "Informe e-mail e senha.";
        var client = clients.CreateClient(ClientName);
        HttpResponseMessage response;
        try
        {
            response = await client.PostAsJsonAsync("api/v1/auth/login", new { email = email.Trim(), password }, cancellationToken);
        }
        catch (TaskCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            return "A API demorou para responder. Aguarde alguns segundos e tente novamente.";
        }
        catch (HttpRequestException)
        {
            return "Não foi possível conectar à API administrativa. Tente novamente.";
        }
        using (response)
        {
            if (response.StatusCode is HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden) return "Não foi possível autenticar esta conta administrativa.";
            if (!response.IsSuccessStatusCode) return "A autenticação administrativa está indisponível. Tente novamente.";
            var token = await response.Content.ReadFromJsonAsync<AuthToken>(cancellationToken: cancellationToken);
            if (string.IsNullOrWhiteSpace(token?.AccessToken)) return "A API retornou uma sessão inválida.";
            _accessToken = token.AccessToken;
            var error = await RefreshAsync(cancellationToken);
            if (error is null)
            {
                await storage.SetAsync(AccessTokenStorageKey, _accessToken);
                NotifyChanged();
                return null;
            }
            await SignOutAsync();
            return error;
        }
    }

    public async Task<string?> RefreshAsync(CancellationToken cancellationToken = default)
    {
        if (!IsAuthenticated) return "Entre para acessar a operação.";
        using var response = await AuthorizedClient().GetAsync("api/v1/admin/overview", cancellationToken);
        if (response.StatusCode is HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden)
        {
            await SignOutAsync();
            return "Esta conta não tem permissão administrativa.";
        }
        if (!response.IsSuccessStatusCode) return "Não foi possível carregar os indicadores operacionais.";
        Overview = await response.Content.ReadFromJsonAsync<AdminOverview>(cancellationToken: cancellationToken);
        return Overview is null ? "A API retornou indicadores inválidos." : null;
    }

    /// <summary>Restores the encrypted browser-session token after a circuit reconnect or page refresh.</summary>
    public async Task RestoreAsync(CancellationToken cancellationToken = default)
    {
        if (_restoreAttempted || IsAuthenticated) return;
        _restoreAttempted = true;
        var stored = await storage.GetAsync<string>(AccessTokenStorageKey);
        if (!stored.Success || string.IsNullOrWhiteSpace(stored.Value)) return;
        _accessToken = stored.Value;
        var error = await RefreshAsync(cancellationToken);
        if (error is null) NotifyChanged();
        else await SignOutAsync();
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

    public async Task<AdminCatalogExercisePageResult> ListCatalogExercisesAsync(int page, string? query, string publication, CancellationToken cancellationToken = default)
    {
        if (!IsAuthenticated) return new(null, "Entre para acessar o catálogo.");
        var path = $"api/v1/admin/catalog/exercises?page={page}&pageSize=25";
        if (!string.IsNullOrWhiteSpace(query)) path += $"&query={Uri.EscapeDataString(query.Trim())}";
        if (publication is "published" or "unpublished") path += $"&publication={publication}";
        using var response = await AuthorizedClient().GetAsync(path, cancellationToken);
        if (response.StatusCode is HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden) return new(null, "Sua sessão não tem permissão administrativa.");
        if (!response.IsSuccessStatusCode) return new(null, await ReadProblemAsync(response, "Não foi possível carregar o catálogo."));
        return new(await response.Content.ReadFromJsonAsync<AdminCatalogExercisePage>(cancellationToken: cancellationToken), null);
    }

    public async Task<AdminCatalogExerciseDetailResult> GetCatalogExerciseAsync(string id, CancellationToken cancellationToken = default)
    {
        if (!IsAuthenticated) return new(null, "Entre para acessar o catálogo.");
        using var response = await AuthorizedClient().GetAsync($"api/v1/admin/catalog/exercises/{Uri.EscapeDataString(id)}", cancellationToken);
        if (response.StatusCode == HttpStatusCode.NotFound) return new(null, "Exercício não encontrado.");
        if (!response.IsSuccessStatusCode) return new(null, "Não foi possível carregar o exercício.");
        return new(await response.Content.ReadFromJsonAsync<AdminCatalogExerciseDetail>(cancellationToken: cancellationToken), null);
    }

    public async Task<AdminCatalogExerciseDetailResult> SaveCatalogExerciseAsync(string id, SaveAdminCatalogExerciseRequest request, CancellationToken cancellationToken = default)
    {
        if (!IsAuthenticated) return new(null, "Entre para alterar o catálogo.");
        using var response = await AuthorizedClient().PutAsJsonAsync($"api/v1/admin/catalog/exercises/{Uri.EscapeDataString(id)}", request, cancellationToken);
        if (response.StatusCode is HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden) return new(null, "Sua sessão não tem permissão administrativa.");
        if (!response.IsSuccessStatusCode) return new(null, await ReadProblemAsync(response, "Não foi possível salvar o exercício."));
        return new(await response.Content.ReadFromJsonAsync<AdminCatalogExerciseDetail>(cancellationToken: cancellationToken), null);
    }

    public async Task<AdminCatalogExerciseDetailResult> SaveCatalogMediaAsync(string exerciseId, Guid mediaId, SaveAdminCatalogMediaRequest request, CancellationToken cancellationToken = default)
    {
        if (!IsAuthenticated) return new(null, "Entre para alterar as mídias.");
        using var response = await AuthorizedClient().PutAsJsonAsync($"api/v1/admin/catalog/exercises/{Uri.EscapeDataString(exerciseId)}/media/{mediaId}", request, cancellationToken);
        if (response.StatusCode is HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden) return new(null, "Sua sessão não tem permissão administrativa.");
        if (!response.IsSuccessStatusCode) return new(null, await ReadProblemAsync(response, "Não foi possível associar a mídia."));
        return new(await response.Content.ReadFromJsonAsync<AdminCatalogExerciseDetail>(cancellationToken: cancellationToken), null);
    }

    public async Task<AdminCatalogMediaInventoryResult> GetMediaInventoryAsync(CancellationToken cancellationToken = default)
    {
        if (!IsAuthenticated) return new(null, "Entre para acessar as mídias.");
        using var response = await AuthorizedClient().GetAsync("api/v1/admin/catalog/media-inventory", cancellationToken);
        if (response.StatusCode is HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden) return new(null, "Sua sessão não tem permissão administrativa.");
        if (!response.IsSuccessStatusCode) return new(null, await ReadProblemAsync(response, "Não foi possível carregar o inventário de mídias."));
        return new(await response.Content.ReadFromJsonAsync<AdminCatalogMediaInventory>(cancellationToken: cancellationToken), null);
    }

    private async Task<string?> MutateAsync(string path, object body, CancellationToken cancellationToken)
    {
        if (!IsAuthenticated) return "Entre para executar esta ação.";
        using var response = await AuthorizedClient().PutAsJsonAsync(path, body, cancellationToken);
        if (response.IsSuccessStatusCode) return null;
        if (response.StatusCode is HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden) return "Sua sessão não tem permissão para esta ação.";
        if (response.StatusCode == HttpStatusCode.Conflict) return "A operação foi bloqueada para preservar o último administrador ativo.";
        return await ReadProblemAsync(response, "Não foi possível concluir a alteração.", cancellationToken);
    }

    private static async Task<string> ReadProblemAsync(HttpResponseMessage response, string fallback, CancellationToken cancellationToken = default)
    {
        var suffix = response.StatusCode == HttpStatusCode.NotFound
            ? " O ambiente conectado ainda não disponibiliza este recurso administrativo."
            : $" (HTTP {(int)response.StatusCode}).";

        string content;
        try
        {
            content = await response.Content.ReadAsStringAsync(cancellationToken);
        }
        catch (HttpRequestException)
        {
            return fallback + suffix;
        }

        if (string.IsNullOrWhiteSpace(content)) return fallback + suffix;

        try
        {
            var problem = JsonSerializer.Deserialize<ApiProblem>(content, new JsonSerializerOptions(JsonSerializerDefaults.Web));
            var message = string.IsNullOrWhiteSpace(problem?.Title) ? problem?.Error : problem.Title;
            return string.IsNullOrWhiteSpace(message) ? fallback + suffix : message;
        }
        catch (JsonException)
        {
            return fallback + suffix;
        }
    }

    public async Task SignOutAsync()
    {
        var changed = IsAuthenticated || Overview is not null;
        _accessToken = null;
        Overview = null;
        _restoreAttempted = true;
        await storage.DeleteAsync(AccessTokenStorageKey);
        if (changed) NotifyChanged();
    }

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
    private void NotifyChanged() => Changed?.Invoke();
    private sealed record AuthToken(string AccessToken);
    private sealed record ApiProblem(string? Title, string? Error);
}

public sealed record AdminOverview(int Users, int TrainingPlans, int MealEntries, int NutritionPlans, int? CustomExercises);
public sealed record AdminUserPage(IReadOnlyList<AdminUserListItem> Items, int Page, int PageSize, int TotalCount);
public sealed record AdminUserListItem(Guid Id, string? DisplayName, string Email, DateTimeOffset? RegisteredAt, DateTimeOffset? LastAccessAt, bool IsBlocked, IReadOnlyList<string> Roles);
public sealed record AdminAuditEvent(Guid Id, Guid ActorUserId, string Action, string Result, string? Reason, DateTimeOffset OccurredAt);
public sealed record AdminUserDetail(Guid Id, string? DisplayName, string Email, DateTimeOffset? RegisteredAt, DateTimeOffset? LastAccessAt, bool IsBlocked, IReadOnlyList<string> Roles, IReadOnlyList<AdminAuditEvent> AuditEvents);
public sealed record AdminRole(string Name);
public sealed record AdminUserPageResult(AdminUserPage? Page, string? Error);
public sealed record AdminUserDetailResult(AdminUserDetail? User, string? Error);
public sealed record AdminCatalogExerciseListItem(string Id, string Name, string PrimaryMuscle, string Equipment, bool IsPublished, int MediaCount, DateTimeOffset UpdatedAt);
public sealed record AdminCatalogExercisePage(IReadOnlyList<AdminCatalogExerciseListItem> Items, int Page, int PageSize, int TotalCount);
public sealed record AdminCatalogMediaItem(Guid Id, string AssetPath, string? Label, bool IsPrimary);
public sealed record AdminCatalogExerciseDetail(string Id, string Name, string PrimaryMuscle, string Equipment, string Instructions, bool IsPublished, IReadOnlyList<AdminCatalogMediaItem> Media);
public sealed record SaveAdminCatalogExerciseRequest(string Id, string Name, string PrimaryMuscle, string Equipment, string Instructions, bool IsPublished, string Reason, bool Confirmed);
public sealed record SaveAdminCatalogMediaRequest(string AssetPath, string? Label, bool IsPrimary, string Reason, bool Confirmed);
public sealed record AdminCatalogMediaInventory(IReadOnlyList<string> RegisteredAssets, IReadOnlyList<string> UnmappedAssets);
public sealed record AdminCatalogExercisePageResult(AdminCatalogExercisePage? Page, string? Error);
public sealed record AdminCatalogExerciseDetailResult(AdminCatalogExerciseDetail? Exercise, string? Error);
public sealed record AdminCatalogMediaInventoryResult(AdminCatalogMediaInventory? Inventory, string? Error);
