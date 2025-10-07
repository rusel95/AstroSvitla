# Data Model: AstroSvitla

**Feature**: 001-astrosvitla-ios-native
**Related**: [spec.md](./spec.md) | [plan.md](./plan.md)
**Created**: 2025-10-07

---

## Overview

AstroSvitla uses **SwiftData** (iOS 17+) for local persistence with offline-first architecture. All user data (charts, reports, purchases) stored locally on device with no cloud sync in MVP.

### Technology Choice

- **SwiftData**: Apple's modern persistence framework
- **Why not CoreData**: Simpler API, better SwiftUI integration, aligns with Constitutional Article II
- **Storage Location**: Local device only (privacy-first approach)
- **Backup Strategy**: User responsible for device backups (iCloud device backup)

---

## Entity Relationship Diagram

```
┌──────────────┐
│     User     │
│  (anonymous) │
└───┬──────────┘
    │
    │ 1:N
    │
    ▼
┌──────────────┐         ┌──────────────────┐
│  BirthChart  │◄────┬──►│  ReportPurchase  │
│              │     │   │                  │
│ • chartData  │  1:N│   │ • reportText     │
│ • birthInfo  │     │   │ • purchaseInfo   │
└──────────────┘     │   └──────────────────┘
                     │
                  belongs to
```

---

## SwiftData Models

### 1. User Model

```swift
import SwiftData
import Foundation

@Model
final class User {
    // Primary identifier
    @Attribute(.unique)
    var id: UUID

    // Metadata
    var createdAt: Date
    var lastActiveAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade)
    var charts: [BirthChart] = []

    @Relationship(deleteRule: .cascade)
    var purchases: [ReportPurchase] = []

    // Initializer
    init(id: UUID = UUID()) {
        self.id = id
        self.createdAt = Date()
        self.lastActiveAt = Date()
    }

    // Helper methods
    func updateLastActive() {
        self.lastActiveAt = Date()
    }
}
```

**Purpose**: Anonymous device user (no authentication)

**Attributes**:
- `id`: Unique identifier (UUID)
- `createdAt`: App first launch timestamp
- `lastActiveAt`: Last interaction timestamp

**Relationships**:
- `charts`: Collection of user's birth charts (cascade delete)
- `purchases`: Collection of report purchases (cascade delete)

**Business Rules**:
- One user per device installation
- Created automatically on first app launch
- Persists across app sessions
- Deleted if user deletes app (device uninstall)

---

### 2. BirthChart Model

```swift
import SwiftData
import Foundation

@Model
final class BirthChart {
    // Primary identifier
    @Attribute(.unique)
    var id: UUID

    // User-facing info
    var name: String // "My Chart", "Partner's Chart", etc.

    // Birth data
    var birthDate: Date
    var birthTime: Date
    var locationName: String // "Kyiv, Ukraine"
    var latitude: Double
    var longitude: Double
    var timezone: String // "Europe/Kyiv"

    // Calculated chart data (serialized JSON)
    var chartDataJSON: String

    // Metadata
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(inverse: \User.charts)
    var user: User?

    @Relationship(deleteRule: .cascade)
    var reports: [ReportPurchase] = []

    // Initializer
    init(
        id: UUID = UUID(),
        name: String,
        birthDate: Date,
        birthTime: Date,
        locationName: String,
        latitude: Double,
        longitude: Double,
        timezone: String,
        chartDataJSON: String = ""
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.birthTime = birthTime
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.timezone = timezone
        self.chartDataJSON = chartDataJSON
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // Computed properties
    var birthDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: birthDate) + " " + formatter.string(from: birthTime)
    }

    // Helper methods
    func updateChartData(_ jsonString: String) {
        self.chartDataJSON = jsonString
        self.updatedAt = Date()
    }
}
```

**Purpose**: Store complete natal chart information

**Attributes**:
- `id`: Unique identifier
- `name`: User-defined label for chart
- `birthDate`: Date of birth
- `birthTime`: Time of birth (minute precision)
- `locationName`: Human-readable location
- `latitude`: Geographic coordinate (decimal degrees)
- `longitude`: Geographic coordinate (decimal degrees)
- `timezone`: IANA timezone identifier
- `chartDataJSON`: Serialized NatalChart domain model
- `createdAt`: Chart creation timestamp
- `updatedAt`: Last modification timestamp

