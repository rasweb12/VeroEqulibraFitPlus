using Microsoft.AspNetCore.Mvc.Testing;
namespace VeroEqulibraFit.Api.Tests;

public sealed class AuthorizationTests
{
    [Fact]
    public async Task PrivateSessionEndpoint_RejectsUnauthenticatedRequest()
    {
        await using var environment = new TestEnvironment();
        using var factory = new WebApplicationFactory<Program>();
        using var client = factory.CreateClient();

        var response = await client.GetAsync("/api/v1/auth/session");

        Assert.Equal(System.Net.HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task AdminOverview_RejectsUnauthenticatedRequest()
    {
        await using var environment = new TestEnvironment();
        using var factory = new WebApplicationFactory<Program>();
        using var client = factory.CreateClient();

        var response = await client.GetAsync("/api/v1/admin/overview");

        Assert.Equal(System.Net.HttpStatusCode.Unauthorized, response.StatusCode);
    }

    private sealed class TestEnvironment : IAsyncDisposable
    {
        private static readonly SemaphoreSlim Gate = new(1, 1);
        private readonly Dictionary<string, string?> _original = [];

        public TestEnvironment()
        {
            Gate.Wait();
            Set("Jwt__Issuer", "vero-equilibrafit-api-tests");
            Set("Jwt__Audience", "vero-equilibrafit-mobile-tests");
            Set("Jwt__SigningKey", "test-signing-key-with-at-least-sixty-four-bytes-for-hs512-validation-0001");
            Set("AI__BaseUrl", "http://localhost:8001");
            Set("AI__InternalApiKey", "test-internal-key-with-at-least-thirty-two-characters");
            Set("ConnectionStrings__Postgres", "Host=127.0.0.1;Port=1;Database=isolated_tests;Username=test;Password=test;Timeout=1");
        }

        public ValueTask DisposeAsync()
        {
            foreach (var (key, value) in _original)
                Environment.SetEnvironmentVariable(key, value);
            Gate.Release();
            return ValueTask.CompletedTask;
        }

        private void Set(string key, string value)
        {
            _original[key] = Environment.GetEnvironmentVariable(key);
            Environment.SetEnvironmentVariable(key, value);
        }
    }
}
