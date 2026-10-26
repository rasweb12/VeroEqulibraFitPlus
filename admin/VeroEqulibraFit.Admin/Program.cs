using VeroEqulibraFit.Admin.Components;
using VeroEqulibraFit.Admin.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();
builder.Services.AddHttpClient("vero-api", client =>
{
    client.BaseAddress = AdminApiSession.ReadBaseUrl(builder.Configuration);
    // Render free instances can require a cold-start window. The UI still
    // reports timeout explicitly instead of leaking an unhandled exception.
    client.Timeout = TimeSpan.FromSeconds(45);
});
builder.Services.AddScoped<AdminApiSession>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}
app.UseStatusCodePagesWithReExecute("/not-found", createScopeForStatusCodePages: true);
app.UseHttpsRedirection();

app.UseAntiforgery();

app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));

app.MapStaticAssets();
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
