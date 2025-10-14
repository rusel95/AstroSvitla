# AstrologyAPI Integration Quickstart Guide

## Overview
This guide provides a complete walkthrough for integrating the new AstrologyAPI service into AstroSvitla. Follow these steps to implement natal chart generation with the api.astrology-api.io provider.

## Prerequisites
- iOS 17+ development environment
- Xcode 15+ with Swift 5.9+
- AstroSvitla project setup with existing SwiftUI/SwiftData infrastructure
- Network connectivity for API testing

## Integration Steps

### 1. Service Implementation

#### Create AstrologyAPI Service Structure
```bash
# Create directory structure
mkdir -p AstroSvitla/Services/AstrologyAPI

# Create service files
touch AstroSvitla/Services/AstrologyAPI/AstrologyAPIService.swift
touch AstroSvitla/Services/AstrologyAPI/AstrologyAPIModels.swift
touch AstroSvitla/Services/AstrologyAPI/AstrologyAPIDTOMapper.swift
```

#### Implement Core Service (AstrologyAPIService.swift)
```swift
import Foundation

public final class AstrologyAPIService: ObservableObject {
    private let baseURL = "https://api.astrology-api.io/api/v3"
    private let session: URLSession
    private let rateLimiter: RateLimiter
    
    public init(session: URLSession = .shared, rateLimiter: RateLimiter) {
        self.session = session
        self.rateLimiter = rateLimiter
    }
    
    public func generateNatalChart(
        name: String,
        birthDate: Date,
        birthLocation: Location,
        options: ChartOptions? = nil
    ) async throws -> NatalChart {
        try await rateLimiter.executeRequest {
            // Implementation follows DTO mapping pattern
            let request = try buildNatalChartRequest(/* parameters */)
            let (data, _) = try await session.data(for: request)
            let response = try JSONDecoder().decode(AstrologyAPINatalChartResponse.self, from: data)
            return AstrologyAPIDTOMapper.mapToDomain(response)
        }
    }
    
    public func generateChartSVG(
        name: String,
        birthDate: Date,
        birthLocation: Location,
        svgOptions: SVGOptions? = nil
    ) async throws -> String {
        // SVG generation implementation
    }
}
```

#### Add Models (AstrologyAPIModels.swift)
Copy the complete DTO structures from `data-model.md`:
- `AstrologyAPINatalChartRequest`
- `AstrologyAPINatalChartResponse`
- `AstrologyAPISVGRequest`
- `AstrologyAPISVGResponse`
- Supporting models (Subject, BirthData, ChartOptions, etc.)

#### Implement Mapper (AstrologyAPIDTOMapper.swift)
```swift
public struct AstrologyAPIDTOMapper {
    public static func mapToDomain(_ response: AstrologyAPINatalChartResponse) -> NatalChart {
        // Transform AstrologyAPI DTOs to domain models
        // Implementation details in data-model.md
    }
    
    public static func mapFromDomain(/* domain parameters */) -> AstrologyAPINatalChartRequest {
        // Transform domain models to AstrologyAPI DTOs
    }
}
```

### 2. Configuration Setup

#### Update Config.swift
```swift
public struct AstrologyAPIConfig {
    public static let baseURL = "https://api.astrology-api.io/api/v3"
    public static let rateLimitRequests = 60
    public static let rateLimitTimeWindow: TimeInterval = 60
    public static let requestTimeout: TimeInterval = 30
}
```

### 3. Dependency Injection

#### Update RepositoryContext.swift
```swift
public class RepositoryContext: ObservableObject {
    // ... existing services ...
    
    @Published public private(set) var astrologyAPIService: AstrologyAPIService
    
    public init() {
        // ... existing initialization ...
        
        self.astrologyAPIService = AstrologyAPIService(
            rateLimiter: RateLimiter(
                maxRequests: AstrologyAPIConfig.rateLimitRequests,
                timeWindow: AstrologyAPIConfig.rateLimitTimeWindow
            )
        )
    }
}
```

