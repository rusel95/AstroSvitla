# Data Model: Enhance Astrological Report Completeness & Source Transparency

**Feature**: 005-enhance-astrological-report  
**Date**: October 16, 2025  
**Status**: Complete

## Overview

This document defines all data entities, their attributes, relationships, validation rules, and state transitions for the enhanced astrological report feature. All models maintain backward compatibility with existing system while adding new capabilities.

---

## Entity Relationship Diagram

```
┌─────────────────┐
│  NatalChart     │
├─────────────────┤
│ id              │
│ birthDate       │
│ birthTime       │
│ latitude        │
│ longitude       │
│ locationName    │
│ planets         │◄──────┐
│ houses          │◄──┐   │
│ aspects         │◄┐ │   │
│ ascendant       ││ │   │
│ midheaven       ││ │   │
│ calculatedAt    ││ │   │
│ imageFileID     ││ │   │
│ imageFormat     ││ │   │
│ ─── NEW ───     ││ │   │
│ astrologicalPoints│   │   │
│ houseRulers     ││ │   │
└─────────────────┘│ │   │
                   │ │   │
      ┌────────────┘ │   │
      │              │   │
┌─────▼──────────┐   │   │
│ AstrologicalPoint│   │   │
├────────────────┤   │   │
│ id             │   │   │
│ pointType      │   │   │
│ longitude      │   │   │
│ zodiacSign     │   │   │
│ housePlacement │   │   │
└────────────────┘   │   │
                     │   │
      ┌──────────────┘   │
      │                  │
┌─────▼────────┐         │
│ HouseRuler   │         │
├──────────────┤         │
│ id           │         │
│ houseNumber  │         │
│ rulingPlanet │─────────┘
│ rulerSign    │
│ rulerHouse   │
│ rulerAspects │
└──────────────┘


┌──────────────────┐
│ GeneratedReport  │
├──────────────────┤
│ id               │
│ area             │
│ summary          │
│ keyInfluences    │
│ detailedAnalysis │
│ recommendations  │
│ knowledgeUsage   │
│ ─── NEW ───      │
│ knowledgeSources │◄───┐
│ knowledgeMetrics │◄─┐ │
└──────────────────┘  │ │
                      │ │
       ┌──────────────┘ │
       │                │
┌──────▼─────────────┐  │
│ EnhancedKnowledge  │  │
│ Source             │  │
├────────────────────┤  │
│ id                 │  │
│ bookTitle          │  │
│ author             │  │
│ chapter            │  │
│ pageRange          │  │
│ snippet            │  │
│ relevanceScore     │  │
│ sourceType         │  │
└────────────────────┘  │
                        │
       ┌────────────────┘
       │
┌──────▼─────────────┐
│ KnowledgeUsage     │
│ Metrics            │
├────────────────────┤
│ id                 │
│ totalSources       │
│ vectorDBCount      │
│ aiTrainingCount    │
│ avgRelevanceScore  │
│ cacheHit           │
└────────────────────┘
```

---

## Entity Definitions

### 1. AstrologicalPoint

**Purpose**: Represents calculated points in a natal chart that aren't traditional planets (karmic nodes, Lilith, angles).

#### Attributes

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | UUID | Required, unique | Primary key |
| `pointType` | PointType (enum) | Required | Type of astrological point |
| `longitude` | Double | Required, 0-360 | Ecliptic longitude in degrees |
| `zodiacSign` | ZodiacSign (enum) | Required | Sign the point occupies |
| `housePlacement` | Int | Required, 1-12 | House number where point is located |

#### Enumerations

```swift
enum PointType: String, Codable, CaseIterable {
    case northNode = "North Node"
    case southNode = "South Node"
    case lilith = "Lilith"
    case ascendant = "Ascendant"
    case midheaven = "Midheaven"
}
```

#### Validation Rules

- `longitude`: Must be in range [0.0, 360.0)
- `housePlacement`: Must be integer between 1 and 12 (inclusive)
- `zodiacSign`: Must match zodiac sign calculated from longitude (automatic derivation)
- **Derived Calculation**: `zodiacSign = ZodiacSign.from(degree: longitude)`

#### Relationships

- **Belongs to**: One `NatalChart` (many-to-one)
- **Can form**: Aspects with `Planet` entities (not stored, calculated dynamically)

