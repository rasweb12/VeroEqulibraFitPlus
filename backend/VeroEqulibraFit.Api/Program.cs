using VeroEqulibraFit.Application.Exercises;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<ExerciseSearchService>();
builder.Services.AddControllers();
builder.Services.AddHealthChecks();
var app = builder.Build();
app.UseHttpsRedirection();
app.MapHealthChecks("/health");
app.MapControllers();
app.Run();

public partial class Program;
