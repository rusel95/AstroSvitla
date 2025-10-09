# Data Model: Prokerala API Integration

**Feature**: Migrate to Prokerala Astrology API
**Date**: 2025-10-09
**Phase**: 1 - Data Model Design

## Overview

This document defines the data models for natal chart generation using Prokerala Astrology API, including API response DTOs, domain models, and cached entity structures.

## Model Layers

### 1. API Response DTOs (Data Transfer Objects)

Models that exactly match the Prokerala API JSON response structure.

### 2. Domain Models

Application business logic models used throughout the app.

### 3. Cached Entity Models

SwiftData `@Model` classes for local persistence.

---

## 1. API Response DTOs

### ProkralaChartDataResponse

Top-level response from `/western_chart_data` endpoint.

```swift
struct ProkralaChartDataResponse: Codable {
    let planets: [PlanetDTO]
    let houses: [HouseDTO]
    let aspects: [AspectDTO]
    let ascendant: AscendantDTO?
    let midheaven: MidheavenDTO?
}
```

### PlanetDTO

Individual planet data from API.

```swift
struct PlanetDTO: Codable {
    let name: String              // "Sun", "Moon", "Mercury", etc.
    let sign: String              // "Aries", "Taurus", etc.
    let full_degree: Double       // Absolute longitude 0-360
    let is_retro: String          // "true" or "false" (string!)

    enum CodingKeys: String, CodingKey {
        case name
        case sign
        case full_degree
        case is_retro
    }
}
```

**Validation Rules**:
- `name` must map to known planet (Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto)
- `sign` must map to zodiac sign (Aries...Pisces)
- `full_degree` range: 0.0 ≤ value < 360.0
- `is_retro` must be "true" or "false"

### HouseDTO

House cusp data from API.

```swift
struct HouseDTO: Codable {
    let house_id: Int             // 1-12
    let sign: String              // Zodiac sign on cusp
    let start_degree: Double      // Cusp degree
    let end_degree: Double        // Next cusp degree
    let planets: [String]?        // Planet names in this house

    enum CodingKeys: String, CodingKey {
        case house_id
        case sign
        case start_degree
        case end_degree
        case planets
    }
}
```

**Validation Rules**:
- `house_id` range: 1-12
- `sign` must map to zodiac sign
- `start_degree` range: 0.0 ≤ value < 360.0
- `end_degree` range: 0.0 ≤ value < 360.0

### AspectDTO

Planetary aspect data from API.

```swift
struct AspectDTO: Codable {
    let aspecting_planet: String  // First planet name
    let aspected_planet: String   // Second planet name
    let type: String              // "Conjunction", "Sextile", "Square", "Trine", "Opposition", "Quincunx"
    let orb: Double               // Deviation from exact aspect (degrees)
    let diff: Double              // Angular difference between planets

    enum CodingKeys: String, CodingKey {
        case aspecting_planet
        case aspected_planet
        case type
        case orb
        case diff
    }
}
```

**Validation Rules**:
- Planet names must map to known planets
- `type` must map to known aspect type
- `orb` range: 0.0 ≤ value ≤ 10.0 (typical max orb)
- `diff` range: 0.0 ≤ value ≤ 180.0

### AscendantDTO / MidheavenDTO

```swift
struct AscendantDTO: Codable {
    let sign: String
    let full_degree: Double
}

struct MidheavenDTO: Codable {
    let sign: String
    let full_degree: Double
}
```

### ProkralaChartImageResponse

Response from `/natal_wheel_chart` endpoint.

```swift
struct ProkralaChartImageResponse: Codable {
    let status: Bool
    let chart_url: String
    let msg: String
}
```

**Validation Rules**:
- `status` must be `true` for success
- `chart_url` must be valid URL (S3 bucket path)
- Parse `msg` for error details if `status` is `false`

---

## 2. Domain Models

### BirthData

User input for natal chart calculation.

