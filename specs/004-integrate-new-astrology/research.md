# Research: New Astrology API Integration

**Feature**: Integrate api.astrology-api.io for Natal Chart Generation
**Date**: October 11, 2025
**Phase**: 0 - Research & Technical Decisions

## Overview

This document consolidates research on integrating api.astrology-api.io as the new primary astrology calculation service for AstroSvitla, replacing the current Free Astrology API while preserving existing architecture and functionality.

## Research Areas

### 1. API Authentication & Rate Limiting

**Decision**: Use direct HTTP requests without authentication (API is currently open access)
**Rationale**: 
- The api.astrology-api.io documentation shows "Authentication Not Required" for all endpoints
- This simplifies integration and removes credential management complexity
- No API key management or rotation required
- Reduces potential security exposure points

**Alternatives Considered**:
- Bearer token authentication: Not offered by the API
- API key authentication: Not currently required by the service
- OAuth2: Overkill for this use case and not supported

**Rate Limiting Strategy**:
- Implement client-side rate limiting using existing `RateLimiter.swift`
- Documentation doesn't specify limits, so start conservatively at 1 request/second
- Monitor response headers for any rate limit indicators
- Implement exponential backoff for 429 responses

### 2. API Response Structure & Mapping

**Decision**: Create dedicated DTOs matching api.astrology-api.io JSON structure with clean mapping to existing domain models
**Rationale**:
- API returns comprehensive JSON with nested planetary, house, and aspect data
- Response structure: `subject_data` (birth info) + `chart_data` (planetary positions, houses, aspects)
- SVG endpoint returns image/svg+xml content type
- Clear separation between API contract and domain models maintains architecture integrity

**Key Response Fields for Natal Chart**:
```json
{
  "subject_data": {
    "name": "string",
    "year": 1990, "month": 5, "day": 15,
    "hour": 14, "minute": 30,
    "city": "London", "nation": "GB",
    "lng": -0.1278, "lat": 51.5074,
    "tz_str": "Europe/London"
  },
  "chart_data": {
    "planetary_positions": [
      {
        "name": "Sun",
        "sign": "Tau", "sign_num": 1,
        "position": 24.83, "abs_pos": 54.83,
        "house": "Tenth_House",
        "retrograde": false
      }
    ],
    "house_cusps": [
      { "house": 1, "sign": "Leo", "degree": 15.42 }
    ],
    "aspects": [
      {
        "planet1": "Sun", "planet2": "Moon",
        "aspect": "Trine", "orb": 2.5,
        "applying": true
      }
    ]
  }
}
```

**Mapping Strategy**:
- `AstrologyAPIModels.swift`: DTOs matching API JSON structure exactly
- `AstrologyAPIDTOMapper.swift`: Transform DTOs to existing domain models
- Preserve all existing domain model interfaces
- No changes required to caching or UI layers

### 3. Error Handling Patterns

**Decision**: Implement comprehensive error handling with fallback and retry mechanisms
**Rationale**:
- Network reliability crucial for user experience
- Existing caching provides natural fallback for API failures
- User should never see raw API errors

**Error Categories**:
1. **Network Errors**: Connection timeouts, no internet
2. **API Errors**: 4xx/5xx HTTP responses  
3. **Parsing Errors**: Malformed JSON responses
4. **Rate Limiting**: 429 responses

**Handling Strategy**:
```swift
enum AstrologyAPIError: LocalizedError {
    case networkUnavailable
    case invalidResponse(statusCode: Int)
    case rateLimitExceeded(retryAfter: TimeInterval?)
    case parsingFailed(Error)
    case invalidBirthData
    
    var errorDescription: String? {
        // User-friendly error messages
    }
}
```

**Retry Logic**:
- Exponential backoff for network failures (1s, 2s, 4s max)
- Respect Retry-After headers for rate limiting
- Fall back to cached data when available
- Surface meaningful errors to users only when cache unavailable

### 4. Configuration Management

**Decision**: Follow existing `Config.swift` pattern with environment variable support
**Rationale**:
- Maintains consistency with existing OpenAI and Prokerala API patterns
- Currently no API key required, but prepare for future authentication
- Environment variable support enables different configs per environment

**Implementation**:
```swift
// In Config.swift
static let astrologyAPIBaseURL = "https://api.astrology-api.io"
static let astrologyAPIKey = ProcessInfo.processInfo.environment["ASTROLOGY_API_KEY"] ?? ""

static var isAstrologyAPIConfigured: Bool {
    !astrologyAPIBaseURL.isEmpty
    // API key check if/when authentication is required
}
```

**Security Considerations**:
- No credentials to protect currently
- Base URL could be configurable for testing
- Future-proof for potential authentication requirements
- Follow existing `.example` file patterns if credentials added

### 5. Performance & Caching Strategy

**Decision**: Leverage existing caching infrastructure with new API as data source
**Rationale**:
- Current `ChartCacheService` and `ImageCacheService` work with any data source
- API response times appear fast (~200-400ms according to docs)
- SVG caching reduces repeated image generation calls
- Offline capability preserved through existing cache

**Performance Optimizations**:
- Cache natal chart data using existing `CachedNatalChart` SwiftData model
- Cache SVG images using existing `ImageCacheService`
- Parallel requests for chart data and SVG when both needed
- Respect existing cache TTL and invalidation logic

## Integration Architecture

### Service Layer Design
```swift
protocol AstrologyAPIServiceProtocol {
    func generateNatalChart(_ request: NatalChartRequest) async throws -> AstrologyAPINatalChartResponse
    func generateChartSVG(_ request: NatalChartSVGRequest) async throws -> Data
}

final class AstrologyAPIService: AstrologyAPIServiceProtocol {
    private let baseURL: String
    private let urlSession: URLSession
    private let rateLimiter: RateLimiter
    
    // Implementation with error handling and rate limiting
}
```

### DTO Mapping
```swift
enum AstrologyAPIDTOMapper {
    static func toDomain(
        response: AstrologyAPINatalChartResponse,
        birthDetails: BirthDetails
    ) throws -> NatalChart {
        // Transform API response to existing domain model
    }
}
```

## Risk Assessment

### High Risk
- **API Reliability**: Third-party service dependency
  - *Mitigation*: Robust caching and fallback mechanisms

### Medium Risk  
- **Response Format Changes**: API updates could break parsing
  - *Mitigation*: Comprehensive error handling and graceful degradation

### Low Risk
- **Rate Limiting**: Unknown limits could cause throttling
  - *Mitigation*: Conservative rate limiting and exponential backoff

## Migration Strategy

1. **Implement new API service alongside existing services**
2. **Update `NatalChartService` to use new API**
3. **Comment out old API implementations with clear markers**
4. **Preserve all existing tests (commented where necessary)**
5. **Maintain backward compatibility throughout**

## Summary of Decisions

| Area | Decision | Key Benefits |
|------|----------|--------------|
| **Authentication** | No auth required currently | Simplified integration, no credential management |
| **Data Mapping** | Dedicated DTOs + mapper | Clean architecture, preserves existing models |
| **Error Handling** | Comprehensive with fallbacks | Robust user experience, graceful degradation |
| **Configuration** | Environment variables + Config.swift | Consistency, future-proof, testable |
| **Performance** | Existing cache + new data source | Maintains offline capability, optimized UX |

**Ready for Phase 1**: All technical unknowns resolved. Architecture approach validated.