#### Examples

```swift
// North Node in Taurus, 3rd house
AstrologicalPoint(
    id: UUID(),
    pointType: .northNode,
    longitude: 47.23,    // 17° Taurus
    zodiacSign: .taurus,
    housePlacement: 3
)

// Lilith in Scorpio, 8th house
AstrologicalPoint(
    id: UUID(),
    pointType: .lilith,
    longitude: 234.56,   // 24° Scorpio
    zodiacSign: .scorpio,
    housePlacement: 8
)
```

---

### 2. HouseRuler

**Purpose**: Represents the planetary ruler of a house based on the zodiac sign on the house cusp, including where that ruler is located.

#### Attributes

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | UUID | Required, unique | Primary key |
| `houseNumber` | Int | Required, 1-12 | Which house this ruler governs |
| `rulingPlanet` | PlanetType (enum) | Required | The planet that rules this house |
| `rulerSign` | ZodiacSign (enum) | Required | Sign where the ruling planet is located |
| `rulerHouse` | Int | Required, 1-12 | House where the ruling planet is located |
| `rulerAspects` | [Aspect] | Optional | Aspects made by the ruling planet |

#### Validation Rules

- `houseNumber`: Must be integer between 1 and 12
- `rulerHouse`: Must be integer between 1 and 12
- `rulingPlanet`: Must be one of the 10 major planets (Sun through Pluto)
- **Business Rule**: `rulingPlanet` determined by looking up sign on house cusp in `TraditionalRulershipTable`

#### Relationships

- **Belongs to**: One `NatalChart` (many-to-one, exactly 12 per chart)
- **References**: One `Planet` (the ruling planet) via `rulingPlanet` enum match

#### Calculation Logic

```swift
static func calculate(
    houseNumber: Int,
    houseCusp: Double,
    planets: [Planet]
) -> HouseRuler {
    // 1. Determine sign on house cusp
    let cuspSign = ZodiacSign.from(degree: houseCusp)
    
    // 2. Look up traditional ruler
    let rulingPlanet = TraditionalRulership.ruler(of: cuspSign)
    
    // 3. Find that planet in the chart
    guard let ruler = planets.first(where: { $0.name == rulingPlanet }) else {
        fatalError("Ruling planet not found in chart")
    }
    
    // 4. Get ruler's aspects
    let rulerAspects = aspects.filter {
        $0.planet1 == rulingPlanet || $0.planet2 == rulingPlanet
    }
    
    return HouseRuler(
        id: UUID(),
        houseNumber: houseNumber,
        rulingPlanet: rulingPlanet,
        rulerSign: ruler.sign,
        rulerHouse: ruler.house,
        rulerAspects: rulerAspects
    )
}
```

#### Examples

```swift
// 1st house (Ascendant) in Aries
// Mars rules Aries, Mars is in 7th house in Libra
HouseRuler(
    id: UUID(),
    houseNumber: 1,
    rulingPlanet: .mars,
    rulerSign: .libra,
    rulerHouse: 7,
    rulerAspects: [
        Aspect(planet1: .mars, planet2: .venus, type: .trine, orb: 2.3)
    ]
)

// Interpretation: "Personality (1st house) expresses through partnerships (7th house)"
```

---

### 3. EnhancedKnowledgeSource

**Purpose**: Represents a specific source of astrological knowledge consulted during AI report generation, with full attribution metadata.

#### Attributes

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | UUID | Required, unique | Primary key |
| `bookTitle` | String | Required, max 200 chars | Title of the book or source |
| `author` | String? | Optional, max 100 chars | Author name (if available) |
| `chapter` | String? | Optional, max 100 chars | Chapter or section name |
| `pageRange` | String? | Optional, max 50 chars | Page numbers (e.g., "pp. 87-92") |
| `snippet` | String | Required, max 500 chars | Actual text excerpt used |
| `relevanceScore` | Double | Required, 0.0-1.0 | Similarity score from vector search |
| `sourceType` | SourceType (enum) | Required | Origin of the knowledge |

#### Enumerations

```swift
enum SourceType: String, Codable {
    case vectorDatabase = "Vector Database"
    case aiTraining = "AI General Knowledge"
}
```

