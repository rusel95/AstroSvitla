# Data Model: Free Astrology API Integration

**Feature**: Integrate Free Astrology API
**Date**: 2025-10-10
**Status**: Design Complete

## Overview

This document defines the data transfer objects (DTOs) for Free Astrology API integration and their mapping to existing domain models. All DTOs follow Swift Codable conventions and match the API's JSON response structure.

## Data Flow

```
Free Astrology API (JSON)
    ↓
FreeAstrologyModels (DTOs)
    ↓
FreeAstrologyDTOMapper
    ↓
Domain Models (NatalChart, Planet, House, Aspect)
    ↓
ChartCacheService (SwiftData persistence)
```

## DTO Models (API Layer)

### Base Request DTO

```swift
/// Common request parameters for all Free Astrology API endpoints
struct FreeAstrologyRequest: Codable {
    let year: Int
    let month: Int
    let date: Int
    let hours: Int
    let minutes: Int
    let seconds: Int
    let latitude: Double
    let longitude: Double
    let timezone: Double

    // Optional configuration
    let observationPoint: String?  // "topocentric" or "geocentric"
    let ayanamsha: String?         // "tropical", "sayana", "lahiri"
    let houseSystem: String?       // "placidus", "koch", "whole_signs", etc.
    let language: String?          // "en", "es", "fr", etc.

    enum CodingKeys: String, CodingKey {
        case year, month, date
        case hours, minutes, seconds
        case latitude, longitude, timezone
        case observationPoint = "observation_point"
        case ayanamsha
        case houseSystem = "house_system"
        case language
    }

    /// Initialize from BirthDetails domain model
    init(birthDetails: BirthDetails, houseSystem: String = "placidus") {
        // Map BirthDetails to API request format
    }
}
```

**Validation Rules**:
- `year`: 1-9999
- `month`: 1-12
- `date`: 1-31 (validated against month)
- `hours`: 0-23
- `minutes`: 0-59
- `seconds`: 0-59
- `latitude`: -90.0 to 90.0
- `longitude`: -180.0 to 180.0
- `timezone`: -12.0 to 14.0

---

### Planets Response DTO

```swift
/// Response from /western/planets endpoint
struct PlanetsResponse: Codable {
    let status: String
    let data: PlanetsData
}

struct PlanetsData: Codable {
    let planets: [PlanetDTO]
}

struct PlanetDTO: Codable {
    let name: String
    let fullDegree: Double
    let normalizedDegree: Double
    let speed: Double
    let isRetrograde: Bool
    let signNum: Int
    let sign: String

    enum CodingKeys: String, CodingKey {
        case name
        case fullDegree = "full_degree"
        case normalizedDegree = "normalized_degree"
        case speed
        case isRetrograde = "is_retrograde"
        case signNum = "sign_num"
        case sign
    }
}
```

**Fields**:
- `name`: Planet name (e.g., "Sun", "Moon", "Mars", "Ascendant")
- `fullDegree`: Absolute degree position (0-359.999)
- `normalizedDegree`: Degree within sign (0-29.999)
- `speed`: Daily motion in degrees
- `isRetrograde`: True if planet appears retrograde
- `signNum`: Zodiac sign number (1=Aries, 2=Taurus, ..., 12=Pisces)
- `sign`: Zodiac sign name

**Expected Planets**:
- Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn
- Uranus, Neptune, Pluto
- Ascendant (calculated point)
- North Node, South Node
- Chiron, Lilith (optional)
- Asteroids: Ceres, Vesta, Juno, Pallas (optional)

---

### Houses Response DTO

```swift
/// Response from /western/houses endpoint
struct HousesResponse: Codable {
    let status: String
    let data: HousesData
}

struct HousesData: Codable {
    let houses: [HouseDTO]
}

struct HouseDTO: Codable {
    let houseNum: Int
    let degree: Double
    let normalizedDegree: Double
    let signNum: Int
    let sign: String

    enum CodingKeys: String, CodingKey {
        case houseNum = "house_num"
        case degree
        case normalizedDegree = "normalized_degree"
        case signNum = "sign_num"
        case sign
    }
}
```

**Fields**:
- `houseNum`: House number (1-12)
- `degree`: Absolute degree of house cusp (0-359.999)
- `normalizedDegree`: Degree within sign (0-29.999)
- `signNum`: Zodiac sign number at cusp
- `sign`: Zodiac sign name at cusp

**House Systems Supported**:
- "placidus" (default)
- "koch"
- "whole_signs"
- "equal"
- "regiomontanus"
- "porphyry"
- "vehlow"

---

### Aspects Response DTO

