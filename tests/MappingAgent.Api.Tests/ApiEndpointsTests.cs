using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;

namespace MappingAgent.Api.Tests;

public class ApiEndpointsTests
{
    private const string TestApiKey = "test-api-key";
    private readonly WebApplicationFactory<Program> _factory;
    private readonly HttpClient _clientWithApiKey;
    private readonly HttpClient _clientWithoutApiKey;

    public ApiEndpointsTests()
    {
        _factory = new WebApplicationFactory<Program>()
            .WithWebHostBuilder(builder =>
            {
                builder.ConfigureAppConfiguration((_, config) =>
                {
                    config.AddInMemoryCollection(new Dictionary<string, string?>
                    {
                        ["API_KEY"] = TestApiKey
                    });
                });
            });

        _clientWithApiKey = _factory.CreateClient();
        _clientWithApiKey.DefaultRequestHeaders.Add("X-API-Key", TestApiKey);
        _clientWithoutApiKey = _factory.CreateClient();
    }

    [Fact]
    public async Task Health_IsAccessibleWithoutApiKey()
    {
        var response = await _clientWithoutApiKey.GetAsync("/health");
        Assert.NotEqual(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Validate_WithoutApiKey_ReturnsUnauthorized()
    {
        var request = new { sql = "SELECT * FROM dbo.Mapping" };
        var response = await _clientWithoutApiKey.PostAsJsonAsync("/api/sql/validate", request);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Validate_WithApiKey_ReturnsOk()
    {
        var request = new { sql = "SELECT * FROM dbo.Mapping" };
        var response = await _clientWithApiKey.PostAsJsonAsync("/api/sql/validate", request);

        response.EnsureSuccessStatusCode();
    }

    [Fact]
    public async Task Validate_WrapsQueryWithTop_WhenNoTopOrOffset()
    {
        var request = new
        {
            sql = "SELECT * FROM dbo.Mapping"
        };

        var response = await _clientWithApiKey.PostAsJsonAsync("/api/sql/validate", request);
        response.EnsureSuccessStatusCode();

        var payload = await response.Content.ReadFromJsonAsync<JsonObject>();
        Assert.NotNull(payload);
        Assert.True(payload!["valid"]?.GetValue<bool>());
        Assert.Equal("SELECT TOP (200) * FROM (SELECT * FROM dbo.Mapping) q", payload["sql"]?.GetValue<string>());
        Assert.True(payload["error"] is null || payload["error"]!.GetValue<string>() is null);
    }

    [Fact]
    public async Task Validate_ReturnsBadRequest_ForForbiddenVerb()
    {
        var request = new
        {
            sql = "DELETE FROM dbo.Mapping"
        };

        var response = await _clientWithApiKey.PostAsJsonAsync("/api/sql/validate", request);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var payload = await response.Content.ReadFromJsonAsync<JsonObject>();
        Assert.NotNull(payload);
        Assert.False(payload!["valid"]?.GetValue<bool>());
        Assert.Equal("Only SELECT or WITH queries are allowed.", payload["error"]?.GetValue<string>());
    }

    [Fact]
    public async Task Query_ReturnsBadRequest_ForSemicolon()
    {
        var request = new
        {
            question = "test",
            sql = "SELECT * FROM dbo.Mapping;",
            @params = new { }
        };

        var response = await _clientWithApiKey.PostAsJsonAsync("/api/sql/query", request);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var payload = await response.Content.ReadFromJsonAsync<JsonObject>();
        Assert.NotNull(payload);
        Assert.Equal("validation_error", payload!["error"]?.GetValue<string>());
        Assert.Equal("Multi-statement queries are not allowed.", payload["detail"]?.GetValue<string>());
    }

    [Fact]
    public async Task Swagger_DeclaresRowsAsArrayOfObjects()
    {
        var response = await _clientWithoutApiKey.GetAsync("/swagger/v1/swagger.json");
        response.EnsureSuccessStatusCode();
        var payload = await response.Content.ReadFromJsonAsync<JsonNode>();

        Assert.NotNull(payload);
        var rowsNode = payload!["components"]?["schemas"]?["SqlQueryResponse"]?["properties"]?["rows"];
        Assert.NotNull(rowsNode);
        Assert.Equal("array", rowsNode!["type"]?.GetValue<string>());
        Assert.Equal("object", rowsNode["items"]?["type"]?.GetValue<string>());
    }
}