```swift
struct BirthData: Codable, Hashable {
    let name: String?             // Person's name (optional)
    let birthDate: Date           // Date only (year, month, day)
    let birthTime: Date           // Time only (hour, minute)
    let location: Location
    let timezone: TimeZone

    var uniqueID: String {
        // Generate hash from birth data for cache lookup
        "\(birthDate.timeIntervalSince1970)_\(birthTime.timeIntervalSince1970)_\(location.latitude)_\(location.longitude)"
    }
}

struct Location: Codable, Hashable {
    let city: String
    let country: String
    let latitude: Double
    let longitude: Double

    init(city: String, country: String, latitude: Double, longitude: Double) {
        self.city = city
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
    }
}
```

**Validation Rules**:
- `birthDate`: Must be in the past (not future date)
- `birthTime`: Valid 24-hour time (0-23 hours, 0-59 minutes)
- `location.latitude`: -90.0 ≤ value ≤ 90.0
- `location.longitude`: -180.0 ≤ value ≤ 180.0
- `timezone`: Valid IANA timezone identifier

**State Transitions**: Immutable value type (no state transitions)

### Planet

Planetary position in natal chart.

```swift
struct Planet: Codable, Hashable, Identifiable {
    let id: UUID = UUID()
    let name: PlanetType
    let sign: ZodiacSign
    let longitude: Double         // Absolute degree 0-360
    let degreeInSign: Double      // 0-30 within current sign
    let house: Int                // House number (1-12)
    let isRetrograde: Bool
    let speed: Double?            // Optional: degrees per day

    init(name: PlanetType, sign: ZodiacSign, longitude: Double, house: Int, isRetrograde: Bool, speed: Double? = nil) {
        self.name = name
        self.sign = sign
        self.longitude = longitude
        self.degreeInSign = longitude.truncatingRemainder(dividingBy: 30)
        self.house = house
        self.isRetrograde = isRetrograde
        self.speed = speed
    }
}

enum PlanetType: String, Codable, CaseIterable {
    case sun = "Sun"
    case moon = "Moon"
    case mercury = "Mercury"
    case venus = "Venus"
    case mars = "Mars"
    case jupiter = "Jupiter"
    case saturn = "Saturn"
    case uranus = "Uranus"
    case neptune = "Neptune"
    case pluto = "Pluto"
}

enum ZodiacSign: String, Codable, CaseIterable {
    case aries = "Aries"
    case taurus = "Taurus"
    case gemini = "Gemini"
    case cancer = "Cancer"
    case leo = "Leo"
    case virgo = "Virgo"
    case libra = "Libra"
    case scorpio = "Scorpio"
    case sagittarius = "Sagittarius"
    case capricorn = "Capricorn"
    case aquarius = "Aquarius"
    case pisces = "Pisces"

    var element: Element {
        switch self {
        case .aries, .leo, .sagittarius: return .fire
        case .taurus, .virgo, .capricorn: return .earth
        case .gemini, .libra, .aquarius: return .air
        case .cancer, .scorpio, .pisces: return .water
        }
    }

    enum Element: String {
        case fire, earth, air, water
    }
}
```

**Validation Rules**:
- `longitude`: 0.0 ≤ value < 360.0
- `house`: 1 ≤ value ≤ 12
- `degreeInSign`: Computed as `longitude % 30`, range 0.0-30.0

**Relationships**:
- Planet belongs to one `NatalChart`
- Planet occupies one zodiac sign
- Planet resides in one house

### House

Astrological house cusp.

```swift
struct House: Codable, Hashable, Identifiable {
    let id: UUID = UUID()
    let number: Int               // 1-12
    let sign: ZodiacSign
    let cusp: Double              // Degree where house begins

    init(number: Int, sign: ZodiacSign, cusp: Double) {
        self.number = number
        self.sign = sign
        self.cusp = cusp
    }
}
```

**Validation Rules**:
- `number`: 1 ≤ value ≤ 12
- `cusp`: 0.0 ≤ value < 360.0

**Relationships**:
- House belongs to one `NatalChart`
- House has one zodiac sign on cusp
- House contains zero or more planets

### Aspect

Angular relationship between two planets.

