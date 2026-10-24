using System.Net;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using VeroEqulibraFit.Api.Controllers;
using VeroEqulibraFit.Api.Services;
using VeroEqulibraFit.Contracts.Nutrition;

namespace VeroEqulibraFit.Api.Tests;

public sealed class NutritionPlansGatewayTests
{
    [Fact]
    public async Task AiGatewayRequestsUseTheConfiguredInternalKey()
    {
        const string key = "test-internal-key-with-at-least-thirty-two-characters";
        var handler = new CaptureHeaderHandler();
        using var http = new HttpClient(handler) { BaseAddress = new Uri("https://localhost") };
        var client = new GeminiAiClient(http, ConfigurationWithKey(key));

        await client.SendCoachMessageAsync(
            "user-1",
            new VeroEqulibraFit.Contracts.Ai.CoachMessageRequest("Como organizar meu treino?", null),
            CancellationToken.None);
        await client.GenerateNutritionPlanAsync(
            new GenerateNutritionPlanRequest("bem estar", null, [], []),
            CancellationToken.None);

        Assert.Equal([key, key], handler.InternalKeys);
    }

    [Theory]
    [InlineData(HttpStatusCode.TooManyRequests, 429)]
    [InlineData(HttpStatusCode.BadGateway, 502)]
    [InlineData(HttpStatusCode.Unauthorized, 502)]
    public async Task Generate_MapsGatewayErrorsWithoutExposingDetails(HttpStatusCode upstream, int expected)
    {
        var handler = new ResponseHandler(upstream);
        using var http = new HttpClient(handler) { BaseAddress = new Uri("https://localhost") };
        var config = ConfigurationWithKey(new string('a', 32));
        var controller = new NutritionPlansController(null!, new GeminiAiClient(http, config), NullLogger<NutritionPlansController>.Instance)
        {
            ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext() },
        };

        var result = await controller.Generate(new GenerateNutritionPlanRequest("bem estar", null, [], []), CancellationToken.None);

        var response = Assert.IsType<ObjectResult>(result.Result);
        Assert.Equal(expected, response.StatusCode);
        var problem = Assert.IsType<ProblemDetails>(response.Value);
        Assert.DoesNotContain("sensitive upstream details", problem.Detail ?? "");
    }

    private sealed class ResponseHandler(HttpStatusCode status) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken) =>
            Task.FromResult(new HttpResponseMessage(status) { Content = new StringContent("sensitive upstream details") });
    }

    private sealed class CaptureHeaderHandler : HttpMessageHandler
    {
        public List<string> InternalKeys { get; } = [];

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            InternalKeys.Add(request.Headers.GetValues("X-Internal-Api-Key").Single());
            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent("{\"content\":\"ok\",\"model\":\"gemini\"}"),
            });
        }
    }

    private static IConfiguration ConfigurationWithKey(string key) => new ConfigurationBuilder()
        .AddInMemoryCollection(new Dictionary<string, string?> { ["AI:InternalApiKey"] = key })
        .Build();
}
