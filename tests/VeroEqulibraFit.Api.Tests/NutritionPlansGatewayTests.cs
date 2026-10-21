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
    [Theory]
    [InlineData(HttpStatusCode.TooManyRequests, 429)]
    [InlineData(HttpStatusCode.BadGateway, 502)]
    [InlineData(HttpStatusCode.Unauthorized, 502)]
    public async Task Generate_MapsGatewayErrorsWithoutExposingDetails(HttpStatusCode upstream, int expected)
    {
        var handler = new ResponseHandler(upstream);
        using var http = new HttpClient(handler) { BaseAddress = new Uri("https://localhost") };
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["AI:InternalApiKey"] = new string('a', 32),
        }).Build();
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
}