```swift
struct Aspect: Codable, Hashable, Identifiable {
    let id: UUID = UUID()
    let planet1: PlanetType
    let planet2: PlanetType
    let type: AspectType
    let orb: Double               // Deviation from exact aspect
    let angle: Double             // Actual angular separation
    let isApplying: Bool          // Aspect getting tighter or separating

    init(planet1: PlanetType, planet2: PlanetType, type: AspectType, orb: Double, angle: Double, isApplying: Bool) {
        self.planet1 = planet1
        self.planet2 = planet2
        self.type = type
        self.orb = orb
        self.angle = angle
        self.isApplying = isApplying
    }
}

enum AspectType: String, Codable, CaseIterable {
    case conjunction = "Conjunction"  // 0°
    case sextile = "Sextile"          // 60°
    case square = "Square"            // 90°
    case trine = "Trine"              // 120°
    case opposition = "Opposition"    // 180°
    case quincunx = "Quincunx"        // 150°

    var angle: Double {
        switch self {
        case .conjunction: return 0
        case .sextile: return 60
        case .square: return 90
        case .trine: return 120
        case .opposition: return 180
        case .quincunx: return 150
        }
    }

    var maxOrb: Double {
        switch self {
        case .conjunction, .opposition: return 10.0
        case .square, .trine: return 8.0
        case .sextile, .quincunx: return 6.0
        }
    }
}
```

**Validation Rules**:
- `orb`: 0.0 ≤ value ≤ `type.maxOrb`
- `angle`: 0.0 ≤ value ≤ 180.0
- `planet1` != `planet2`

**Relationships**:
- Aspect involves exactly two planets
- Aspect belongs to one `NatalChart`

### NatalChart

Complete natal chart aggregate.

```swift
struct NatalChart: Codable, Identifiable {
    let id: UUID
    let birthData: BirthData
    let planets: [Planet]
    let houses: [House]
    let aspects: [Aspect]
    let ascendant: Double         // Rising sign degree
    let midheaven: Double         // MC degree
    let houseSystem: HouseSystem
    let generatedAt: Date

    init(id: UUID = UUID(), birthData: BirthData, planets: [Planet], houses: [House], aspects: [Aspect], ascendant: Double, midheaven: Double, houseSystem: HouseSystem = .placidus, generatedAt: Date = Date()) {
        self.id = id
        self.birthData = birthData
        self.planets = planets
        self.houses = houses
        self.aspects = aspects
        self.ascendant = ascendant
        self.midheaven = midheaven
        self.houseSystem = houseSystem
        self.generatedAt = generatedAt
    }
}

enum HouseSystem: String, Codable {
    case placidus = "placidus"
    case koch = "koch"
    case equalHouse = "equal_house"
    case wholeSign = "whole_sign"
}
```

**Validation Rules**:
- `planets.count` == 10 (Sun through Pluto)
- `houses.count` == 12
- `aspects.count` >= 0 (varies by orb settings)
- `ascendant`: 0.0 ≤ value < 360.0
- `midheaven`: 0.0 ≤ value < 360.0

**Relationships**:
- NatalChart has many planets (exactly 10)
- NatalChart has many houses (exactly 12)
- NatalChart has many aspects (variable)
- NatalChart has one birth data set

### ChartVisualization

Metadata for cached chart wheel image.

```swift
struct ChartVisualization: Codable, Identifiable {
    let id: UUID
    let chartID: UUID             // References NatalChart.id
    let imageFormat: ImageFormat
    let imageURL: URL?            // S3 URL from API response
    let localFileID: String?      // Filename in local cache
    let size: Int                 // Image dimensions (pixels)
    let generatedAt: Date

    enum ImageFormat: String, Codable {
        case svg
        case png
    }
}
```

**Validation Rules**:
- `chartID` must reference existing `NatalChart`
- Either `imageURL` or `localFileID` must be non-nil
- `size`: 300 ≤ value ≤ 1200 (reasonable image dimensions)

**Relationships**:
- ChartVisualization belongs to one `NatalChart`
- ChartVisualization may have local cached file

---

## 3. Cached Entity Models (SwiftData)

### CachedNatalChart

SwiftData model for persisting natal charts locally.