**Relationships**:
- `user`: Belongs to one User
- `reports`: Has many ReportPurchases (cascade delete)

**Business Rules**:
- Requires all birth data fields (validation in ViewModel)
- Location must be geocoded before saving
- Chart data calculated once and cached (immutable)
- Can be deleted by user (cascade deletes associated reports)
- Multiple charts allowed per user

**Validation**:
- Birth date: 1900-01-01 to 2100-12-31
- Birth time: Valid 24-hour time with minute precision
- Latitude: -90 to +90
- Longitude: -180 to +180
- Name: 1-50 characters

---

### 3. ReportPurchase Model

```swift
import SwiftData
import Foundation

@Model
final class ReportPurchase {
    // Primary identifier
    @Attribute(.unique)
    var id: UUID

    // Report content
    var area: String // "finances", "career", "relationships", "health", "general"
    var reportText: String // Generated AI report content
    var language: String // "en" or "uk"

    // Purchase info
    var price: Decimal
    var currency: String // "USD"
    var transactionId: String // StoreKit receipt
    var purchaseDate: Date

    // Metadata
    var generatedAt: Date
    var wordCount: Int

    // Relationships
    @Relationship(inverse: \BirthChart.reports)
    var chart: BirthChart?

    // Initializer
    init(
        id: UUID = UUID(),
        area: String,
        reportText: String,
        language: String,
        price: Decimal,
        currency: String = "USD",
        transactionId: String
    ) {
        self.id = id
        self.area = area
        self.reportText = reportText
        self.language = language
        self.price = price
        self.currency = currency
        self.transactionId = transactionId
        self.purchaseDate = Date()
        self.generatedAt = Date()
        self.wordCount = reportText.split(separator: " ").count
    }

    // Computed properties
    var areaDisplayName: String {
        switch area {
        case "finances": return "Finances"
        case "career": return "Career"
        case "relationships": return "Relationships"
        case "health": return "Health"
        case "general": return "General Overview"
        default: return area.capitalized
        }
    }

    var estimatedReadingTime: Int {
        // Average reading speed: 200 words per minute
        return max(1, wordCount / 200)
    }

    // Helper methods
    func isForArea(_ reportArea: ReportArea) -> Bool {
        return self.area == reportArea.rawValue
    }
}
```

**Purpose**: Store purchased report with payment receipt

**Attributes**:
- `id`: Unique identifier
- `area`: Life area category (enum string value)
- `reportText`: Full AI-generated report content
- `language`: Report language ("en" or "uk")
- `price`: Amount paid (Decimal for precision)
- `currency`: Currency code (USD)
- `transactionId`: StoreKit transaction receipt
- `purchaseDate`: When purchase was made
- `generatedAt`: When report was generated
- `wordCount`: Number of words in report

**Relationships**:
- `chart`: Belongs to one BirthChart

**Business Rules**:
- One purchase = one report for one life area
- Report content is immutable after generation
- User owns report permanently (offline access)
- Transaction ID must be unique (StoreKit validation)
- Cannot purchase same area twice for same chart (UI prevention)

**Pricing** (from spec):
- General Overview: $9.99
- Finances: $6.99
- Career: $6.99
- Relationships: $5.99
- Health: $5.99

---

## Domain Models (Non-Persistent)

These models exist only in memory during calculations and are serialized to JSON for storage in `BirthChart.chartDataJSON`.

### NatalChart (Domain Model)

```swift
struct NatalChart: Codable {
    let birthDate: Date
    let birthTime: Date
    let latitude: Double
    let longitude: Double
    let locationName: String

    let planets: [Planet]
    let houses: [House]
    let aspects: [Aspect]

    let ascendant: Double // Degree position
    let midheaven: Double // Degree position

    var calculatedAt: Date
}
```

### Planet (Domain Model)

