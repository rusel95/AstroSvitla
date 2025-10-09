# Quickstart Guide: Prokerala API Integration

**Feature**: Migrate to Prokerala Astrology API for Natal Chart Calculations and Visualization
**Audience**: iOS Developers implementing this feature
**Time to Complete**: ~30 minutes for basic setup and first API call

## Prerequisites

- Xcode 15+ with iOS 17+ SDK
- AstroSvitla project cloned and building successfully
- Basic understanding of Swift async/await
- Internet connection for API testing

## Step 1: Get API Credentials (5 minutes)

### 1.1 Sign Up for AstrologyAPI Account

1. Visit https://astrologyapi.com
2. Click "Sign Up" or "Get Started"
3. Choose the **Free Trial** or **Starter Plan**
   - Free tier: 5,000 credits/month, 5 requests/minute
   - Perfect for development and initial deployment

### 1.2 Generate Credentials

1. Log in to your AstrologyAPI dashboard
2. Navigate to "API Credentials" or "Settings"
3. Copy your **User ID** (username for Basic Auth)
4. Copy your **API Key** (password for Basic Auth)
5. **Save these securely** - you'll need them in Step 2

> **Note**: Treat API credentials like passwords. Never commit them to version control.

## Step 2: Configure App (5 minutes)

### 2.1 Update Config.swift

1. Open `AstroSvitla/Config/Config.swift.example`
2. Copy to create `AstroSvitla/Config/Config.swift` (if not already present)
3. Add Prokerala API configuration:

```swift
// AstroSvitla/Config/Config.swift

enum Config {

    // MARK: - Existing Configuration (keep as-is)

    static let openAIAPIKey = "your_openai_key"
    static let openAIModel = "gpt-4o"
    static let openAIBaseURL = "https://api.openai.com/v1"

    // MARK: - AstrologyAPI (Prokerala) Configuration

    /// AstrologyAPI User ID for Basic Authentication
    static let astrologyAPIUserID = "your_user_id_here"

    /// AstrologyAPI Key for Basic Authentication
    static let astrologyAPIKey = "your_api_key_here"

    /// Base URL for AstrologyAPI endpoints
    static let astrologyAPIBaseURL = "https://json.astrologyapi.com/v1"

    // MARK: - Validation

    static var isAstrologyAPIConfigured: Bool {
        !astrologyAPIUserID.isEmpty &&
        astrologyAPIUserID != "your_user_id_here" &&
        !astrologyAPIKey.isEmpty &&
        astrologyAPIKey != "your_api_key_here"
    }

    static func validate() throws {
        guard isOpenAIConfigured else {
            throw ConfigError.missingAPIKey("OpenAI API key not configured")
        }

        guard isAstrologyAPIConfigured else {
            throw ConfigError.missingAPIKey("AstrologyAPI credentials not configured in Config.swift")
        }
    }
}
```