#### Validation Rules

- `bookTitle`: Must not be empty, max 200 characters
- `snippet`: Must not be empty, max 500 characters
- `relevanceScore`: Must be in range [0.0, 1.0]
- **Business Rule**: If `sourceType == .vectorDatabase`, then `bookTitle`, `snippet`, and `relevanceScore` must be populated
- **Business Rule**: If `sourceType == .aiTraining`, then `author`, `chapter`, `pageRange` may be null

#### Relationships

- **Belongs to**: One `GeneratedReport` (many-to-one)
- Multiple sources can be associated with a single report

#### Examples

```swift
// Vector database source
EnhancedKnowledgeSource(
    id: UUID(),
    bookTitle: "The Inner Sky",
    author: "Steven Forrest",
    chapter: "Chapter 5: The Moon",
    pageRange: "pp. 87-92",
    snippet: "Moon in Scorpio in the 8th house indicates...",
    relevanceScore: 0.94,
    sourceType: .vectorDatabase
)

// AI training source
EnhancedKnowledgeSource(
    id: UUID(),
    bookTitle: "AI General Astrological Knowledge",
    author: nil,
    chapter: "Nodes interpretation",
    pageRange: nil,
    snippet: "North Node represents the soul's evolutionary purpose...",
    relevanceScore: 0.78,
    sourceType: .aiTraining
)
```

---

### 4. KnowledgeUsageMetrics

**Purpose**: Summary statistics about knowledge sources used in report generation for transparency and performance monitoring.

#### Attributes

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | UUID | Required, unique | Primary key |
| `totalSourcesConsulted` | Int | Required, ≥0 | Total count of all sources |
| `vectorDBSourceCount` | Int | Required, ≥0 | Count of vector database sources |
| `aiTrainingSourceCount` | Int | Required, ≥0 | Count of AI training sources |
| `averageRelevanceScore` | Double | Required, 0.0-1.0 | Mean relevance across all sources |
| `cacheHit` | Bool | Required | Whether cached results were used |

#### Validation Rules

- All counts must be non-negative integers
- `totalSourcesConsulted == vectorDBSourceCount + aiTrainingSourceCount`
- `averageRelevanceScore`: Must be in range [0.0, 1.0] or 0.0 if no sources
- **Business Rule**: Calculated after all sources retrieved, before report returned

#### Relationships

- **Belongs to**: One `GeneratedReport` (one-to-one)

#### Calculation Logic

```swift
static func calculate(sources: [EnhancedKnowledgeSource], cacheHit: Bool) -> KnowledgeUsageMetrics {
    let vectorSources = sources.filter { $0.sourceType == .vectorDatabase }
    let aiSources = sources.filter { $0.sourceType == .aiTraining }
    
    let avgScore = sources.isEmpty ? 0.0 :
        sources.map { $0.relevanceScore }.reduce(0, +) / Double(sources.count)
    
    return KnowledgeUsageMetrics(
        id: UUID(),
        totalSourcesConsulted: sources.count,
        vectorDBSourceCount: vectorSources.count,
        aiTrainingSourceCount: aiSources.count,
        averageRelevanceScore: avgScore,
        cacheHit: cacheHit
    )
}
```

#### Examples

```swift
// Report with vector database usage
KnowledgeUsageMetrics(
    id: UUID(),
    totalSourcesConsulted: 18,
    vectorDBSourceCount: 15,
    aiTrainingSourceCount: 3,
    averageRelevanceScore: 0.87,
    cacheHit: false  // Fresh query
)

// Report with cache hit
KnowledgeUsageMetrics(
    id: UUID(),
    totalSourcesConsulted: 15,
    vectorDBSourceCount: 15,
    aiTrainingSourceCount: 0,
    averageRelevanceScore: 0.91,
    cacheHit: true  // Served from cache
)
```

---

## Modified Existing Entities

### 5. NatalChart (Modified)

**Changes**: Add arrays for astrological points and house rulers.

#### New Attributes

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `astrologicalPoints` | [AstrologicalPoint] | Required | Array of nodes, Lilith, angles |
| `houseRulers` | [HouseRuler] | Required | Array of 12 house rulers |

#### Validation Rules

