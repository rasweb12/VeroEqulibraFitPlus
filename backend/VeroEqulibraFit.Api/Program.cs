using VeroEqulibraFit.Application.Exercises;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.IdentityModel.Tokens;
using VeroEqulibraFit.Infrastructure;
using VeroEqulibraFit.Api.Services;
using System.Threading.RateLimiting;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<ExerciseSearchService>();
builder.Services.AddControllers();
builder.Services.AddHealthChecks();
builder.Services.AddHttpClient<GeminiAiClient>(client =>
{
    var baseUrl = builder.Configuration["AI:BaseUrl"];
    if (!string.IsNullOrWhiteSpace(baseUrl))
    {
        if (!baseUrl.StartsWith("http://", StringComparison.OrdinalIgnoreCase) && !baseUrl.StartsWith("https://", StringComparison.OrdinalIgnoreCase)) baseUrl = $"http://{baseUrl}";
        client.BaseAddress = new Uri(baseUrl);
    }
    client.Timeout = TimeSpan.FromSeconds(35);
});
var connectionString = builder.Configuration.GetConnectionString("Postgres")
    ?? builder.Configuration["Database:ConnectionString"];
if (!string.IsNullOrWhiteSpace(connectionString))
    builder.Services.AddVeroEqulibraFitInfrastructure(connectionString);
else
    throw new InvalidOperationException("ConnectionStrings:Postgres must be configured for authentication and data isolation.");
builder.Services.AddSingleton<JwtTokenService>();
builder.Services.AddSingleton<IAccountEmailSender, SmtpAccountEmailSender>();
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(options =>
{
    var tokenService = new JwtTokenService(builder.Configuration);
    options.RequireHttpsMetadata = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidIssuer = tokenService.Issuer,
        ValidateAudience = false,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = tokenService.SigningKey,
        ClockSkew = TimeSpan.FromSeconds(30),
    };
});
builder.Services.AddAuthorization();
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddFixedWindowLimiter("auth-public", limiter =>
    {
        limiter.PermitLimit = 10;
        limiter.Window = TimeSpan.FromMinutes(1);
        limiter.QueueLimit = 0;
        limiter.AutoReplenishment = true;
    });
});
var app = builder.Build();
app.UseHttpsRedirection();
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();
app.MapHealthChecks("/health");
app.MapControllers();
app.Run();

public partial class Program;