### 4. Service Integration

#### Update NatalChartService.swift
```swift
public final class NatalChartService: ObservableObject {
    private let astrologyAPIService: AstrologyAPIService
    // Keep existing services commented for fallback
    // private let freeAstrologyService: FreeAstrologyAPIService
    // private let prokeralaService: ProkeralaAPIService
    
    public func generateChart(
        name: String,
        birthDate: Date,
        location: Location
    ) async throws -> NatalChart {
        // Primary: Use AstrologyAPI
        do {
            return try await astrologyAPIService.generateNatalChart(
                name: name,
                birthDate: birthDate,
                birthLocation: location
            )
        } catch {
            // Log error and potentially fallback to other services
            throw error
        }
    }
}
```

### 5. Testing Integration

#### Unit Tests (AstroSvitlaTests/Services/AstrologyAPI/)
```swift
@Test func testNatalChartGeneration() async throws {
    // Given
    let mockSession = MockURLSession()
    let rateLimiter = RateLimiter(maxRequests: 100, timeWindow: 60)
    let service = AstrologyAPIService(session: mockSession, rateLimiter: rateLimiter)
    
    // When
    let chart = try await service.generateNatalChart(/* test parameters */)
    
    // Then
    #expect(chart.planets.count > 0)
    #expect(chart.houses.count == 12)
}
```

#### Manual Testing with HTTP Examples
Use the examples in `contracts/astrology-api-examples.http` to test API endpoints directly.

### 6. UI Integration

#### Update Chart Generation Views
```swift
// In ChartInputView or relevant UI component
Button("Generate Chart") {
    Task {
        do {
            let chart = try await repositoryContext.natalChartService.generateChart(
                name: inputName,
                birthDate: inputBirthDate,
                location: inputLocation
            )
            // Handle successful chart generation
        } catch {
            // Handle error
        }
    }
}
```

## Validation Checklist

### Functional Validation
- [ ] Service successfully generates natal charts from AstrologyAPI
- [ ] SVG generation works with different themes
- [ ] Error handling gracefully manages API failures
- [ ] Rate limiting prevents API quota exceeded errors
- [ ] Domain model mapping preserves all required data

### Integration Validation
- [ ] New service integrates with existing chart cache
- [ ] UI correctly displays charts generated from AstrologyAPI
- [ ] Existing functionality remains unaffected
- [ ] Performance meets existing app standards

### Testing Validation
- [ ] Unit tests cover service layer and mapping logic
- [ ] Integration tests validate end-to-end chart generation
- [ ] Error scenarios properly tested and handled
- [ ] Rate limiting behavior validated

## Troubleshooting

### Common Issues
1. **Network Timeout**: Check `AstrologyAPIConfig.requestTimeout` setting
2. **Rate Limiting**: Verify `RateLimiter` configuration matches API limits
3. **Mapping Errors**: Validate DTO structures match API response format
4. **Missing Data**: Ensure all required fields are included in requests

### Debug Commands
```bash
# Test API connectivity
curl -X POST https://api.astrology-api.io/api/v3/charts/natal \
  -H "Content-Type: application/json" \
  -d '{"subject":{"name":"Test","birth_data":{"year":1990,"month":5,"day":15,"hour":14,"minute":30,"second":0,"city":"London","country_code":"GB"}}}'

# Run service tests
xcodebuild test -scheme AstroSvitla -only-testing:AstroSvitlaTests/Services/AstrologyAPI
```

## Next Steps

1. **Performance Optimization**: Monitor API response times and implement caching strategies
2. **Error Recovery**: Implement fallback to existing APIs if AstrologyAPI fails
3. **Feature Enhancement**: Add support for additional chart types and options
4. **Monitoring**: Add logging and analytics for API usage tracking

## Resources

- API Documentation: `contracts/astrology-api-openapi.json`
- HTTP Examples: `contracts/astrology-api-examples.http`
- Technical Decisions: `research.md`
- Data Models: `data-model.md`
- Implementation Plan: `plan.md`