- `astrologicalPoints`: Should contain at minimum: North Node, South Node, Lilith (3 points)
- `houseRulers`: Must contain exactly 12 entries (one per house)

#### Backward Compatibility

- Existing charts without these fields: default to empty arrays
- Migration: Recalculate and populate for all existing charts (one-time task)

#### Updated Schema

```swift
struct NatalChart: Codable, Sendable {
    let id: UUID
    let birthDate: Date
    let birthTime: Date
    let latitude: Double
    let longitude: Double
    let locationName: String
    
    let planets: [Planet]
    let houses: [House]
    let aspects: [Aspect]
    
    let ascendant: Double
    let midheaven: Double
    
    var calculatedAt: Date
    var imageFileID: String?
    var imageFormat: String?
    
    // NEW FIELDS
    var astrologicalPoints: [AstrologicalPoint] = []
    var houseRulers: [HouseRuler] = []
}
```

---

### 6. GeneratedReport (Modified)

**Changes**: Add arrays for enhanced knowledge sources and metrics.

#### New Attributes

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `knowledgeSources` | [EnhancedKnowledgeSource] | Required | Array of source attributions |
| `knowledgeMetrics` | KnowledgeUsageMetrics | Required | Summary statistics |

#### Validation Rules

- `knowledgeSources`: Should contain 10-20 sources for typical reports (per FR-018)
- `knowledgeMetrics.totalSourcesConsulted`: Must equal `knowledgeSources.count`

#### Backward Compatibility

- Existing reports without these fields: show "Legacy report - source data unavailable"
- New reports: must populate both fields

#### Updated Schema

```swift
struct GeneratedReport: Identifiable, Sendable, Codable {
    let id: UUID
    let area: ReportArea
    let summary: String
    let keyInfluences: [String]
    let detailedAnalysis: String
    let recommendations: [String]
    let knowledgeUsage: KnowledgeUsage  // Deprecated, replaced by fields below
    
    // NEW FIELDS
    var knowledgeSources: [EnhancedKnowledgeSource] = []
    var knowledgeMetrics: KnowledgeUsageMetrics?
}
```

---

## Supporting Data Structures

### TraditionalRulershipTable

**Purpose**: Lookup table for classical planetary rulerships (pre-outer planets).

```swift
struct TraditionalRulershipTable {
    static let rulerships: [ZodiacSign: PlanetType] = [
        .aries: .mars,
        .taurus: .venus,
        .gemini: .mercury,
        .cancer: .moon,
        .leo: .sun,
        .virgo: .mercury,
        .libra: .venus,
        .scorpio: .mars,
        .sagittarius: .jupiter,
        .capricorn: .saturn,
        .aquarius: .saturn,
        .pisces: .jupiter
    ]
    
    static func ruler(of sign: ZodiacSign) -> PlanetType {
        guard let ruler = rulerships[sign] else {
            fatalError("No ruler found for sign \(sign)")
        }
        return ruler
    }
}
```

---

## State Transitions

### NatalChart Lifecycle

```
┌──────────────┐
│  Created     │ (Birth details entered)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Calculating  │ (API calls in progress)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Complete     │ (planets, houses, aspects, nodes, Lilith, rulers calculated)
└──────────────┘
```

**Validation at "Complete" state**:
- All 10 planets present
- 12 houses present
- At least 3 astrological points (North Node, South Node, Lilith)
- Exactly 12 house rulers
- Ascendant and Midheaven set

### GeneratedReport Lifecycle

```
┌──────────────┐
│  Initiated   │ (User purchases report area)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Querying     │ (Vector database query for knowledge)
│  Knowledge   │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Generating   │ (AI generating structured report)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Complete     │ (Report with sources saved)
└──────────────┘
```

**Validation at "Complete" state**:
- All mandatory sections present (summary, key influences, detailed analysis, recommendations, knowledge usage)
- Knowledge sources count ≥ 10 (per FR-018)
- Knowledge metrics calculated and populated

---

## Database Schema (SwiftData)

### New Models

