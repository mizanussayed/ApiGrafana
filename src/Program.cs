using System.Diagnostics;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add logging
builder.Services.AddLogging();

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Simple request logging middleware
app.Use(async (context, next) =>
{
    var stopwatch = Stopwatch.StartNew();
    var startTime = DateTime.UtcNow;
    
    await next();
    
    stopwatch.Stop();
    
    // Simple console logging
    var logger = context.RequestServices.GetRequiredService<ILogger<Program>>();
    logger.LogInformation("Request: {method} {path} - {statusCode} - {responseTime}ms", 
        context.Request.Method, context.Request.Path, context.Response.StatusCode, stopwatch.ElapsedMilliseconds);
});

// API Endpoints
app.MapGet("/", () => "Hello World! API is running.");

app.MapGet("/health", () => new { Status = "Healthy", Timestamp = DateTime.UtcNow });

app.MapGet("/api/users", () => 
{
    var users = new[]
    {
        new { Id = 1, Name = "John Doe", Email = "john@example.com" },
        new { Id = 2, Name = "Jane Smith", Email = "jane@example.com" },
        new { Id = 3, Name = "Bob Johnson", Email = "bob@example.com" }
    };
    return Results.Ok(users);
});

app.MapGet("/api/users/{id}", (int id) => 
{
    var user = new { Id = id, Name = $"User {id}", Email = $"user{id}@example.com" };
    return Results.Ok(user);
});

app.MapPost("/api/users", (object user) => 
{
    Thread.Sleep(100); // Simulate some processing time
    return Results.Created($"/api/users/{Random.Shared.Next(1000)}", user);
});

app.MapGet("/api/slow", async () =>
{
    await Task.Delay(2000); // Simulate slow endpoint
    return Results.Ok(new { Message = "This was a slow operation" });
});

app.MapGet("/api/error", () => Results.Problem("Simulated error", statusCode: 500));

app.Run();