```swift
import SwiftData
import Foundation

@Model
final class CachedNatalChart {
    @Attribute(.unique) var id: UUID
    var birthDataJSON: Data       // Encoded BirthData
    var planetsJSON: Data         // Encoded [Planet]
    var housesJSON: Data          // Encoded [House]
    var aspectsJSON: Data         // Encoded [Aspect]
    var ascendant: Double
    var midheaven: Double
    var houseSystem: String       // HouseSystem.rawValue
    var generatedAt: Date
    var imageFileID: String?      // Filename for cached image
    var imageFormat: String?      // "svg" or "png"

    init(id: UUID, birthData: BirthData, planets: [Planet], houses: [House], aspects: [Aspect], ascendant: Double, midheaven: Double, houseSystem: HouseSystem, generatedAt: Date, imageFileID: String? = nil, imageFormat: String? = nil) throws {
        self.id = id
        self.birthDataJSON = try JSONEncoder().encode(birthData)
        self.planetsJSON = try JSONEncoder().encode(planets)
        self.housesJSON = try JSONEncoder().encode(houses)
        self.aspectsJSON = try JSONEncoder().encode(aspects)
        self.ascendant = ascendant
        self.midheaven = midheaven
        self.houseSystem = houseSystem.rawValue
        self.generatedAt = generatedAt
        self.imageFileID = imageFileID
        self.imageFormat = imageFormat
    }

    // Decode methods
    func decodeBirthData() throws -> BirthData {
        try JSONDecoder().decode(BirthData.self, from: birthDataJSON)
    }

    func decodePlanets() throws -> [Planet] {
        try JSONDecoder().decode([Planet].self, from: planetsJSON)
    }

    func decodeHouses() throws -> [House] {
        try JSONDecoder().decode([House].self, from: housesJSON)
    }

    func decodeAspects() throws -> [Aspect] {
        try JSONDecoder().decode([Aspect].self, from: aspectsJSON)
    }

    func toNatalChart() throws -> NatalChart {
        NatalChart(
            id: id,
            birthData: try decodeBirthData(),
            planets: try decodePlanets(),
            houses: try decodeHouses(),
            aspects: try decodeAspects(),
            ascendant: ascendant,
            midheaven: midheaven,
            houseSystem: HouseSystem(rawValue: houseSystem) ?? .placidus,
            generatedAt: generatedAt
        )
    }
}
```

**Rationale for JSON Encoding**:
- SwiftData has limited support for complex nested arrays
- JSON encoding ensures reliable serialization
- Easy to migrate if SwiftData support improves
- Backward compatible with existing chart data

**Indexes**:
- `@Attribute(.unique)` on `id` for fast lookup
- Consider index on `generatedAt` for cache expiration queries

**Cache Invalidation**:
- Charts older than 30 days flagged as stale
- LRU eviction if cache exceeds storage limit

---

## Data Transformation Mappers

### DTOMapper

Transforms API DTOs to domain models.

