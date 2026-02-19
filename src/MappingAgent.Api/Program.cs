using System.Data;
using System.Diagnostics;
using System.Text.Json;
using System.Text.RegularExpressions;
using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.OperationFilter<SqlQueryResponseOperationFilter>();
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.Use(async (context, next) =>
{
    var path = context.Request.Path;
    var isHealth = HttpMethods.IsGet(context.Request.Method) &&
                   path.Equals("/health", StringComparison.OrdinalIgnoreCase);
    var isSwagger = path.StartsWithSegments("/swagger", StringComparison.OrdinalIgnoreCase);

    if (isHealth || isSwagger)
    {
        await next();
        return;
    }

    var expectedApiKey = app.Configuration["API_KEY"];
    if (string.IsNullOrWhiteSpace(expectedApiKey))
    {
        context.Response.StatusCode = StatusCodes.Status500InternalServerError;
        await context.Response.WriteAsJsonAsync(new { error = "server_not_configured", detail = "API_KEY is missing." });
        return;
    }

    if (!context.Request.Headers.TryGetValue("X-API-Key", out var providedApiKey) ||
        !string.Equals(providedApiKey.ToString(), expectedApiKey, StringComparison.Ordinal))
    {
        context.Response.StatusCode = StatusCodes.Status401Unauthorized;
        await context.Response.WriteAsJsonAsync(new { error = "unauthorized" });
        return;
    }

    await next();
});

app.MapGet("/", () => Results.Ok(new { message = "MappingAgent API" }));

app.MapGet("/health", async (ILoggerFactory loggerFactory) =>
{
    var logger = loggerFactory.CreateLogger("Health");
    try
    {
        await using var connection = new SqlConnection(BuildConnectionString());
        await connection.OpenAsync();
        using var command = new SqlCommand("SELECT 1", connection)
        {
            CommandTimeout = 5
        };
        await command.ExecuteScalarAsync();
        return Results.Ok(new { ok = true });
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Health check failed");
        return Results.Json(new { ok = false, error = "database_unavailable" }, statusCode: 503);
    }
});

app.MapPost("/api/sql/query", async (SqlQueryRequest request, ILoggerFactory loggerFactory) =>
{
    var logger = loggerFactory.CreateLogger("SqlQuery");
    var stopwatch = Stopwatch.StartNew();

    try
    {
        var finalSql = ValidateAndNormalizeSql(request.Sql);
        var parameters = new DynamicParameters();
        if (request.Params is not null)
        {
            foreach (var kv in request.Params)
            {
                parameters.Add(kv.Key, ConvertJsonValue(kv.Value));
            }
        }

        await using var connection = new SqlConnection(BuildConnectionString());
        await connection.OpenAsync();
        var command = new CommandDefinition(finalSql, parameters, commandTimeout: 5);
        var rawRows = (await connection.QueryAsync(command)).ToList();

        var columns = new List<string>();
        var rows = new List<Dictionary<string, object?>>();

        if (rawRows.Count > 0)
        {
            if (rawRows[0] is IDictionary<string, object?> first)
            {
                columns = first.Keys.ToList();
            }

            foreach (var row in rawRows)
            {
                if (row is IDictionary<string, object?> dict)
                {
                    var rowObject = new Dictionary<string, object?>(StringComparer.Ordinal);
                    foreach (var column in columns)
                    {
                        dict.TryGetValue(column, out var value);
                        rowObject[column] = value;
                    }
                    rows.Add(rowObject);
                }
            }
        }

        stopwatch.Stop();
        var response = new SqlQueryResponse(
            finalSql,
            columns,
            rows,
            rows.Count >= 200,
            stopwatch.ElapsedMilliseconds
        );

        logger.LogInformation(
            "SQL query executed. question={Question} rows={RowCount} elapsedMs={ElapsedMs} sql={Sql}",
            request.Question,
            rows.Count,
            response.ElapsedMs,
            response.Sql
        );

        return Results.Ok(response);
    }
    catch (SqlValidationException ex)
    {
        stopwatch.Stop();
        return Results.BadRequest(new { error = "validation_error", detail = ex.Message });
    }
    catch (Exception ex)
    {
        stopwatch.Stop();
        logger.LogError(ex, "SQL query failed");
        return Results.Json(new { error = "query_execution_failed", detail = ex.Message }, statusCode: 500);
    }
})
    .Produces<SqlQueryResponse>(StatusCodes.Status200OK)
    .Produces(StatusCodes.Status400BadRequest)
    .Produces(StatusCodes.Status500InternalServerError);

