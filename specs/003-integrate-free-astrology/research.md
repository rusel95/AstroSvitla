# Research: Free Astrology API Integration

**Feature**: Integrate Free Astrology API
**Date**: 2025-10-10
**Status**: Complete

## Overview

This document consolidates research findings for integrating the Free Astrology API as a test alternative to existing Swiss Ephemeris and Prokerala API implementations. All unknowns from the Technical Context have been resolved.

## Research Questions & Findings

### 1. Authentication Method

**Question**: How does Free Astrology API handle authentication?

**Decision**: HTTP header-based API key authentication

**Rationale**:
- API requires `x-api-key` header with API key value
- Simple to implement with URLSession
- No OAuth2 complexity like Prokerala
- API key obtained through signup at https://freeastrologyapi.com/signup

**Implementation Details**:
```swift
// Request headers
headers = [
    "Content-Type": "application/json",
    "x-api-key": Config.freeAstrologyAPIKey
]
```

**Alternatives Considered**:
- OAuth2 (like Prokerala): Not supported by Free Astrology API
- Query parameter auth: Less secure, not used by this API
- Basic Auth: Not supported

---

### 2. Rate Limits & Pricing

**Question**: What are the rate limits and costs for Free Astrology API?

**Decision**: Use free tier (50 requests/day) for testing phase

**Rationale**:
- Free tier provides 50 requests per day (INR 0/month)
- Sufficient for testing scope (10-20 test charts)
- Each chart requires 4 API calls (planets, houses, aspects, natal-chart-wheel)
- 50 requests/day = ~12 complete charts per day
- Testing phase expected to last 1-2 weeks with ~5 charts per day

**Pricing Tiers**:
| Tier | Cost | Requests/Month | Requests/Second | Best For |
|------|------|----------------|-----------------|----------|
| Free | INR 0 | 1,500/month (50/day) | N/A | Testing, POC |
| Mercury | INR 1,000 (~$12 USD) | 50,000 | 10 | Small apps |
| Venus | INR 3,500 (~$42 USD) | 200,000 | 100 | Medium apps |
| Saturn | INR 6,500 (~$78 USD) | 500,000 | 1,000 | Large apps |

**Constraints**:
- Free tier: 50 requests/day (no per-second limit specified)
- Must implement request counting to avoid exceeding limits
- Should reuse existing RateLimiter infrastructure
- Cache all responses to minimize redundant API calls

**Alternatives Considered**:
- Paid tier for testing: Unnecessary cost for experimental feature
- No rate limiting: Would risk hitting limits and getting blocked

---

### 3. API Endpoints & Response Formats

**Question**: What data formats do the 4 endpoints return?

**Decision**: JSON responses for planets/houses/aspects, SVG URL for chart

**Findings by Endpoint**:

#### Planets Endpoint
- URL: `https://json.freeastrologyapi.com/western/planets`
- Method: POST
- Response: JSON array of planet objects
- Fields: name, full_degree, normalized_degree, speed, is_retrograde, sign_num, sign

#### Houses Endpoint
- URL: `https://json.freeastrologyapi.com/western/houses`
- Method: POST
- Response: JSON array of house objects
- Fields: house_num, degree, normalized_degree, sign_num, sign
- Supports: Placidus, Koch, Whole Signs, Equal, Regiomontanus, Porphyry, Vehlow

#### Aspects Endpoint
- URL: `https://json.freeastrologyapi.com/western/aspects`
- Method: POST
- Response: JSON array of aspect relationships
- Fields: planet1_name, planet2_name, aspect_name, orb_degree
- Configurable: Custom orbs, excluded planets, allowed aspects

#### Natal Wheel Chart Endpoint
- URL: `https://json.freeastrologyapi.com/western/natal-wheel-chart`
- Method: POST
- Response: JSON with `chart_url` field (SVG image URL)
- Customizable: Colors, aspect display, language

**Common Request Parameters**:
```json
{
  "year": 1990,
  "month": 5,
  "date": 15,
  "hours": 14,
  "minutes": 30,
  "seconds": 0,
  "latitude": 40.7128,
  "longitude": -74.0060,
  "timezone": -4.0,
  "observation_point": "topocentric",
  "ayanamsha": "tropical",
  "house_system": "placidus"
}
```

**Rationale**:
- All endpoints follow consistent request/response patterns
- JSON parsing straightforward with Swift Codable
- SVG chart can be downloaded and cached like Prokerala PNG/SVG
- Response structure maps cleanly to existing domain models

**Alternatives Considered**:
- GraphQL: Not supported by Free Astrology API
- XML responses: API only provides JSON

---

### 4. Error Handling Patterns

**Question**: How does the API communicate errors?

**Decision**: Implement standard HTTP status code handling with fallback error parsing

**Expected Error Scenarios**:
1. **Authentication failure (401)**: Invalid or missing API key
2. **Rate limit exceeded (429)**: Too many requests
3. **Invalid input (400)**: Missing or invalid parameters
4. **Server error (500)**: API service issues
5. **Network errors**: Timeout, no connectivity