```swift
/// Response from /western/aspects endpoint
struct AspectsResponse: Codable {
    let status: String
    let data: AspectsData
}

struct AspectsData: Codable {
    let aspects: [AspectDTO]
}

struct AspectDTO: Codable {
    let planet1Name: String
    let planet2Name: String
    let aspectName: String
    let orbDegree: Double?

    enum CodingKeys: String, CodingKey {
        case planet1Name = "planet1_name"
        case planet2Name = "planet2_name"
        case aspectName = "aspect_name"
        case orbDegree = "orb_degree"
    }
}
```

**Fields**:
- `planet1Name`: First planet in aspect
- `planet2Name`: Second planet in aspect
- `aspectName`: Aspect type name
- `orbDegree`: Orb (exactness) of aspect in degrees

**Aspect Types**:
- "Conjunction" (0°)
- "Opposition" (180°)
- "Trine" (120°)
- "Square" (90°)
- "Sextile" (60°)
- "Semi-Sextile" (30°)
- "Quintile" (72°)
- "Septile" (51.43°)
- "Octile" (45°)
- "Novile" (40°)
- "Quincunx" (150°)
- "Sesquiquadrate" (135°)

---

### Natal Chart Response DTO

```swift
/// Response from /western/natal-wheel-chart endpoint
struct NatalChartResponse: Codable {
    let status: String
    let data: NatalChartData
}

struct NatalChartData: Codable {
    let chartUrl: String

    enum CodingKeys: String, CodingKey {
        case chartUrl = "chart_url"
    }
}
```

**Fields**:
- `chartUrl`: URL to SVG chart image (expires after some time, should be downloaded immediately)

**Chart Customization Options** (request parameters):
- `chart_color`: Hex color for chart elements
- `aspect_color`: Hex color for aspect lines
- `exclude_planets`: Array of planet names to hide
- `allowed_aspects`: Array of aspect names to display
- Custom orb values for each aspect type

---

## Domain Models (Existing - No Changes)

### Planet

```swift
struct Planet: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let longitude: Double
    let latitude: Double
    let speed: Double
    let isRetrograde: Bool
    let sign: ZodiacSign

    // Calculated from longitude
    var degree: Double {
        longitude.truncatingRemainder(dividingBy: 30)
    }
}
```

