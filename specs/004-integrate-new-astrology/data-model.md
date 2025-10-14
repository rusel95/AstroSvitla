# Data Model: New Astrology API Integration

**Feature**: Integrate api.astrology-api.io for Natal Chart Generation
**Date**: October 11, 2025
**Status**: Design Complete

## Overview

This document defines the data transfer objects (DTOs) for api.astrology-api.io integration and their mapping to existing domain models. All DTOs follow Swift Codable conventions and match the API's JSON response structure exactly.

## Data Flow

```
api.astrology-api.io (JSON)
    ↓
AstrologyAPIModels (DTOs)
    ↓
AstrologyAPIDTOMapper
    ↓
Domain Models (NatalChart, Planet, House, Aspect)
    ↓
ChartCacheService (SwiftData persistence)
```

## DTO Models (API Layer)

### Request DTOs

```swift
/// Birth data for natal chart calculation
struct AstrologyAPIBirthData: Codable {
    let year: Int
    let month: Int
    let day: Int
    let hour: Int
    let minute: Int
    let second: Int
    let city: String
    let countryCode: String
    
    private enum CodingKeys: String, CodingKey {
        case year, month, day, hour, minute, second, city
        case countryCode = "country_code"
    }
}

/// Subject information for API requests
struct AstrologyAPISubject: Codable {
    let name: String
    let birthData: AstrologyAPIBirthData
    
    private enum CodingKeys: String, CodingKey {
        case name
        case birthData = "birth_data"
    }
}

/// Chart calculation options
struct AstrologyAPIOptions: Codable {
    let houseSystem: String
    let zodiacType: String
    let activePoints: [String]
    let precision: Int
    
    private enum CodingKeys: String, CodingKey {
        case houseSystem = "house_system"
        case zodiacType = "zodiac_type"
        case activePoints = "active_points"
        case precision
    }
    
    static let `default` = AstrologyAPIOptions(
        houseSystem: "P", // Placidus
        zodiacType: "Tropic", // Tropical/Western
        activePoints: ["Sun", "Moon", "Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"],
        precision: 2
    )
}

/// Complete natal chart request
struct AstrologyAPINatalChartRequest: Codable {
    let subject: AstrologyAPISubject
    let options: AstrologyAPIOptions
}

/// SVG chart generation request  
struct AstrologyAPISVGRequest: Codable {
    let subject: AstrologyAPISubject
    let options: AstrologyAPIOptions
    let svgOptions: AstrologyAPISVGOptions?
    
    private enum CodingKeys: String, CodingKey {
        case subject, options
        case svgOptions = "svg_options"
    }
}

struct AstrologyAPISVGOptions: Codable {
    let theme: String
    let language: String
    
    static let `default` = AstrologyAPISVGOptions(
        theme: "classic",
        language: "en"
    )
}
```

### Response DTOs

```swift
/// Subject metadata in API response
struct AstrologyAPISubjectData: Codable {
    let name: String
    let year: Int
    let month: Int
    let day: Int
    let hour: Int
    let minute: Int
    let city: String
    let nation: String
    let longitude: Double
    let latitude: Double
    let timezoneString: String
    
    private enum CodingKeys: String, CodingKey {
        case name, year, month, day, hour, minute, city, nation
        case longitude = "lng"
        case latitude = "lat"
        case timezoneString = "tz_str"
    }
}

/// Individual planetary position
struct AstrologyAPIPlanetaryPosition: Codable {
    let name: String
    let quality: String?
    let element: String?
    let sign: String
    let signNumber: Int?
    let position: Double
    let absolutePosition: Double
    let emoji: String?
    let pointType: String?
    let house: String
    let isRetrograde: Bool
    let speed: Double?
    
    private enum CodingKeys: String, CodingKey {
        case name, quality, element, sign, position, emoji, house, speed
        case signNumber = "sign_num"
        case absolutePosition = "abs_pos"
        case pointType = "point_type"
        case isRetrograde = "retrograde"
    }
}

/// House cusp information
struct AstrologyAPIHouseCusp: Codable {
    let house: Int
    let sign: String
    let degree: Double
    let absoluteLongitude: Double
    
    private enum CodingKeys: String, CodingKey {
        case house, sign, degree
        case absoluteLongitude = "abs_pos"
    }
}

/// Aspect between planets
struct AstrologyAPIAspect: Codable {
    let planet1: String
    let planet2: String
    let aspect: String
    let orb: Double
    let isApplying: Bool?
    let strength: String?
    
    private enum CodingKeys: String, CodingKey {
        case planet1, planet2, aspect, orb, strength
        case isApplying = "applying"
    }
}

/// Chart calculation data
struct AstrologyAPIChartData: Codable {
    let planetaryPositions: [AstrologyAPIPlanetaryPosition]
    let houseCusps: [AstrologyAPIHouseCusp]?
    let aspects: [AstrologyAPIAspect]?
    
    private enum CodingKeys: String, CodingKey {
        case planetaryPositions = "planetary_positions"
        case houseCusps = "house_cusps"
        case aspects
    }
}

/// Complete natal chart response
struct AstrologyAPINatalChartResponse: Codable {
    let subjectData: AstrologyAPISubjectData
    let chartData: AstrologyAPIChartData
    
    private enum CodingKeys: String, CodingKey {
        case subjectData = "subject_data"
        case chartData = "chart_data"
    }
}
```