```swift
struct Planet: Codable, Identifiable {
    let id: UUID
    let name: PlanetType
    let longitude: Double // Ecliptic longitude (0-360°)
    let latitude: Double // Ecliptic latitude
    let sign: ZodiacSign
    let house: Int // 1-12
    let isRetrograde: Bool
    let speed: Double // Daily motion in degrees
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
    // Future: Add north node, south node, chiron
}
```

### House (Domain Model)

```swift
struct House: Codable, Identifiable {
    let id: UUID
    let number: Int // 1-12
    let cusp: Double // Degree position (0-360°)
    let sign: ZodiacSign
}
```

### Aspect (Domain Model)

```swift
struct Aspect: Codable, Identifiable {
    let id: UUID
    let planet1: PlanetType
    let planet2: PlanetType
    let type: AspectType
    let orb: Double // Orb of aspect in degrees
    let isApplying: Bool // Aspect is forming (not separating)
}

enum AspectType: String, Codable {
    case conjunction = "Conjunction" // 0°
    case opposition = "Opposition" // 180°
    case trine = "Trine" // 120°
    case square = "Square" // 90°
    case sextile = "Sextile" // 60°
    // Future: Add minor aspects (semisquare, sesquiquadrate, etc.)

    var angle: Double {
        switch self {
        case .conjunction: return 0
        case .opposition: return 180
        case .trine: return 120
        case .square: return 90
        case .sextile: return 60
        }
    }

    var maxOrb: Double {
        // Standard orbs for major aspects
        switch self {
        case .conjunction, .opposition: return 8.0
        case .trine, .square: return 7.0
        case .sextile: return 6.0
        }
    }
}
```

### ZodiacSign (Enum)

```swift
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

    // Element
    var element: Element {
        switch self {
        case .aries, .leo, .sagittarius: return .fire
        case .taurus, .virgo, .capricorn: return .earth
        case .gemini, .libra, .aquarius: return .air
        case .cancer, .scorpio, .pisces: return .water
        }
    }

    // Modality
    var modality: Modality {
        switch self {
        case .aries, .cancer, .libra, .capricorn: return .cardinal
        case .taurus, .leo, .scorpio, .aquarius: return .fixed
        case .gemini, .virgo, .sagittarius, .pisces: return .mutable
        }
    }

    // Degree range
    var degreeRange: ClosedRange<Double> {
        let index = Double(ZodiacSign.allCases.firstIndex(of: self) ?? 0)
        let start = index * 30.0
        return start...(start + 30.0)
    }
}

enum Element: String, Codable {
    case fire = "Fire"
    case earth = "Earth"
    case air = "Air"
    case water = "Water"
}

enum Modality: String, Codable {
    case cardinal = "Cardinal"
    case fixed = "Fixed"
    case mutable = "Mutable"
}
```

### ReportArea (Enum)

```swift
enum ReportArea: String, Codable, CaseIterable {
    case finances = "finances"
    case career = "career"
    case relationships = "relationships"
    case health = "health"
    case general = "general"

    var displayName: String {
        switch self {
        case .finances: return "Finances"
        case .career: return "Career"
        case .relationships: return "Relationships"
        case .health: return "Health"
        case .general: return "General Overview"
        }
    }

    var price: Decimal {
        switch self {
        case .general: return 9.99
        case .finances, .career: return 6.99
        case .relationships, .health: return 5.99
        }
    }

    var icon: String { // SF Symbol names
        switch self {
        case .finances: return "dollarsign.circle.fill"
        case .career: return "briefcase.fill"
        case .relationships: return "heart.fill"
        case .health: return "heart.text.square.fill"
        case .general: return "star.circle.fill"
        }
    }

    var storeKitProductID: String {
        return "com.astrosvitla.astroinsight.report.\(self.rawValue)"
    }
}
```

---

## ModelContainer Setup