**Error Handling Strategy**:
```swift
enum FreeAstrologyError: LocalizedError {
    case authenticationFailed
    case rateLimitExceeded(retryAfter: Int)
    case invalidRequest(message: String)
    case serverError
    case networkError(Error)
    case invalidResponse

    var errorDescription: String? {
        // User-friendly error messages
    }
}
```

**Rationale**:
- Consistent with existing error handling patterns (see NatalChartService.ServiceError)
- Provides clear feedback for debugging
- Allows graceful degradation (fallback to cache)

**Alternatives Considered**:
- Generic errors: Less actionable for users and developers
- Silent failures: Would make debugging difficult

---

### 5. Data Mapping Strategy

**Question**: How to map Free Astrology API responses to existing domain models?

**Decision**: Create dedicated DTOMapper following existing Prokerala pattern

**Mapping Requirements**:

**Planets**: `PlanetResponse` → `Planet`
```swift
// DTO (from API)
struct PlanetResponse: Codable {
    let name: String
    let fullDegree: Double
    let normalizedDegree: Double
    let speed: Double
    let isRetrograde: Bool
    let signNum: Int
    let sign: String
}

// Domain Model (existing)
struct Planet {
    let id: UUID
    let name: String
    let longitude: Double  // maps from fullDegree
    let latitude: Double   // not provided by API, default to 0
    let speed: Double
    let isRetrograde: Bool
    let sign: ZodiacSign   // map from signNum
}
```

**Houses**: `HouseResponse` → `House`
```swift
// DTO
struct HouseResponse: Codable {
    let houseNum: Int
    let degree: Double
    let normalizedDegree: Double
    let signNum: Int
    let sign: String
}

// Domain Model
struct House {
    let id: UUID
    let number: Int       // maps from houseNum
    let longitude: Double // maps from degree
    let sign: ZodiacSign  // map from signNum
}
```

**Aspects**: `AspectResponse` → `Aspect`
```swift
// DTO
struct AspectResponse: Codable {
    let planet1Name: String
    let planet2Name: String
    let aspectName: String
    let orbDegree: Double
}

// Domain Model
struct Aspect {
    let id: UUID
    let planet1: String
    let planet2: String
    let type: AspectType  // map from aspectName
    let orb: Double       // maps from orbDegree
    let angle: Double     // calculate from aspect type
}
```

**Chart Visualization**: `ChartResponse` → `ChartVisualization`
```swift
// DTO
struct NatalChartResponse: Codable {
    let chartUrl: String
}

// Domain Model
struct ChartVisualization {
    let imageFileID: String  // extract from URL or generate UUID
    let imageFormat: String  // "svg"
    let imageURL: String     // chartUrl
}
```

**Rationale**:
- Follows existing DTOMapper pattern from Prokerala implementation
- Maintains clean separation between API contracts and domain models
- Allows domain models to remain unchanged (per constraints)
- Makes it easy to switch APIs by swapping mappers

**Alternatives Considered**:
- Direct use of API DTOs in domain: Couples domain to specific API
- Modify existing domain models: Violates constraint to preserve existing models

---

### 6. Testing Strategy

**Question**: How to ensure API integration works correctly?

**Decision**: Implement TDD with contract tests, unit tests, and integration tests

**Test Layers**:

1. **Contract Tests** (verify API behavior):
   - `PlanetsEndpointContractTests`: Validate planets endpoint response
   - `HousesEndpointContractTests`: Validate houses endpoint response
   - `AspectsEndpointContractTests`: Validate aspects endpoint response
   - `NatalChartEndpointContractTests`: Validate chart image endpoint response

2. **Unit Tests** (isolated logic):
   - `FreeAstrologyAPIServiceTests`: Test HTTP client logic
   - `FreeAstrologyDTOMapperTests`: Test DTO → Domain mapping
   - `FreeAstrologyDTOTests`: Test JSON parsing

3. **Integration Tests** (end-to-end):
   - `NatalChartGenerationTests`: Test full chart generation flow

4. **Mock Objects**:
   - `MockFreeAstrologyAPIService`: Test double for view models

**Rationale**:
- Contract tests catch API changes early
- Unit tests ensure correct mapping logic
- Integration tests validate full workflow
- Mocks enable testing without API calls

**Alternatives Considered**:
- Manual testing only: Not sustainable, no regression detection
- Only integration tests: Slow, hard to diagnose failures

---

## Implementation Checklist

- [x] Authentication method determined (API key header)
- [x] Rate limits understood (50 requests/day free tier)
- [x] Pricing evaluated (free tier sufficient for testing)
- [x] API endpoints documented (4 endpoints, JSON/SVG responses)
- [x] Request/response formats understood
- [x] Error handling patterns defined
- [x] DTO mapping strategy designed
- [x] Testing approach established

## Next Phase

All research complete. Ready for **Phase 1: Design & Contracts**.

Phase 1 will produce:
1. `data-model.md` - Detailed DTO and domain model definitions
2. `contracts/` - HTTP contract files for all 4 endpoints
3. Contract tests - Failing tests for TDD workflow
4. `quickstart.md` - Manual testing guide
5. Updated `CLAUDE.md` - Agent context with Free Astrology API info