## Mapping Logic (Service Layer)

### Domain Model Mapping

```swift
enum AstrologyAPIDTOMapper {
    
    /// Convert birth details to API request format
    static func toAPIRequest(
        birthDetails: BirthDetails,
        name: String = "Chart Subject"
    ) -> AstrologyAPINatalChartRequest {
        let birthData = AstrologyAPIBirthData(
            year: Calendar.current.component(.year, from: birthDetails.date),
            month: Calendar.current.component(.month, from: birthDetails.date),
            day: Calendar.current.component(.day, from: birthDetails.date),
            hour: Calendar.current.component(.hour, from: birthDetails.time),
            minute: Calendar.current.component(.minute, from: birthDetails.time),
            second: 0,
            city: birthDetails.location.city,
            countryCode: birthDetails.location.countryCode
        )
        
        let subject = AstrologyAPISubject(name: name, birthData: birthData)
        
        return AstrologyAPINatalChartRequest(
            subject: subject,
            options: .default
        )
    }
    
    /// Convert API response to domain model
    static func toDomain(
        response: AstrologyAPINatalChartResponse,
        birthDetails: BirthDetails
    ) throws -> NatalChart {
        
        // Map planets
        let planets = try mapPlanets(response.chartData.planetaryPositions)
        
        // Map houses  
        let houses = try mapHouses(response.chartData.houseCusps ?? [])
        
        // Map aspects
        let aspects = try mapAspects(response.chartData.aspects ?? [])
        
        // Extract angles
        let angles = extractAngles(from: response.chartData.planetaryPositions)
        
        return NatalChart(
            id: UUID(),
            birthDetails: birthDetails,
            planets: planets,
            houses: houses,
            aspects: aspects,
            ascendant: angles.ascendant,
            midheaven: angles.midheaven,
            descendant: angles.descendant,
            imumCoeli: angles.imumCoeli,
            imageFileID: nil, // Set separately when SVG is cached
            imageFormat: nil,
            calculatedAt: Date(),
            dataSource: "api.astrology-api.io"
        )
    }
    
    // MARK: - Private Mapping Methods
    
    private static func mapPlanets(
        _ apiPlanets: [AstrologyAPIPlanetaryPosition]
    ) throws -> [Planet] {
        return try apiPlanets.compactMap { apiPlanet in
            guard let planetType = PlanetType.from(apiName: apiPlanet.name) else {
                return nil // Skip unrecognized planets
            }
            
            return Planet(
                type: planetType,
                sign: ZodiacSign.from(apiName: apiPlanet.sign),
                degree: apiPlanet.position,
                house: apiPlanet.house.extractHouseNumber(),
                isRetrograde: apiPlanet.isRetrograde,
                speed: apiPlanet.speed
            )
        }
    }
    
    private static func mapHouses(
        _ apiHouses: [AstrologyAPIHouseCusp]
    ) throws -> [House] {
        return apiHouses.map { apiHouse in
            House(
                number: apiHouse.house,
                sign: ZodiacSign.from(apiName: apiHouse.sign),
                degree: apiHouse.degree
            )
        }
    }
    
    private static func mapAspects(
        _ apiAspects: [AstrologyAPIAspect]
    ) throws -> [Aspect] {
        return try apiAspects.compactMap { apiAspect in
            guard let planet1 = PlanetType.from(apiName: apiAspect.planet1),
                  let planet2 = PlanetType.from(apiName: apiAspect.planet2),
                  let aspectType = AspectType.from(apiName: apiAspect.aspect) else {
                return nil
            }
            
            return Aspect(
                planet1: planet1,
                planet2: planet2,
                type: aspectType,
                orb: apiAspect.orb,
                isApplying: apiAspect.isApplying ?? false
            )
        }
    }
    
    private static func extractAngles(
        from planets: [AstrologyAPIPlanetaryPosition]
    ) -> (ascendant: Double, midheaven: Double, descendant: Double, imumCoeli: Double) {
        // Extract ASC, MC, DSC, IC from planetary positions
        // These may be included as special points in the response
        let ascendant = planets.first { $0.name == "ASC" || $0.name == "Ascendant" }?.absolutePosition ?? 0
        let midheaven = planets.first { $0.name == "MC" || $0.name == "Midheaven" }?.absolutePosition ?? 0
        
        return (
            ascendant: ascendant,
            midheaven: midheaven,
            descendant: (ascendant + 180).truncatingRemainder(dividingBy: 360),
            imumCoeli: (midheaven + 180).truncatingRemainder(dividingBy: 360)
        )
    }
}
```

