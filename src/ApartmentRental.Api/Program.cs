using System.Text;
using ApartmentRental.Api.Contracts;
using ApartmentRental.Api.Data;
using ApartmentRental.Api.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? "Server=localhost,1433;Database=ApartmentRental;User Id=sa;Password=Your_strong_password123;TrustServerCertificate=True;";
var jwtKey = builder.Configuration["Jwt:Key"] ?? "development-only-change-this-secret-please";

builder.Services.AddDbContext<ApplicationDbContext>(options => options.UseSqlServer(connectionString));
builder.Services.AddScoped<TokenService>();
builder.Services.AddScoped<RentalService>();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddCors(options => options.AddDefaultPolicy(policy => policy
    .AllowAnyHeader().AllowAnyMethod().AllowCredentials()
    .WithOrigins(builder.Configuration.GetSection("Cors:Origins").Get<string[]>() ?? ["http://localhost:5173"])));
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
        ValidateIssuer = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"] ?? "ApartmentRental.Api",
        ValidateAudience = true,
        ValidAudience = builder.Configuration["Jwt:Audience"] ?? "ApartmentRental.Client",
        ValidateLifetime = true,
        ClockSkew = TimeSpan.FromMinutes(1)
    };
});
builder.Services.AddAuthorization();

var app = builder.Build();
app.UseExceptionHandler(errorApp => errorApp.Run(async context =>
{
    context.Response.StatusCode = StatusCodes.Status500InternalServerError;
    context.Response.ContentType = "application/json";
    await context.Response.WriteAsJsonAsync(new { error = "internal_error", message = "An unexpected error occurred." });
}));
app.UseSwagger();
app.UseSwaggerUI();
app.UseCors();
app.UseAuthentication();
app.UseAuthorization();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    await DbSeeder.SeedAsync(db);
}

app.MapGet("/api/health", () => Results.Ok(new { status = "ok", service = "ApartmentRental.Api" }));
app.MapPost("/api/auth/login", async (LoginRequest request, ApplicationDbContext db, TokenService tokens) =>
{
    var user = await db.Users.FirstOrDefaultAsync(x => x.Email == request.Email && x.IsActive);
    if (user is null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash)) return Results.Unauthorized();
    return Results.Ok(new LoginResponse(tokens.CreateToken(user), user.Email, user.DisplayName, user.Role.ToString()));
}).AllowAnonymous();
app.MapGet("/api/me", (HttpContext context) => Results.Ok(new
{
    email = context.User.Identity?.Name,
    role = context.User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value,
    displayName = context.User.FindFirst("display_name")?.Value
})).RequireAuthorization();

app.MapGet("/api/properties/search", async (string? city, int? bedrooms, decimal? maxRent, bool? listedOnly, string? q, RentalService service) =>
    Results.Ok(await service.SearchAsync(new PropertySearchRequest(city, bedrooms, maxRent, listedOnly ?? true, q)))).AllowAnonymous();
app.MapGet("/api/dashboard", async (RentalService service) => Results.Ok(await service.DashboardAsync())).RequireAuthorization(policy => policy.RequireRole("Admin", "Agent"));

app.MapGet("/api/leases", async (HttpContext context, RentalService service) => Results.Ok(await service.GetLeasesAsync(context.User))).RequireAuthorization();
app.MapPost("/api/leases", async (CreateLeaseRequest request, HttpContext context, RentalService service) =>
{
    var lease = await service.CreateLeaseAsync(context.User, request);
    return lease is null ? Results.Forbid() : Results.Created($"/api/leases/{lease.Id}", lease);
}).RequireAuthorization(policy => policy.RequireRole("Admin", "Agent"));

app.MapGet("/api/payments", async (long? leaseId, HttpContext context, RentalService service) => Results.Ok(await service.GetPaymentsAsync(context.User, leaseId))).RequireAuthorization();
app.MapPost("/api/leases/{leaseId:long}/payments", async (long leaseId, CreatePaymentRequest request, HttpContext context, RentalService service) =>
{
    var payment = await service.RecordPaymentAsync(context.User, leaseId, request);
    return payment is null ? Results.Forbid() : Results.Ok(payment);
}).RequireAuthorization();

app.MapGet("/api/maintenance", async (HttpContext context, RentalService service) => Results.Ok(await service.GetMaintenanceAsync(context.User))).RequireAuthorization();
app.MapPost("/api/maintenance", async (CreateMaintenanceRequest request, HttpContext context, RentalService service) =>
{
    var item = await service.CreateMaintenanceAsync(context.User, request);
    return item is null ? Results.Forbid() : Results.Created("/api/maintenance", item);
}).RequireAuthorization();
app.MapPatch("/api/maintenance/{id:long}", async (long id, UpdateMaintenanceRequest request, HttpContext context, RentalService service) => (await service.UpdateMaintenanceAsync(context.User, id, request)) ? Results.NoContent() : Results.NotFound()).RequireAuthorization(policy => policy.RequireRole("Admin", "Agent"));
app.MapGet("/api/audit", async (ApplicationDbContext db) => Results.Ok(await db.AuditEvents.AsNoTracking().OrderByDescending(x => x.CreatedAtUtc).Take(100).ToListAsync())).RequireAuthorization(policy => policy.RequireRole("Admin"));

app.Run();

public partial class Program { }