**Mapping Notes**:
- `id`: Generate new UUID
- `name`: Direct from `PlanetDTO.name`
- `longitude`: From `PlanetDTO.fullDegree`
- `latitude`: Default to 0.0 (API doesn't provide declination)
- `speed`: From `PlanetDTO.speed`
- `isRetrograde`: From `PlanetDTO.isRetrograde`
- `sign`: Map from `PlanetDTO.signNum`

---

### House

```swift
struct House: Identifiable, Codable, Hashable {
    let id: UUID
    let number: Int
    let longitude: Double
    let sign: ZodiacSign

    var degree: Double {
        longitude.truncatingRemainder(dividingBy: 30)
    }
}
```

**Mapping Notes**:
- `id`: Generate new UUID
- `number`: From `HouseDTO.houseNum`
- `longitude`: From `HouseDTO.degree`
- `sign`: Map from `HouseDTO.signNum`

---

### Aspect

```swift
struct Aspect: Identifiable, Codable, Hashable {
    let id: UUID
    let planet1: String
    let planet2: String
    let type: AspectType
    let orb: Double
    let angle: Double
}
```

**Mapping Notes**:
- `id`: Generate new UUID
- `planet1`: From `AspectDTO.planet1Name`
- `planet2`: From `AspectDTO.planet2Name`
- `type`: Map from `AspectDTO.aspectName` to AspectType enum
- `orb`: From `AspectDTO.orbDegree`
- `angle`: Calculate from AspectType (e.g., .conjunction = 0, .trine = 120)

---

### ChartVisualization

```swift
struct ChartVisualization: Codable {
    let imageFileID: String
    let imageFormat: String
    let imageURL: String?
}
```

**Mapping Notes**:
- `imageFileID`: Generate UUID for local cache storage
- `imageFormat`: Always "svg" for Free Astrology API
- `imageURL`: From `NatalChartData.chartUrl`

---

## Mapper Implementation

### FreeAstrologyDTOMapper

```swift
enum FreeAstrologyDTOMapper {

    /// Map complete API responses to NatalChart domain model
    static func toDomain(
        planets: PlanetsResponse,
        houses: HousesResponse,
        aspects: AspectsResponse,
        chart: NatalChartResponse,
        birthDetails: BirthDetails
    ) throws -> NatalChart {
        // Combine all mapped data into NatalChart
    }

    /// Map planets response to domain model
    static func mapPlanets(_ response: PlanetsResponse) throws -> [Planet] {
        response.data.planets.map { dto in
            Planet(
                id: UUID(),
                name: dto.name,
                longitude: dto.fullDegree,
                latitude: 0.0,
                speed: dto.speed,
                isRetrograde: dto.isRetrograde,
                sign: ZodiacSign(rawValue: dto.signNum) ?? .aries
            )
        }
    }

    /// Map houses response to domain model
    static func mapHouses(_ response: HousesResponse) throws -> [House] {
        response.data.houses.map { dto in
            House(
                id: UUID(),
                number: dto.houseNum,
                longitude: dto.degree,
                sign: ZodiacSign(rawValue: dto.signNum) ?? .aries
            )
        }
    }

    /// Map aspects response to domain model
    static func mapAspects(_ response: AspectsResponse) throws -> [Aspect] {
        response.data.aspects.compactMap { dto in
            guard let aspectType = AspectType.from(name: dto.aspectName) else {
                return nil
            }
            return Aspect(
                id: UUID(),
                planet1: dto.planet1Name,
                planet2: dto.planet2Name,
                type: aspectType,
                orb: dto.orbDegree ?? 0.0,
                angle: aspectType.angle
            )
        }
    }

    /// Map chart visualization response to domain model
    static func mapVisualization(_ response: NatalChartResponse) -> ChartVisualization {
        ChartVisualization(
            imageFileID: UUID().uuidString,
            imageFormat: "svg",
            imageURL: response.data.chartUrl
        )
    }
}
```

**Error Handling**:
```swift
enum MappingError: LocalizedError {
    case missingRequiredData(String)
    case invalidPlanetData
    case invalidHouseData
    case invalidAspectData

    var errorDescription: String? {
        switch self {
        case .missingRequiredData(let field):
            return "Required data missing: \(field)"
        case .invalidPlanetData:
            return "Unable to parse planet positions"
        case .invalidHouseData:
            return "Unable to parse house cusps"
        case .invalidAspectData:
            return "Unable to parse aspects"
        }
    }
}
```

---

## State Transitions

### Chart Generation Flow

```
1. Input: BirthDetails
   ↓
2. Transform: BirthDetails → FreeAstrologyRequest
   ↓
3. API Calls (parallel):
   - POST /western/planets → PlanetsResponse
   - POST /western/houses → HousesResponse
   - POST /western/aspects → AspectsResponse
   - POST /western/natal-wheel-chart → NatalChartResponse
   ↓
4. Mapping:
   - PlanetsResponse → [Planet]
   - HousesResponse → [House]
   - AspectsResponse → [Aspect]
   - NatalChartResponse → ChartVisualization
   ↓
5. Aggregation:
   - All mapped data → NatalChart
   ↓
6. Persistence:
   - NatalChart → ChartCacheService → SwiftData
   - SVG download → ImageCacheService → FileManager
   ↓
7. Output: NatalChart (with cached image)
```

**Error States**:
- Network failure → Use cached chart if available
- Authentication error → Prompt for valid API key
- Rate limit exceeded → Show retry timer
- Invalid response → Log and show user-friendly error
- Partial data → Log warning, use available data if sufficient

---

## Testing Strategy

### DTO Tests

```swift
// Test JSON parsing
func testPlanetDTODecoding() throws {
    let json = """
    {
        "name": "Sun",
        "full_degree": 45.5,
        "normalized_degree": 15.5,
        "speed": 1.0,
        "is_retrograde": false,
        "sign_num": 2,
        "sign": "Taurus"
    }
    """
    let dto = try JSONDecoder().decode(PlanetDTO.self, from: json.data(using: .utf8)!)
    #expect(dto.name == "Sun")
    #expect(dto.fullDegree == 45.5)
}
```

### Mapper Tests

```swift
// Test DTO to domain mapping
func testMapPlanets() throws {
    let response = PlanetsResponse(/* mock data */)
    let planets = try FreeAstrologyDTOMapper.mapPlanets(response)
    #expect(planets.count > 0)
    #expect(planets.first?.name == "Sun")
}
```

### Integration Tests

```swift
// Test full chart generation
func testGenerateNatalChart() async throws {
    let birthDetails = BirthDetails(/* test data */)
    let chart = try await service.generateChart(birthDetails: birthDetails)
    #expect(chart.planets.count >= 10)
    #expect(chart.houses.count == 12)
    #expect(chart.aspects.count > 0)
}
```

---

## Summary

All data models are designed to:
1. ✅ Parse Free Astrology API JSON responses with Codable
2. ✅ Map cleanly to existing domain models without modifications
3. ✅ Support validation and error handling
4. ✅ Enable testability with clear contracts
5. ✅ Maintain separation between API layer and domain layer

Ready for contract definition and implementation in Phase 1.