```swift
// In AstroSvitlaApp.swift

import SwiftUI
import SwiftData

@main
struct AstroSvitlaApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [User.self, BirthChart.self, ReportPurchase.self])
        }
    }
}

// Alternative: Shared ModelContainer with custom configuration

extension ModelContainer {
    static var shared: ModelContainer = {
        let schema = Schema([
            User.self,
            BirthChart.self,
            ReportPurchase.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false, // Persist to disk
            allowsSave: true
        )

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )

            // Initialize default user if needed
            initializeDefaultUserIfNeeded(in: container)

            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private static func initializeDefaultUserIfNeeded(in container: ModelContainer) {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<User>()

        do {
            let users = try context.fetch(fetchDescriptor)
            if users.isEmpty {
                let newUser = User()
                context.insert(newUser)
                try context.save()
                print("✅ Default user created")
            }
        } catch {
            print("❌ Error initializing default user: \(error)")
        }
    }
}
```

---

## Queries and Operations

### Common SwiftData Queries

```swift
import SwiftData

// Fetch all birth charts for current user
@Query(sort: \BirthChart.createdAt, order: .reverse)
var charts: [BirthChart]

// Fetch all purchased reports for specific chart
@Query(filter: #Predicate<ReportPurchase> { $0.chart?.id == chartId })
var reports: [ReportPurchase]

// Fetch specific report by area
@Query(
    filter: #Predicate<ReportPurchase> {
        $0.area == "finances" && $0.chart?.id == chartId
    }
)
var financeReport: [ReportPurchase]

// Check if user already purchased report for area
func hasPurchased(area: ReportArea, for chart: BirthChart) -> Bool {
    let descriptor = FetchDescriptor<ReportPurchase>(
        predicate: #Predicate {
            $0.area == area.rawValue && $0.chart?.id == chart.id
        }
    )
    let results = try? context.fetch(descriptor)
    return !(results?.isEmpty ?? true)
}
```

### CRUD Operations

```swift
import SwiftData

class ChartService {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // Create new birth chart
    func createChart(
        name: String,
        birthDate: Date,
        birthTime: Date,
        location: String,
        latitude: Double,
        longitude: Double,
        timezone: String,
        chartData: NatalChart
    ) throws -> BirthChart {

        // Serialize domain model to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let chartDataJSON = try encoder.encode(chartData)
        let jsonString = String(data: chartDataJSON, encoding: .utf8) ?? ""

        // Create SwiftData model
        let chart = BirthChart(
            name: name,
            birthDate: birthDate,
            birthTime: birthTime,
            locationName: location,
            latitude: latitude,
            longitude: longitude,
            timezone: timezone,
            chartDataJSON: jsonString
        )

        context.insert(chart)
        try context.save()

        return chart
    }

    // Read chart and deserialize
    func getNatalChart(from birthChart: BirthChart) throws -> NatalChart {
        guard let jsonData = birthChart.chartDataJSON.data(using: .utf8) else {
            throw ChartError.invalidData
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(NatalChart.self, from: jsonData)
    }

    // Update chart name
    func updateChartName(_ chart: BirthChart, newName: String) throws {
        chart.name = newName
        chart.updatedAt = Date()
        try context.save()
    }

    // Delete chart (cascade deletes reports)
    func deleteChart(_ chart: BirthChart) throws {
        context.delete(chart)
        try context.save()
    }
}

class ReportService {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // Save purchased report
    func saveReport(
        for chart: BirthChart,
        area: ReportArea,
        reportText: String,
        language: String,
        transactionId: String
    ) throws -> ReportPurchase {

        let report = ReportPurchase(
            area: area.rawValue,
            reportText: reportText,
            language: language,
            price: area.price,
            transactionId: transactionId
        )

        report.chart = chart
        context.insert(report)
        try context.save()

        return report
    }

    // Fetch all reports for chart
    func getReports(for chart: BirthChart) throws -> [ReportPurchase] {
        let descriptor = FetchDescriptor<ReportPurchase>(
            predicate: #Predicate { $0.chart?.id == chart.id },
            sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // Check if area already purchased
    func isPurchased(area: ReportArea, for chart: BirthChart) -> Bool {
        let descriptor = FetchDescriptor<ReportPurchase>(
            predicate: #Predicate {
                $0.area == area.rawValue && $0.chart?.id == chart.id
            }
        )
        let results = try? context.fetch(descriptor)
        return !(results?.isEmpty ?? true)
    }
}

enum ChartError: Error {
    case invalidData
    case serializationFailed
    case deserializationFailed
}
```