4. **Replace placeholders** with your actual credentials from Step 1.1
5. **Save the file** (it's gitignored, so credentials stay local)

### 2.2 Update Config.swift.example

Update the example file so other developers know what to configure:

```swift
// AstroSvitla/Config/Config.swift.example

enum Config {

    // MARK: - OpenAI Configuration
    static let openAIAPIKey = "YOUR_OPENAI_API_KEY_HERE"
    static let openAIModel = "gpt-4o"
    static let openAIBaseURL = "https://api.openai.com/v1"

    // MARK: - AstrologyAPI Configuration

    /// Get credentials from https://astrologyapi.com
    /// Free tier: 5,000 credits/month, 5 requests/minute
    static let astrologyAPIUserID = "YOUR_USER_ID_HERE"
    static let astrologyAPIKey = "YOUR_API_KEY_HERE"
    static let astrologyAPIBaseURL = "https://json.astrologyapi.com/v1"

    // ... rest of config
}
```

## Step 3: Test API Connection (10 minutes)

### 3.1 Create Test Playground

Create a new Swift Playground or test file to validate API access:

```swift
// AstroSvitlaTests/QuickTests/ProkralaAPIQuickTest.swift

import XCTest
@testable import AstroSvitla

final class ProkralaAPIQuickTest: XCTestCase {

    func testAPIConnection() async throws {
        // Step 1: Build authentication header
        let credentials = "\(Config.astrologyAPIUserID):\(Config.astrologyAPIKey)"
        let base64Credentials = Data(credentials.utf8).base64EncodedString()

        // Step 2: Create request
        var request = URLRequest(url: URL(string: "\(Config.astrologyAPIBaseURL)/western_chart_data")!)
        request.httpMethod = "POST"
        request.addValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Step 3: Build request body (test birth data)
        let requestBody: [String: Any] = [
            "day": 15,
            "month": 3,
            "year": 1990,
            "hour": 14,
            "min": 30,
            "lat": 40.7128,
            "lon": -74.0060,
            "tzone": -5.0,
            "house_type": "placidus"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Step 4: Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Step 5: Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            XCTFail("Invalid response type")
            return
        }

        XCTAssertEqual(httpResponse.statusCode, 200, "Expected 200 OK, got \(httpResponse.statusCode)")

        // Step 6: Parse JSON
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json, "Failed to parse JSON response")

        // Step 7: Validate structure
        let planets = json?["planets"] as? [[String: Any]]
        XCTAssertNotNil(planets, "Response missing 'planets' array")
        XCTAssertEqual(planets?.count, 10, "Expected 10 planets")

        let houses = json?["houses"] as? [[String: Any]]
        XCTAssertNotNil(houses, "Response missing 'houses' array")
        XCTAssertEqual(houses?.count, 12, "Expected 12 houses")

        print("✅ API connection successful!")
        print("✅ Received \(planets?.count ?? 0) planets")
        print("✅ Received \(houses?.count ?? 0) houses")
    }
}
```

### 3.2 Run the Test

1. Open `AstroSvitla.xcodeproj` in Xcode
2. Navigate to Test Navigator (⌘5)
3. Find `ProkralaAPIQuickTest`
4. Click the play button next to `testAPIConnection`
5. **Expected result**: Test passes with "✅ API connection successful!" in console

**If test fails**:
- Check credentials in `Config.swift`
- Verify internet connection
- Check Xcode console for error details
- Common issues:
  - 401 Unauthorized → Wrong credentials
  - 429 Too Many Requests → Rate limit exceeded (wait 60 seconds)
  - Network error → Check firewall/proxy settings

## Step 4: Implement Basic API Service (10 minutes)

### 4.1 Create ProkralaAPIService Protocol

```swift
// AstroSvitla/Services/ProkralaAPIService.swift

import Foundation

protocol ProkralaAPIServiceProtocol {
    func fetchChartData(_ request: NatalChartRequest) async throws -> ProkralaChartDataResponse
    func generateChartImage(_ request: NatalChartRequest) async throws -> ProkralaChartImageResponse
}

struct NatalChartRequest {
    let birthData: BirthData
    let houseSystem: HouseSystem
    let imageFormat: ChartVisualization.ImageFormat
    let chartSize: Int

    init(birthData: BirthData, houseSystem: HouseSystem = .placidus, imageFormat: ChartVisualization.ImageFormat = .svg, chartSize: Int = 600) {
        self.birthData = birthData
        self.houseSystem = houseSystem
        self.imageFormat = imageFormat
        self.chartSize = chartSize
    }
}
```

### 4.2 Implement Basic Service

```swift
final class ProkralaAPIService: ProkralaAPIServiceProtocol {

    private let userID: String
    private let apiKey: String
    private let baseURL: String

    init(userID: String = Config.astrologyAPIUserID,
         apiKey: String = Config.astrologyAPIKey,
         baseURL: String = Config.astrologyAPIBaseURL) {
        self.userID = userID
        self.apiKey = apiKey
        self.baseURL = baseURL
    }

    func fetchChartData(_ request: NatalChartRequest) async throws -> ProkralaChartDataResponse {
        let url = URL(string: "\(baseURL)/western_chart_data")!
        let urlRequest = try buildRequest(url: url, body: request.toChartDataBody())
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        try validateResponse(response)
        return try JSONDecoder().decode(ProkralaChartDataResponse.self, from: data)
    }

    func generateChartImage(_ request: NatalChartRequest) async throws -> ProkralaChartImageResponse {
        let url = URL(string: "\(baseURL)/natal_wheel_chart")!
        let urlRequest = try buildRequest(url: url, body: request.toChartImageBody())
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        try validateResponse(response)
        return try JSONDecoder().decode(ProkralaChartImageResponse.self, from: data)
    }

    // MARK: - Private Helpers

    private func buildRequest(url: URL, body: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Authentication
        let credentials = "\(userID):\(apiKey)"
        let base64Credentials = Data(credentials.utf8).base64EncodedString()
        request.addValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")

        // Headers
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("en", forHTTPHeaderField: "Accept-Language")

        // Body
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        return request
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Received invalid response from server"
        case .httpError(let code):
            return "Server returned error code: \(code)"
        }
    }
}
```

### 4.3 Add Request Body Extensions

```swift
extension NatalChartRequest {

    func toChartDataBody() -> [String: Any] {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: birthData.birthDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: birthData.birthTime)

        let timezoneOffset = Double(birthData.timezone.secondsFromGMT()) / 3600.0

        return [
            "day": dateComponents.day!,
            "month": dateComponents.month!,
            "year": dateComponents.year!,
            "hour": timeComponents.hour!,
            "min": timeComponents.minute!,
            "lat": birthData.location.latitude,
            "lon": birthData.location.longitude,
            "tzone": timezoneOffset,
            "house_type": houseSystem.rawValue
        ]
    }

    func toChartImageBody() -> [String: Any] {
        var body = toChartDataBody()
        body["image_type"] = imageFormat.rawValue
        body["chart_size"] = chartSize
        return body
    }
}
```

## Step 5: Test Full Integration (5 minutes)

### 5.1 Create Integration Test

```swift
// AstroSvitlaTests/IntegrationTests/NatalChartGenerationTest.swift

import XCTest
@testable import AstroSvitla

final class NatalChartGenerationTest: XCTestCase {

    func testGenerateNatalChart() async throws {
        // Arrange
        let birthData = BirthData(
            name: "Test Person",
            birthDate: Date(timeIntervalSince1970: 637545600), // March 15, 1990
            birthTime: Date(timeIntervalSince1970: 52200), // 14:30
            location: Location(city: "New York", country: "USA", latitude: 40.7128, longitude: -74.0060),
            timezone: TimeZone(identifier: "America/New_York")!
        )

        let request = NatalChartRequest(birthData: birthData)
        let apiService = ProkralaAPIService()

        // Act
        async let chartData = apiService.fetchChartData(request)
        async let chartImage = apiService.generateChartImage(request)

        let (data, image) = try await (chartData, chartImage)

        // Assert
        XCTAssertEqual(data.planets.count, 10, "Should return 10 planets")
        XCTAssertEqual(data.houses.count, 12, "Should return 12 houses")
        XCTAssertTrue(image.status, "Chart image generation should succeed")
        XCTAssertFalse(image.chart_url.isEmpty, "Should return image URL")

        print("✅ Chart data received with \(data.planets.count) planets")
        print("✅ Chart image available at: \(image.chart_url)")
    }
}
```

### 5.2 Run Integration Test

1. Run `testGenerateNatalChart` in Xcode
2. **Expected result**: Test passes, console shows planet count and image URL
3. **Performance check**: Test should complete in < 5 seconds (per SC-001)

## Next Steps

You now have:
- ✅ API credentials configured
- ✅ Basic API service implemented
- ✅ Connection validated with tests
- ✅ Sample natal chart generated

### Recommended Next Steps

1. **Implement Data Models** (see [data-model.md](./data-model.md))
   - Create DTOs for API responses
   - Create domain models (Planet, House, Aspect, NatalChart)
   - Implement DTO → Domain mappers

2. **Add Caching Layer** (see [research.md](./research.md#local-caching-strategy))
   - Create `CachedNatalChart` SwiftData model
   - Implement `ChartCacheService`
   - Add image file caching with FileManager

3. **Implement Error Handling** (see [research.md](./research.md#error-handling-strategy))
   - Create `NatalChartAPIError` enum
   - Add retry logic with exponential backoff
   - Implement user-friendly error messages

4. **Add Rate Limiting** (see [research.md](./research.md#rate-limiting-strategy))
   - Track API request timestamps
   - Enforce 5 requests/minute limit
   - Display rate limit UI feedback

5. **Refactor Existing Chart Features**
   - Update `ChartCalculator` to use `ProkralaAPIService`
   - Modify `ChartDetailsView` to handle API loading states
   - Update `NatalChartWheelView` to display API-generated images

6. **Write Comprehensive Tests** (TDD)
   - Unit tests for API service (with mocks)
   - Unit tests for data mappers
   - Integration tests for full flow
   - UI tests for chart generation scenarios

## Troubleshooting

### Issue: 401 Unauthorized

**Cause**: Invalid API credentials

**Solution**:
1. Verify `Config.astrologyAPIUserID` and `Config.astrologyAPIKey`
2. Check for typos or extra spaces
3. Regenerate credentials in AstrologyAPI dashboard
4. Ensure credentials are not expired (check account status)

### Issue: 429 Too Many Requests

**Cause**: Rate limit exceeded (5 requests/minute)

**Solution**:
1. Wait 60 seconds before next request
2. Implement client-side rate limiting (see research.md)
3. Check if other tests/developers are using same credentials

### Issue: Network Request Failed

**Cause**: Network connectivity issues

**Solution**:
1. Check internet connection
2. Verify firewall/proxy settings
3. Test with `curl` to isolate issue:
   ```bash
   curl -X POST https://json.astrologyapi.com/v1/western_chart_data \
     -H "Authorization: Basic $(echo -n 'USER_ID:API_KEY' | base64)" \
     -H "Content-Type: application/json" \
     -d '{"day":15,"month":3,"year":1990,"hour":14,"min":30,"lat":40.7128,"lon":-74.0060,"tzone":-5.0,"house_type":"placidus"}'
   ```

### Issue: Invalid JSON Response

**Cause**: API response format changed or parsing error

**Solution**:
1. Print raw response data: `print(String(data: data, encoding: .utf8)!)`
2. Compare with contract examples in `contracts/`
3. Check for API version updates or deprecations
4. File issue if API contract broken

## Resources

- **Specification**: [spec.md](./spec.md)
- **Research**: [research.md](./research.md)
- **Data Models**: [data-model.md](./data-model.md)
- **API Contracts**: [contracts/](./contracts/)
- **AstrologyAPI Docs**: https://astrologyapi.com/docs
- **Support**: https://astrologyapi.com/contact

## Feedback

Found an issue with this quickstart guide? Have suggestions for improvement? File an issue in the project repository or update this document directly.

---

**Happy coding! 🚀**
