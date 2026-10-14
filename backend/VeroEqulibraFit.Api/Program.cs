using VeroEqulibraFit.Application.Exercises;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using VeroEqulibraFit.Infrastructure;
using VeroEqulibraFit.Api.Services;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<ExerciseSearchService>();
builder.Services.AddControllers();
builder.Services.AddHealthChecks();
builder.Services.AddHttpClient<GeminiAiClient>(client =>
{
    var baseUrl = builder.Configuration["AI:BaseUrl"];
    if (!string.IsNullOrWhiteSpace(baseUrl)) client.BaseAddress = new Uri(baseUrl);
    client.Timeout = TimeSpan.FromSeconds(35);
});
var connectionString = builder.Configuration.GetConnectionString("Postgres");
if (!string.IsNullOrWhiteSpace(connectionString))
    builder.Services.AddVeroEqulibraFitInfrastructure(connectionString);
else
    throw new InvalidOperationException("ConnectionStrings:Postgres must be configured for authentication and data isolation.");
builder.Services.AddSingleton<JwtTokenService>();
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
var app = builder.Build();
app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapHealthChecks("/health");
app.MapControllers();
app.Run();

public partial class Program;
