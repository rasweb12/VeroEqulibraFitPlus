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
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(options =>
{
    options.Authority = builder.Configuration["Jwt:Authority"];
    options.Audience = builder.Configuration["Jwt:Audience"];
    options.RequireHttpsMetadata = !builder.Environment.IsDevelopment();
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
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