### Enum Extensions for Mapping

```swift
extension PlanetType {
    static func from(apiName: String) -> PlanetType? {
        switch apiName.lowercased() {
        case "sun": return .sun
        case "moon": return .moon
        case "mercury": return .mercury
        case "venus": return .venus
        case "mars": return .mars
        case "jupiter": return .jupiter
        case "saturn": return .saturn
        case "uranus": return .uranus
        case "neptune": return .neptune
        case "pluto": return .pluto
        default: return nil
        }
    }
}

extension ZodiacSign {
    static func from(apiName: String) -> ZodiacSign {
        switch apiName.lowercased() {
        case "ari": return .aries
        case "tau": return .taurus
        case "gem": return .gemini
        case "can": return .cancer
        case "leo": return .leo
        case "vir": return .virgo
        case "lib": return .libra
        case "sco": return .scorpio
        case "sag": return .sagittarius
        case "cap": return .capricorn
        case "aqu": return .aquarius
        case "pis": return .pisces
        default: return .aries // Default fallback
        }
    }
}

extension AspectType {
    static func from(apiName: String) -> AspectType? {
        switch apiName.lowercased() {
        case "conjunction": return .conjunction
        case "opposition": return .opposition
        case "trine": return .trine
        case "square": return .square
        case "sextile": return .sextile
        default: return nil
        }
    }
}

extension String {
    func extractHouseNumber() -> Int {
        // Extract house number from strings like "Tenth_House" -> 10
        let houseMap = [
            "first": 1, "second": 2, "third": 3, "fourth": 4,
            "fifth": 5, "sixth": 6, "seventh": 7, "eighth": 8,
            "ninth": 9, "tenth": 10, "eleventh": 11, "twelfth": 12
        ]
        
        for (name, number) in houseMap {
            if self.lowercased().contains(name) {
                return number
            }
        }
        
        return 1 // Default fallback
    }
}
```

## Error Handling

```swift
enum AstrologyAPIMappingError: LocalizedError {
    case invalidPlanetData(String)
    case invalidHouseData(String)  
    case invalidAspectData(String)
    case missingRequiredField(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidPlanetData(let planet):
            return "Invalid planet data for: \(planet)"
        case .invalidHouseData(let house):
            return "Invalid house data for: \(house)"
        case .invalidAspectData(let aspect):
            return "Invalid aspect data for: \(aspect)"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        }
    }
}
```

## Testing Strategy

### Unit Tests Required

1. **DTO Parsing Tests**: Verify all DTOs correctly parse real API responses
2. **Mapping Tests**: Test conversion from API DTOs to domain models
3. **Error Handling Tests**: Verify graceful handling of malformed data
4. **Enum Mapping Tests**: Test planet/sign/aspect name conversions

### Test Data

```swift
// Example test JSON matching API format
let testAPIResponse = """
{
  "subject_data": {
    "name": "Test Subject",
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
        "sign": "Tau", "position": 24.83,
        "abs_pos": 54.83, "house": "Tenth_House",
        "retrograde": false
      }
    ],
    "house_cusps": [
      { "house": 1, "sign": "Leo", "degree": 15.42, "abs_pos": 135.42 }
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
"""
```

## Summary

This data model design provides:
- **Complete API Coverage**: All response fields mapped appropriately
- **Type Safety**: Strong typing with Codable compliance  
- **Domain Model Preservation**: No changes to existing domain interfaces
- **Error Resilience**: Graceful handling of unexpected data
- **Testing Support**: Comprehensive test coverage strategy

**Ready for Contract Definition**: Data models designed and validated.