---

## Data Migration Strategy

### MVP: No Migration Needed
- First release with SwiftData schema
- No legacy data to migrate

### Future Versions

If schema changes required:

```swift
// Version 2 migration example
let schema = Schema([
    User.self,
    BirthChart.self,
    ReportPurchase.self
])

let v1Schema = Schema([...]) // Old schema
let v2Schema = Schema([...]) // New schema

let migrationPlan = SchemaMigrationPlan([
    MigrationStage.lightweight(fromVersion: v1Schema, toVersion: v2Schema)
])

let configuration = ModelConfiguration(
    schema: schema,
    migrationPlan: migrationPlan
)
```

---

## Performance Considerations

### Indexing
- `@Attribute(.unique)` on `id` fields provides automatic indexing
- Consider adding indexes if querying by date frequently

### Memory Management
- `chartDataJSON` can be large (5-10 KB per chart)
- Lazy loading: only deserialize when needed
- Pagination: if user has 50+ charts, implement pagination

### Storage Limits
- Typical data size per user:
  - 1 chart: ~10 KB
  - 1 report: ~5 KB
  - 10 charts + 20 reports: ~200 KB
- Conservative estimate: 1000 users × 200 KB = 200 MB total
- No storage concerns for MVP

---

## Data Privacy & Security

### Privacy Compliance
- **No PII collection**: Birth data is not personally identifiable without name
- **Local storage only**: No network transmission except for report generation
- **No analytics**: No tracking or telemetry
- **User control**: User can delete all data by deleting app

### Security Measures
- **StoreKit receipts**: Validated locally
- **No API keys in database**: Config.swift (gitignored)
- **No plaintext secrets**: Use iOS Keychain for sensitive data (future)

---

## Testing Strategy

### Unit Tests

```swift
import XCTest
import SwiftData
@testable import AstroSvitla

class BirthChartModelTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() {
        super.setUp()

        let schema = Schema([User.self, BirthChart.self, ReportPurchase.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: [configuration])
        context = ModelContext(container)
    }

    func testCreateBirthChart() throws {
        // Given
        let chart = BirthChart(
            name: "Test Chart",
            birthDate: Date(),
            birthTime: Date(),
            locationName: "Kyiv, Ukraine",
            latitude: 50.4501,
            longitude: 30.5234,
            timezone: "Europe/Kyiv"
        )

        // When
        context.insert(chart)
        try context.save()

        // Then
        let fetchDescriptor = FetchDescriptor<BirthChart>()
        let charts = try context.fetch(fetchDescriptor)

        XCTAssertEqual(charts.count, 1)
        XCTAssertEqual(charts.first?.name, "Test Chart")
    }

    func testCascadeDeleteReports() throws {
        // Given
        let chart = BirthChart(...)
        context.insert(chart)

        let report = ReportPurchase(
            area: "finances",
            reportText: "Test report",
            language: "en",
            price: 6.99,
            transactionId: "test123"
        )
        report.chart = chart
        context.insert(report)
        try context.save()

        // When: Delete chart
        context.delete(chart)
        try context.save()

        // Then: Report should be deleted too
        let reportDescriptor = FetchDescriptor<ReportPurchase>()
        let remainingReports = try context.fetch(reportDescriptor)

        XCTAssertEqual(remainingReports.count, 0)
    }
}
```

---

## Summary

✅ **SwiftData models**: User, BirthChart, ReportPurchase
✅ **Domain models**: NatalChart, Planet, House, Aspect, enums
✅ **Relationships**: User → Charts → Reports (cascade delete)
✅ **Serialization**: JSON encoding for complex chart data
✅ **Queries**: SwiftData @Query and FetchDescriptor patterns
✅ **Privacy**: Local-only storage, no PII, no tracking
✅ **Testing**: In-memory container for unit tests

**Next**: Implement SwiftData models in Phase 1.2 of implementation plan
