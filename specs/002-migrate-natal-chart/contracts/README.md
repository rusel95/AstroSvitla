# API Contracts: Prokerala Astrology API

This directory contains HTTP contract examples for the Prokerala Astrology API integration (AstrologyAPI.com).

## Files

- **[western-chart-data.http](./western-chart-data.http)**: Natal chart calculation data endpoint (planets, houses, aspects)
- **[natal-wheel-chart.http](./natal-wheel-chart.http)**: Chart wheel visualization endpoint (SVG/PNG images)
- **[README.md](./README.md)**: This file

## Purpose

These contract files serve as:

1. **API Reference**: Complete request/response examples for development
2. **Testing Fixtures**: Mock responses for unit and integration tests
3. **Documentation**: Contract assertions and validation rules
4. **Contract Tests**: Validate actual API behavior matches expected schemas

## Usage

### With HTTP Client Tools

These `.http` files can be executed directly in:
- **VS Code**: REST Client extension
- **IntelliJ/AppCode**: Built-in HTTP Client
- **Postman**: Import as collections

Replace `{{base64(USER_ID:API_KEY)}}` with actual Base64-encoded credentials.

### For Testing

```swift
// Load contract response as test fixture
let contractURL = Bundle.module.url(forResource: "western-chart-data", withExtension: "http")!
let contractData = try Data(contentsOf: contractURL)

// Parse expected response section
let mockResponse = extractExpectedResponse(from: contractData)

// Use in mock URLSession
mockURLSession.mockData = mockResponse
```

### For Contract Validation

Run integration tests against live API to ensure responses match contract schemas:

```swift
func testWesternChartDataContract() async throws {
    let response = try await apiService.fetchChartData(testRequest)

    // Assert contract expectations
    XCTAssertEqual(response.planets.count, 10, "Must return exactly 10 planets")
    XCTAssertEqual(response.houses.count, 12, "Must return exactly 12 houses")

    for planet in response.planets {
        XCTAssertTrue((0..<360).contains(planet.full_degree), "Planet longitude out of range")
        XCTAssertTrue(["true", "false"].contains(planet.is_retro), "Invalid retrograde value")
    }
}
```

## Authentication

All endpoints require **Basic Authentication**:

```
Authorization: Basic <base64(userID:apiKey)>
```

Get credentials from:
1. Sign up at https://astrologyapi.com
2. Generate User ID and API Key from dashboard
3. Store in `Config.swift` (gitignored):
   ```swift
   static let astrologyAPIUserID = "your_user_id"
   static let astrologyAPIKey = "your_api_key"
   ```

## Rate Limits

**Free Tier**:
- 5,000 credits/month
- 5 requests/minute
- Each chart generation = 2 requests (data + image)
- Effective limit: ~2.5 charts/minute, ~2,500 charts/month

**Enforcement**:
- Server-side: Returns `429 Too Many Requests` if exceeded
- Client-side: Track request timestamps, enforce limit proactively

## Error Handling

All endpoints may return:
- **400 Bad Request**: Invalid input data
- **401 Unauthorized**: Authentication failure
- **429 Too Many Requests**: Rate limit exceeded
- **500 Internal Server Error**: Server-side error

See contract files for detailed error response schemas and handling strategies.

## Performance Expectations

From specification success criteria (SC-001):
- **Total chart generation**: < 5 seconds
- **western_chart_data**: ~1-3 seconds
- **natal_wheel_chart**: ~1-2 seconds
- **Image download**: ~500ms-1s
- **Parallel execution**: Max(data, image) ≈ 3 seconds

## Testing Strategy

### Unit Tests
Mock API responses using contract examples:
```swift
class MockProkralaAPIService: ProkralaAPIServiceProtocol {
    var mockChartData: ProkralaChartDataResponse?
    var mockChartImage: ProkralaChartImageResponse?

    func fetchChartData(_ request: NatalChartRequest) async throws -> ProkralaChartDataResponse {
        guard let data = mockChartData else {
            throw APIError.mockNotConfigured
        }
        return data
    }
}
```

### Integration Tests
Validate live API against contracts:
```swift
func testLiveAPIContractCompliance() async throws {
    // Use test credentials from environment variables
    let apiService = ProkralaAPIService(
        userID: ProcessInfo.processInfo.environment["TEST_API_USER_ID"]!,
        apiKey: ProcessInfo.processInfo.environment["TEST_API_KEY"]!
    )

    let response = try await apiService.fetchChartData(testBirthData)

    // Validate against contract assertions
    assertContractCompliance(response)
}
```

### Contract Tests (CI/CD)
Run weekly to detect breaking API changes:
```yaml
# .github/workflows/contract-tests.yml
name: API Contract Validation
on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run contract tests
        env:
          TEST_API_USER_ID: ${{ secrets.ASTROLOGY_API_USER_ID }}
          TEST_API_KEY: ${{ secrets.ASTROLOGY_API_KEY }}
        run: |
          xcodebuild test -scheme AstroSvitla -only-testing:AstroSvitlaTests/APIContractTests
```

## Maintenance

When API changes:
1. Update contract files with new request/response schemas
2. Update DTOs in `data-model.md`
3. Update mappers in implementation
4. Run contract tests to validate changes
5. Update this README if endpoints or auth changes

## References

- **API Documentation**: https://astrologyapi.com/docs
- **Feature Spec**: [../spec.md](../spec.md)
- **Data Model**: [../data-model.md](../data-model.md)
- **Research**: [../research.md](../research.md)