```swift
enum DTOMapper {

    // MARK: - Planet Mapping

    static func toDomain(planetDTO: PlanetDTO, house: Int) throws -> Planet {
        guard let planetType = PlanetType(rawValue: planetDTO.name) else {
            throw MappingError.invalidPlanetName(planetDTO.name)
        }

        guard let zodiacSign = ZodiacSign(rawValue: planetDTO.sign) else {
            throw MappingError.invalidSign(planetDTO.sign)
        }

        let isRetrograde = (planetDTO.is_retro.lowercased() == "true")

        return Planet(
            name: planetType,
            sign: zodiacSign,
            longitude: planetDTO.full_degree,
            house: house,
            isRetrograde: isRetrograde
        )
    }

    // MARK: - House Mapping

    static func toDomain(houseDTO: HouseDTO) throws -> House {
        guard (1...12).contains(houseDTO.house_id) else {
            throw MappingError.invalidHouseNumber(houseDTO.house_id)
        }

        guard let zodiacSign = ZodiacSign(rawValue: houseDTO.sign) else {
            throw MappingError.invalidSign(houseDTO.sign)
        }

        return House(
            number: houseDTO.house_id,
            sign: zodiacSign,
            cusp: houseDTO.start_degree
        )
    }

    // MARK: - Aspect Mapping

    static func toDomain(aspectDTO: AspectDTO) throws -> Aspect {
        guard let planet1 = PlanetType(rawValue: aspectDTO.aspecting_planet) else {
            throw MappingError.invalidPlanetName(aspectDTO.aspecting_planet)
        }

        guard let planet2 = PlanetType(rawValue: aspectDTO.aspected_planet) else {
            throw MappingError.invalidPlanetName(aspectDTO.aspected_planet)
        }

        guard let aspectType = AspectType(rawValue: aspectDTO.type) else {
            throw MappingError.invalidAspectType(aspectDTO.type)
        }

        return Aspect(
            planet1: planet1,
            planet2: planet2,
            type: aspectType,
            orb: aspectDTO.orb,
            angle: aspectDTO.diff,
            isApplying: false  // API doesn't provide this; could calculate
        )
    }

    // MARK: - Full Chart Mapping

    static func toDomain(response: ProkralaChartDataResponse, birthData: BirthData) throws -> NatalChart {
        // First, create house-to-planet mapping
        var housePlanetMap: [String: Int] = [:]
        for houseDTO in response.houses {
            for planetName in (houseDTO.planets ?? []) {
                housePlanetMap[planetName] = houseDTO.house_id
            }
        }

        // Map planets with house assignments
        let planets = try response.planets.map { planetDTO in
            let house = housePlanetMap[planetDTO.name] ?? 1
            return try toDomain(planetDTO: planetDTO, house: house)
        }

        // Map houses
        let houses = try response.houses.map { try toDomain(houseDTO: $0) }

        // Map aspects
        let aspects = try response.aspects.map { try toDomain(aspectDTO: $0) }

        // Extract ascendant and midheaven
        let ascendant = response.ascendant?.full_degree ?? houses[0].cusp
        let midheaven = response.midheaven?.full_degree ?? houses[9].cusp

        return NatalChart(
            birthData: birthData,
            planets: planets,
            houses: houses,
            aspects: aspects,
            ascendant: ascendant,
            midheaven: midheaven,
            houseSystem: .placidus
        )
    }
}

enum MappingError: LocalizedError {
    case invalidPlanetName(String)
    case invalidSign(String)
    case invalidHouseNumber(Int)
    case invalidAspectType(String)

    var errorDescription: String? {
        switch self {
        case .invalidPlanetName(let name):
            return "Unknown planet name: \(name)"
        case .invalidSign(let sign):
            return "Unknown zodiac sign: \(sign)"
        case .invalidHouseNumber(let num):
            return "Invalid house number: \(num). Must be 1-12."
        case .invalidAspectType(let type):
            return "Unknown aspect type: \(type)"
        }
    }
}
```

---

## Validation Summary

| Entity | Key Validations |
|--------|----------------|
| **BirthData** | Date in past, valid time, lat/lon ranges, valid timezone |
| **Planet** | Longitude 0-360, house 1-12, known planet/sign enum |
| **House** | Number 1-12, cusp 0-360, known zodiac sign |
| **Aspect** | Orb ≤ maxOrb, angle ≤ 180, different planets |
| **NatalChart** | 10 planets, 12 houses, ascendant/MC 0-360 |
| **CachedNatalChart** | Valid JSON encoding, unique ID |
| **DTOs** | String-to-enum mapping, range checks, null handling |

---

## Relationships Diagram

```
BirthData (1) ─────> (1) NatalChart
                           │
                           ├─> (10) Planet
                           │
                           ├─> (12) House
                           │
                           ├─> (*) Aspect
                           │
                           └─> (0..1) ChartVisualization

NatalChart (1) ────> (1) CachedNatalChart (SwiftData)
                           │
                           └─> (0..1) Image File (FileManager)
```

---

## SwiftData Schema

```swift
// Register in ModelContainer
let schema = Schema([
    CachedNatalChart.self
])

let modelConfiguration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false
)

let container = try ModelContainer(
    for: schema,
    configurations: [modelConfiguration]
)
```

---

## Next Steps

- ✅ Data models defined
- ⏭️ Generate API contract examples (contracts/)
- ⏭️ Generate quickstart guide (quickstart.md)
- ⏭️ Update agent context file