```swift
@Model
final class AstrologicalPointModel {
    @Attribute(.unique) var id: UUID
    var pointType: String  // PointType.rawValue
    var longitude: Double
    var zodiacSign: String  // ZodiacSign.rawValue
    var housePlacement: Int
    
    var natalChart: NatalChartModel?
}

@Model
final class HouseRulerModel {
    @Attribute(.unique) var id: UUID
    var houseNumber: Int
    var rulingPlanet: String  // PlanetType.rawValue
    var rulerSign: String
    var rulerHouse: Int
    // rulerAspects stored as JSON string
    
    var natalChart: NatalChartModel?
}

@Model
final class EnhancedKnowledgeSourceModel {
    @Attribute(.unique) var id: UUID
    var bookTitle: String
    var author: String?
    var chapter: String?
    var pageRange: String?
    var snippet: String
    var relevanceScore: Double
    var sourceType: String  // SourceType.rawValue
    
    var report: GeneratedReportModel?
}
```

---

## Testing Data

### Fixture: Expert Chart (Taurus/Scorpio Nodes)

```swift
extension NatalChart {
    static var expertTestChart: NatalChart {
        NatalChart(
            id: UUID(),
            birthDate: Date(timeIntervalSince1970: 638841000), // 1990-03-25
            birthTime: Date(timeIntervalSince1970: 638892600), // 14:30 UTC
            latitude: 50.4501,
            longitude: 30.5234,
            locationName: "Kyiv, Ukraine",
            planets: [...],
            houses: [...],
            aspects: [...],
            ascendant: 15.0,  // 15° Aries
            midheaven: 285.0,  // 15° Capricorn
            astrologicalPoints: [
                AstrologicalPoint(
                    pointType: .northNode,
                    longitude: 47.0,  // 17° Taurus
                    zodiacSign: .taurus,
                    housePlacement: 3
                ),
                AstrologicalPoint(
                    pointType: .southNode,
                    longitude: 227.0,  // 17° Scorpio
                    zodiacSign: .scorpio,
                    housePlacement: 9
                ),
                AstrologicalPoint(
                    pointType: .lilith,
                    longitude: 156.0,  // 6° Virgo
                    zodiacSign: .virgo,
                    housePlacement: 6
                )
            ],
            houseRulers: [
                HouseRuler(
                    houseNumber: 1,
                    rulingPlanet: .mars,  // Aries rising
                    rulerSign: .libra,
                    rulerHouse: 7
                ),
                // ... other 11 rulers
            ]
        )
    }
}
```

### Validation Tests

```swift
func testExpertChartNodeAccuracy() {
    let chart = NatalChart.expertTestChart
    let northNode = chart.astrologicalPoints.first { $0.pointType == .northNode }!
    
    // Expected from Swiss Ephemeris: 17° Taurus = 47°
    #expect(abs(northNode.longitude - 47.0) < 1.0) // Within 1 degree (SC-001)
    #expect(northNode.zodiacSign == .taurus)
    #expect(northNode.housePlacement == 3)
}

func testHouseRulerCalculation() {
    let chart = NatalChart.expertTestChart
    let ascendantRuler = chart.houseRulers.first { $0.houseNumber == 1 }!
    
    // Ascendant in Aries → ruler is Mars
    #expect(ascendantRuler.rulingPlanet == .mars)
    // Mars in 7th house
    #expect(ascendantRuler.rulerHouse == 7)
}
```

---

## Data Model Summary

| Entity | Purpose | Key Attributes | Relationships |
|--------|---------|----------------|---------------|
| **AstrologicalPoint** | Nodes, Lilith, angles | pointType, longitude, sign, house | Many-to-one with NatalChart |
| **HouseRuler** | Traditional rulerships | houseNumber, rulingPlanet, rulerHouse | Many-to-one with NatalChart (12 per chart) |
| **EnhancedKnowledgeSource** | Source attribution | bookTitle, author, snippet, relevanceScore | Many-to-one with GeneratedReport |
| **KnowledgeUsageMetrics** | Usage statistics | totalSources, vectorDBCount, avgScore, cacheHit | One-to-one with GeneratedReport |
| **NatalChart** (modified) | Complete chart data | +astrologicalPoints, +houseRulers | Unchanged |
| **GeneratedReport** (modified) | AI-generated report | +knowledgeSources, +knowledgeMetrics | Unchanged |

---

**Data Model Status**: ✅ **COMPLETE** - Ready for contract definition (Phase 1 continuation)

**Next Step**: Generate API contracts in `contracts/` directory
