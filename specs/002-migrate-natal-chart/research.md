# Research: Prokerala Astrology API Migration

**Feature**: Migrate to Prokerala Astrology API for Natal Chart Calculations and Visualization
**Date**: 2025-10-09
**Phase**: 0 - Research & Unknowns Resolution

## Overview

This document consolidates research on migrating from SwissEphemeris local calculations to Prokerala Astrology API (branded as AstrologyAPI.com) for natal chart computations and visualizations.

## API Provider Selection

### Decision

Use **AstrologyAPI.com** (Prokerala's Western Astrology API) as the unified provider for both natal chart calculations and chart wheel visualizations.

### Rationale

1. **Single Provider**: Handles both calculations (planets, houses, aspects) and chart visualization (SVG/PNG) through dedicated endpoints
2. **Western Astrology Focus**: Specialized Western/tropical astrology support with Placidus house system (our requirement)
3. **Free Tier Available**: 5,000 credits/month, 5 requests/minute rate limit suitable for initial deployment
4. **Professional Quality**: Industry-standard calculations meeting the "within 1 degree" accuracy requirement
5. **Clear Documentation**: Well-documented REST API with JSON responses and examples
6. **No Custom Rendering**: Eliminates need for complex SVG/Canvas chart drawing logic

### Alternatives Considered

1. **FreeAstrologyAPI.com**
   - ❌ Limited documentation
   - ❌ Unclear pricing/tier structure
   - ❌ Less established than AstrologyAPI

2. **Self-hosted SwissEphemeris + Custom Rendering**
   - ❌ Requires maintaining ephemeris data files
   - ❌ Need to implement chart wheel drawing from scratch
   - ❌ Complexity violates "simpler alternatives" principle
   - ✅ Would work offline
   - **Rejected**: Too complex, defeats purpose of API migration

3. **Astro-Seek or Astro.com APIs**
   - ❌ Not designed for programmatic third-party app integration
   - ❌ Terms of service restrictions

## API Endpoints & Integration

### Decision: Two-Endpoint Strategy

Use two separate API calls per chart generation:
1. **Data Endpoint**: `western_chart_data` for calculations
2. **Image Endpoint**: `natal_wheel_chart` for visualization

### Rationale

1. **Flexibility**: Can cache data and images separately
2. **Offline Support**: Can display cached data even if image fails to load
3. **Error Handling**: Partial failures (data succeeds, image fails) can be handled gracefully
4. **Performance**: Data parsing and image download can be optimized independently

### Endpoint Details

#### 1. Western Chart Data API

**URL**: `https://json.astrologyapi.com/v1/western_chart_data`
**Method**: POST
**Purpose**: Calculate planetary positions, house cusps, and aspects

**Request Body**:
```json
{
  "day": 6,
  "month": 1,
  "year": 2000,
  "hour": 7,
  "min": 45,
  "lat": 19.132,
  "lon": 72.342,
  "tzone": 5.5,
  "house_type": "placidus"
}
```

**Response Structure**:
- `planets[]`: Array of planetary positions
  - `name`: Planet name (Sun, Moon, Mercury, etc.)
  - `sign`: Zodiac sign
  - `full_degree`: Absolute longitude (0-360)
  - `is_retro`: "true"/"false" string for retrograde status
- `houses[]`: Array of house data
  - `house_id`: 1-12
  - `sign`: Sign on house cusp
  - `start_degree`: Cusp degree
  - `end_degree`: Next cusp degree
  - `planets[]`: Planets in this house
- `aspects[]`: Array of planetary aspects
  - `aspecting_planet`: First planet name
  - `aspected_planet`: Second planet name
  - `type`: Aspect type (Conjunction, Sextile, Square, Trine, Opposition, Quincunx)
  - `orb`: Deviation from exact aspect (degrees)
  - `diff`: Angular difference between planets

#### 2. Natal Wheel Chart API

**URL**: `https://json.astrologyapi.com/v1/natal_wheel_chart`
**Method**: POST
**Purpose**: Generate chart wheel image (SVG/PNG)

**Request Body**:
```json
{
  "day": 6,
  "month": 1,
  "year": 2000,
  "hour": 7,
  "min": 45,
  "lat": 19.132,
  "lon": 72.342,
  "tzone": 5.5,
  "house_type": "placidus",
  "image_type": "svg",
  "chart_size": 600
}
```

**Optional Customization Parameters**:
- `image_type`: "svg" or "png" (default: "png")
- `chart_size`: Image dimensions in pixels
- `planet_icon_color`: Hex color string
- `inner_circle_background`: Hex color string
- `sign_icon_color`: Hex color string
- `sign_background`: Hex color string

**Response Structure**:
```json
{
  "status": true,
  "chart_url": "https://s3.ap-south-1.amazonaws.com/western-chart/example.svg",
  "msg": "Chart created successfully!"
}
```

### Authentication

**Decision**: Basic Authentication with User ID and API Key

**Implementation**:
```swift
let credentials = "\(userID):\(apiKey)"
let base64Credentials = Data(credentials.utf8).base64EncodedString()
request.addValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
request.addValue("application/json", forHTTPHeaderField: "Content-Type")
```

**Configuration**:
- Store `astrologyAPIUserID` and `astrologyAPIKey` in `Config.swift`
- Add to `Config.swift.example` with placeholder values
- Validate presence during app initialization (similar to OpenAI validation)

### Rate Limiting Strategy

**Decision**: Client-Side Rate Limit Enforcement

**Approach**:
1. Track request timestamps in `UserDefaults`
2. Implement sliding window: max 5 requests per 60 seconds
3. Queue requests that would exceed limit
4. Display user-friendly message: "Please wait {N} seconds before generating another chart"
5. Track monthly credit usage (estimate based on requests * 2 endpoints)

**Rationale**:
- Prevents HTTP 429 errors from degrading UX
- Educates users about API constraints
- Aligns with free tier limits (5 req/min, 5000 credits/month)
- Simple to implement without external dependencies

## iOS Networking Implementation

### Decision: Native URLSession with async/await

**Rationale**:
1. **Modern Swift Concurrency**: iOS 17+ requirement allows async/await patterns
2. **No Third-Party Dependencies**: Reduces complexity, aligns with Constitution Principle II
3. **Built-in Error Handling**: Swift's structured concurrency provides clean error propagation
4. **Testability**: Easy to mock URLSession using protocols
5. **Performance**: Native APIs are optimized for iOS

### Best Practices Applied

#### 1. Async/Await Pattern

```swift
func fetchNatalChartData(request: NatalChartRequest) async throws -> NatalChartData {
    let urlRequest = try buildRequest(endpoint: .chartData, body: request)
    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    try validateResponse(response)
    return try JSONDecoder().decode(NatalChartDataResponse.self, from: data)
}
```

#### 2. HTTP Status Validation

URLSession's `data(for:)` does NOT throw on HTTP error codes (e.g., 404, 500). Manual validation required:

```swift
func validateResponse(_ response: URLResponse) throws {
    guard let httpResponse = response as? HTTPURLResponse else {
        throw APIError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
        throw APIError.httpError(statusCode: httpResponse.statusCode)
    }
}
```

#### 3. Retry with Exponential Backoff

For transient network errors (timeouts, 5xx errors):

```swift
func fetchWithRetry<T>(maxAttempts: Int = 3, operation: () async throws -> T) async throws -> T {
    var lastError: Error?

    for attempt in 0..<maxAttempts {
        do {
            return try await operation()
        } catch {
            lastError = error
            if attempt < maxAttempts - 1 {
                let delay = pow(2.0, Double(attempt)) // 1s, 2s, 4s
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    throw lastError ?? APIError.retryFailed
}
```

#### 4. Timeout Configuration

```swift
var config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 10.0  // 10 seconds
config.timeoutIntervalForResource = 30.0 // 30 seconds max
let session = URLSession(configuration: config)
```

#### 5. Task Cancellation Support

Swift concurrency's cancellation automatically propagates to URLSession:

```swift
Task {
    do {
        let chart = try await apiService.fetchNatalChart(birthData)
        // Handle success
    } catch is CancellationError {
        // User navigated away, cleanup
    } catch {
        // Handle other errors
    }
}
```

## Local Caching Strategy

### Decision: Hybrid SwiftData + FileManager Approach

**Data Models** → SwiftData (structured data)
**Chart Images** → FileManager (binary files)

### Rationale

1. **SwiftData Strengths**: Query, filter, and relationship management for chart metadata
2. **FileManager for Large Binary**: SVG/PNG files are better stored as files, not BLOBs
3. **Memory Efficiency**: Avoid loading large image data into SwiftData models
4. **Offline Access**: Both structured data and images persisted locally
5. **Cache Invalidation**: Easy to implement LRU or time-based expiration

### Implementation Approach

#### SwiftData Models

```swift
@Model
class CachedNatalChart {
    @Attribute(.unique) var id: UUID
    var birthData: BirthData // Name, date, time, location
    var generatedAt: Date
    var planetsJSON: Data // Encoded [Planet] array
    var housesJSON: Data // Encoded [House] array
    var aspectsJSON: Data // Encoded [Aspect] array
    var imageFileID: String? // Filename in Documents/ChartImages/
    var imageFormat: String? // "svg" or "png"

    init(id: UUID = UUID(), birthData: BirthData, ...) { ... }
}
```

#### Image Storage

```swift
class ChartImageCache {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    init() {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = docs.appendingPathComponent("ChartImages", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func saveImage(data: Data, fileID: String, format: String) throws {
        let url = cacheDirectory.appendingPathComponent("\(fileID).\(format)")
        try data.write(to: url)
    }

    func loadImage(fileID: String, format: String) throws -> Data {
        let url = cacheDirectory.appendingPathComponent("\(fileID).\(format)")
        return try Data(contentsOf: url)
    }
}
```

#### Cache Lookup Strategy

1. User requests chart for birth data (name, date, time, location)
2. Query SwiftData for matching `CachedNatalChart` (match on birth data hash or unique ID)
3. If found and < 30 days old:
   - Decode planets/houses/aspects from JSON
   - Load image from `ChartImageCache` using `imageFileID`
   - Return cached chart (no API call)
4. If not found or stale:
   - Fetch from API
   - Save to SwiftData + FileManager
   - Return fresh chart

### Cache Invalidation

- **Time-based**: Charts older than 30 days considered stale (astrological data doesn't change)
- **Manual**: User can force refresh
- **Storage Limits**: Implement LRU eviction if cache exceeds 100MB or 50 charts

## Error Handling Strategy

### Decision: Structured Error Hierarchy with User-Friendly Messages

### Error Types

```swift
enum NatalChartAPIError: LocalizedError {
    case invalidBirthData(String)
    case networkError(Error)
    case authenticationFailed
    case rateLimitExceeded(retryAfter: TimeInterval)
    case serverError(statusCode: Int)
    case invalidResponse
    case imageDownloadFailed(URL)
    case cachingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidBirthData(let reason):
            return "Invalid birth information: \(reason)"
        case .networkError:
            return "Unable to connect. Please check your internet connection."
        case .authenticationFailed:
            return "API authentication failed. Please check your credentials."
        case .rateLimitExceeded(let seconds):
            return "Request limit reached. Please wait \(Int(seconds)) seconds."
        case .serverError(let code):
            return "Server error (code \(code)). Please try again later."
        case .invalidResponse:
            return "Received invalid data from server. Please try again."
        case .imageDownloadFailed:
            return "Chart image could not be downloaded. Showing data only."
        case .cachingFailed:
            return "Chart generated but could not be saved for offline access."
        }
    }
}
```

### Rationale

1. **User-Centric Messages**: Avoid technical jargon (FR-012 requirement)
2. **Actionable Guidance**: Tell users what to do ("check internet", "wait N seconds")
3. **Graceful Degradation**: Image failure doesn't block chart data display
4. **Logging Support**: Technical details available for debugging

## Offline Support Implementation

### Decision: Cache-First Strategy with Clear Online/Offline Indicators

### User Experience

1. **Offline Mode Detection**:
   ```swift
   import Network

   class NetworkMonitor: ObservableObject {
       @Published var isConnected = true
       private let monitor = NWPathMonitor()

       init() {
           monitor.pathUpdateHandler = { [weak self] path in
               self?.isConnected = (path.status == .satisfied)
           }
           monitor.start(queue: .global())
       }
   }
   ```

2. **UI States**:
   - **Online + Cached**: Show cached chart with "Refresh" button
   - **Online + No Cache**: Show "Generate Chart" button
   - **Offline + Cached**: Show cached chart with "Offline" badge, disable refresh
   - **Offline + No Cache**: Show message "Internet required to generate charts. Connect to WiFi."

3. **Cache Priority**:
   - Always attempt to serve from cache first (instant load)
   - If online, optionally refresh in background
   - If offline, only show cached charts

### Rationale

- Meets FR-009 (offline data access) and FR-010 (offline image access)
- Aligns with Success Criteria SC-003 (offline accessibility)
- Provides clear user feedback per FR-012 (clear error messages)

## Data Mapping & Transformation

### Decision: DTO Pattern for API Responses

Separate API response models (DTOs) from domain models for:
1. **API Changes**: Insulates app from API schema evolution
2. **Data Transformation**: Convert API strings ("true"/"false") to Swift Bool
3. **Validation**: Catch malformed responses early
4. **Testing**: Mock API responses without affecting domain logic

### Example Mapping

```swift
// API DTO
struct PlanetDTO: Codable {
    let name: String
    let sign: String
    let full_degree: Double
    let is_retro: String // API returns "true"/"false" as string
}

// Domain Model
struct Planet {
    let name: PlanetType // Enum
    let sign: ZodiacSign // Enum
    let longitude: Double
    let isRetrograde: Bool // Swift Bool
}

// Mapper
extension Planet {
    init(from dto: PlanetDTO) throws {
        guard let planetType = PlanetType(rawValue: dto.name.lowercased()) else {
            throw MappingError.invalidPlanetName(dto.name)
        }
        guard let zodiacSign = ZodiacSign(rawValue: dto.sign.lowercased()) else {
            throw MappingError.invalidSign(dto.sign)
        }

        self.name = planetType
        self.sign = zodiacSign
        self.longitude = dto.full_degree
        self.isRetrograde = (dto.is_retro == "true")
    }
}
```

### Rationale

- **Type Safety**: Catch invalid API data at mapping boundary
- **Testability**: Test mapping logic independently
- **Maintainability**: API changes require updates only to mappers, not domain
- **SwiftData Compatibility**: Domain models are clean, SwiftData-friendly

## Testing Strategy

### Decision: Layered Testing with Mocks

1. **Unit Tests** (TDD):
   - `ProkralaAPIServiceTests`: Mock URLSession, test request building, response parsing
   - `ChartCacheServiceTests`: Test cache CRUD operations with in-memory SwiftData
   - `NatalChartMapperTests`: Verify DTO → Domain transformation
   - `RateLimiterTests`: Verify rate limit enforcement logic

2. **Integration Tests**:
   - `APIContractTests`: Real API calls with test credentials (CI environment variables)
   - Validate actual API responses match expected schemas
   - Run weekly to detect API breaking changes

3. **UI Tests**:
   - `ChartGenerationFlowTests`: End-to-end chart generation with mocked API
   - Offline mode scenarios
   - Error handling (rate limit, network failure)

### Mocking Approach

```swift
protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

class MockURLSession: URLSessionProtocol {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = mockError { throw error }
        return (mockData ?? Data(), mockResponse ?? URLResponse())
    }
}
```

### Rationale

- **TDD Compliance**: Constitution Principle III (NON-NEGOTIABLE)
- **Fast Tests**: Unit tests run without network calls
- **Regression Prevention**: Integration tests catch API schema changes
- **Confidence**: UI tests validate full user flows

## Migration Path from SwissEphemeris

### Decision: Parallel Implementation with Feature Flag

**Phase 1**: Build Prokerala integration alongside existing SwissEphemeris
**Phase 2**: Add feature flag in Config.swift: `useProkeralaAPI: Bool`
**Phase 3**: Test both implementations side-by-side
**Phase 4**: Default to Prokerala, remove SwissEphemeris in follow-up PR

### Rationale

1. **Risk Mitigation**: Can roll back if Prokerala has issues
2. **Accuracy Validation**: Compare calculations between systems
3. **Incremental Rollout**: Enable for beta testers first
4. **Clean Separation**: Eventual removal is straightforward

### Deprecated Code Handling

- Move `SwissEphemerisService.swift` to `AstroSvitla/Deprecated/`
- Remove `import SwissEphemeris` from app target
- Document removal plan in `MIGRATION_NOTES.md`

## Config.swift Updates

### Decision: Add Prokerala credentials with validation

```swift
// Add to Config.swift.example
enum Config {
    // MARK: - AstrologyAPI (Prokerala) Configuration

    static let astrologyAPIUserID = "YOUR_USER_ID_HERE"
    static let astrologyAPIKey = "YOUR_API_KEY_HERE"
    static let astrologyAPIBaseURL = "https://json.astrologyapi.com/v1"

    static var isAstrologyAPIConfigured: Bool {
        !astrologyAPIUserID.isEmpty &&
        astrologyAPIUserID != "YOUR_USER_ID_HERE" &&
        !astrologyAPIKey.isEmpty &&
        astrologyAPIKey != "YOUR_API_KEY_HERE"
    }

    // Update validate() method
    static func validate() throws {
        guard isOpenAIConfigured else {
            throw ConfigError.missingAPIKey("OpenAI API key not configured")
        }
        guard isAstrologyAPIConfigured else {
            throw ConfigError.missingAPIKey("AstrologyAPI credentials not configured")
        }
    }
}
```

### Rationale

- Consistent with existing OpenAI config pattern
- Enforces credential presence at app launch
- Clear error messages for developers
- `.example` file documents required setup

## Summary of Research Decisions

| Topic | Decision | Key Rationale |
|-------|----------|---------------|
| **API Provider** | AstrologyAPI.com (Prokerala) | Single provider for calculations + visualization, Western astrology focus, free tier |
| **Endpoints** | `western_chart_data` + `natal_wheel_chart` | Separate data/image for flexibility, error handling, caching |
| **Authentication** | Basic Auth with User ID + API Key | Standard, simple, secure when using HTTPS |
| **Networking** | URLSession with async/await | Modern Swift, no dependencies, testable, aligns with iOS 17+ |
| **Caching** | SwiftData (data) + FileManager (images) | Hybrid approach optimizes for structured data and binary files |
| **Rate Limiting** | Client-side tracking with UserDefaults | Prevents 429 errors, user-friendly messaging |
| **Error Handling** | Structured LocalizedError with UX messages | User-centric, actionable, graceful degradation |
| **Offline Support** | Cache-first with NetworkMonitor | Instant load, clear online/offline states, FR-009/010 compliance |
| **Data Mapping** | DTO pattern with explicit transformation | Type safety, API resilience, testability |
| **Testing** | TDD with mocked URLSession + integration tests | Constitution Principle III, fast feedback, contract validation |
| **Migration** | Parallel implementation with feature flag | Risk mitigation, validation, incremental rollout |

## Next Steps

- ✅ Research completed, all NEEDS CLARIFICATION resolved
- ⏭️ Proceed to Phase 1: Data Model Design (data-model.md)
- ⏭️ Proceed to Phase 1: API Contracts (contracts/ directory)
- ⏭️ Proceed to Phase 1: Quickstart Guide (quickstart.md)