app.MapPost("/api/sql/validate", (SqlValidateRequest request) =>
{
    try
    {
        var finalSql = ValidateAndNormalizeSql(request.Sql);
        return Results.Ok(new SqlValidateResponse(true, finalSql, null));
    }
    catch (SqlValidationException ex)
    {
        return Results.BadRequest(new SqlValidateResponse(false, null, ex.Message));
    }
})
    .Produces<SqlValidateResponse>(StatusCodes.Status200OK)
    .Produces<SqlValidateResponse>(StatusCodes.Status400BadRequest);

app.Run();

static string BuildConnectionString()
{
    var fromEnv = Environment.GetEnvironmentVariable("CONNECTION_STRING");
    if (!string.IsNullOrWhiteSpace(fromEnv))
    {
        return fromEnv;
    }

    var host = Environment.GetEnvironmentVariable("MAPPING_DB_HOST") ?? "localhost";
    var port = Environment.GetEnvironmentVariable("MAPPING_DB_PORT") ?? "1433";
    var database = Environment.GetEnvironmentVariable("MAPPING_DB") ?? "MappingDW";
    var password = Environment.GetEnvironmentVariable("MSSQL_SA_PASSWORD");

    if (string.IsNullOrWhiteSpace(password))
    {
        throw new InvalidOperationException("Missing MSSQL_SA_PASSWORD and CONNECTION_STRING was not provided.");
    }

    return $"Server={host},{port};Database={database};User Id=sa;Password={password};TrustServerCertificate=True;Encrypt=False;";
}

static string ValidateAndNormalizeSql(string? input)
{
    if (string.IsNullOrWhiteSpace(input))
    {
        throw new SqlValidationException("SQL is required.");
    }

    var sql = input.Trim();
    if (!(sql.StartsWith("SELECT", StringComparison.OrdinalIgnoreCase) ||
          sql.StartsWith("WITH", StringComparison.OrdinalIgnoreCase)))
    {
        throw new SqlValidationException("Only SELECT or WITH queries are allowed.");
    }

    if (sql.Contains(';'))
    {
        throw new SqlValidationException("Multi-statement queries are not allowed.");
    }

    var bannedKeywordsPattern = @"\b(INSERT|UPDATE|DELETE|MERGE|DROP|ALTER|CREATE|EXEC|TRUNCATE|GRANT|REVOKE)\b";
    if (Regex.IsMatch(sql, bannedKeywordsPattern, RegexOptions.IgnoreCase | RegexOptions.CultureInvariant))
    {
        throw new SqlValidationException("Query contains forbidden keywords.");
    }

    var hasTop = Regex.IsMatch(sql, @"\bTOP\s*\(", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant)
                 || Regex.IsMatch(sql, @"\bTOP\s+\d+", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
    var hasOffsetFetch = Regex.IsMatch(sql, @"\bOFFSET\b", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant)
                         || Regex.IsMatch(sql, @"\bFETCH\b", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);

    if (!hasTop && !hasOffsetFetch)
    {
        return $"SELECT TOP (200) * FROM ({sql}) q";
    }

    return sql;
}

static object? ConvertJsonValue(object? value)
{
    if (value is not JsonElement element)
    {
        return value;
    }

    return element.ValueKind switch
    {
        JsonValueKind.String => element.GetString(),
        JsonValueKind.Number when element.TryGetInt64(out var i) => i,
        JsonValueKind.Number when element.TryGetDouble(out var d) => d,
        JsonValueKind.True => true,
        JsonValueKind.False => false,
        JsonValueKind.Null => null,
        JsonValueKind.Undefined => null,
        _ => element.ToString()
    };
}

sealed class SqlValidationException : Exception
{
    public SqlValidationException(string message) : base(message) { }
}

public record SqlQueryRequest(string? Question, string Sql, Dictionary<string, object?>? Params);
public record SqlQueryResponse(string Sql, List<string> Columns, List<Dictionary<string, object?>> Rows, bool Truncated, long ElapsedMs);
public record SqlValidateRequest(string Sql);
public record SqlValidateResponse(bool Valid, string? Sql, string? Error);

public partial class Program { }

sealed class SqlQueryResponseOperationFilter : IOperationFilter
{
    public void Apply(OpenApiOperation operation, OperationFilterContext context)
    {
        var isQueryEndpoint = string.Equals(context.ApiDescription.RelativePath, "api/sql/query", StringComparison.OrdinalIgnoreCase) &&
                              string.Equals(context.ApiDescription.HttpMethod, "POST", StringComparison.OrdinalIgnoreCase);
        if (!isQueryEndpoint)
        {
            return;
        }

        var schema = context.SchemaGenerator.GenerateSchema(typeof(SqlQueryResponse), context.SchemaRepository);
        operation.Responses["200"] = new OpenApiResponse
        {
            Description = "OK",
            Content = new Dictionary<string, OpenApiMediaType>
            {
                ["application/json"] = new()
                {
                    Schema = schema
                }
            }
        };
    }
}
