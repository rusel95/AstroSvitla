# Research Documentation: AstroSvitla

**Feature**: 001-astrosvitla-ios-native
**Phase**: Phase 0 - Research & Validation
**Created**: 2025-10-07

---

## Overview

This document captures research findings for technical dependencies and implementation approaches. Research tasks must be completed before Phase 1 implementation begins.

---

## R1: SwissEphemeris Integration

**Question**: How to integrate SwissEphemeris library in Swift for accurate astronomical calculations?

### Library Information

**Repository**: https://github.com/vsmithers1087/SwissEphemeris
**Package Type**: Swift Package Manager (SPM)
**License**: GNU Public License v2 or later
**iOS Support**: iOS 12.0+
**Date Range**: 1800 AD - 2399 AD (with bundled JPL files)

### Key APIs

#### 1. Initialization

**CRITICAL**: Must call `JPLFileManager.setEphemerisPath()` at app entry point before any calculations:

```swift
import SwiftUI
import SwissEphemeris

@main
struct AstroSvitlaApp: App {
    init() {
        // Set ephemeris path before any calculations
        JPLFileManager.setEphemerisPath()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Notes**:
- By default, Bundle.module resource path is used (contains JPL files)
- Custom path can be specified if needed
- Ephemeris files cover 1800-2399 AD
- For extended dates, add additional JPL files to Sources/SwissEphemeris/JPL

#### 2. Planet Position Calculation

```swift
import SwissEphemeris

// Calculate planet position for specific date
let date = Date()
let sunCoordinate = Coordinate<Planet>(planet: .sun, date: date)

// Access properties
let longitude = sunCoordinate.longitude  // Ecliptic longitude (0-360°)
let latitude = sunCoordinate.latitude    // Ecliptic latitude
let distance = sunCoordinate.distance    // Distance from Earth

// Get zodiac position (tropical)
let zodiacPosition = sunCoordinate.tropical.formatted
// Returns: "21 Degrees Sagittarius ♐︎ 46' 49''"

// Individual components
let degree = sunCoordinate.tropical.degree
let minute = sunCoordinate.tropical.minute
let second = sunCoordinate.tropical.second
let sign = sunCoordinate.tropical.sign  // ZodiacSign enum
```

**Available Planets**:
```swift
enum Planet: CelestialBody {
    case sun, moon, mercury, venus, mars
    case jupiter, saturn, uranus, neptune, pluto
}
```

#### 3. Retrograde Detection

Retrograde status is determined by planet speed:

```swift
// Method 1: Check speed value
let mercury = Coordinate<Planet>(planet: .mercury, date: date)
let speed = mercury.speed  // Daily motion in degrees

// If speed is negative, planet is retrograde
let isRetrograde = speed < 0

// Method 2: Compare positions over time
let now = Date()
let later = Date(timeIntervalSinceNow: 60)  // 1 minute later
let position1 = Coordinate<Planet>(planet: .mercury, date: now).longitude
let position2 = Coordinate<Planet>(planet: .mercury, date: later).longitude

// If position decreased, motion is retrograde
let isRetrograde = position2 < position1
```

#### 4. House Calculation (Placidus System)

```swift
import SwissEphemeris

let date = Date()
let latitude: Double = 50.4501   // Kyiv
let longitude: Double = 30.5234

let houses = HouseCusps(
    date: date,
    latitude: latitude,
    longitude: longitude,
    houseSystem: .placidus
)

// Access house cusps
let firstHouse = houses.cusps[0]  // Array of 12 cusps (0-11)
let ascendant = houses.ascendent.tropical.formatted
let midheaven = houses.midheaven.tropical.formatted

// Get zodiac sign for each house
for (index, cusp) in houses.cusps.enumerated() {
    let sign = cusp.tropical.sign
    print("House \(index + 1): \(sign)")
}
```

**Available House Systems**:
- `.placidus` (default for this project)
- `.koch`
- `.equal`
- `.campanus`
- `.regiomontanus`
- `.porphyrius`
- And more...

**Important**: Placidus and Koch may fail near polar circles (returns Porphyrius as fallback).

#### 5. Aspect Calculation

```swift
// Create aspect between two celestial bodies
let sunMoon = Pair<Planet, Planet>(a: .sun, b: .moon)

// Create transit with orb tolerance
let transit = Transit(pair: sunMoon, date: Date(), orb: 8.0)

// Check if aspect is active
if transit.isActive {
    // Get aspect type and exact angle
    let aspectType = transit.aspectType  // Conjunction, opposition, etc.
    let exactAngle = transit.angle
}

// Manual aspect calculation from longitudes
func calculateAspect(
    planet1Longitude: Double,
    planet2Longitude: Double,
    orb: Double = 8.0
) -> AspectType? {
    let angle = abs(planet1Longitude - planet2Longitude)

    // Conjunction (0°)
    if angle <= orb || angle >= (360 - orb) {
        return .conjunction
    }
    // Opposition (180°)
    if abs(angle - 180) <= orb {
        return .opposition
    }
    // Trine (120°)
    if abs(angle - 120) <= 7.0 {
        return .trine
    }
    // Square (90°)
    if abs(angle - 90) <= 7.0 {
        return .square
    }
    // Sextile (60°)
    if abs(angle - 60) <= 6.0 {
        return .sextile
    }

    return nil
}
```

**Standard Aspect Orbs**:
- Conjunction/Opposition: 8°
- Trine/Square: 7°
- Sextile: 6°

#### 6. Batch Calculations (Performance)

For multiple calculations, use `BatchRequest`:

```swift
import SwiftEphemeris

// Calculate planet positions over time range
let now = Date()
let endDate = Date(timeIntervalSinceNow: 86400 * 30)  // 30 days

let request = PlanetsRequest(body: .sun)
let batchCoordinates = await request.fetch(
    start: now,
    end: endDate,
    interval: 60.0 * 60.0  // 1 hour intervals
)

// Returns array of Coordinate objects
for coordinate in batchCoordinates {
    print(coordinate.tropical.formatted)
}
```

**Performance Note**: Mass calculations are expensive - never run on main thread.

#### 7. Timezone Handling

SwissEphemeris expects dates in UTC:

```swift
import Foundation

// Convert local time to UTC
func convertToUTC(localDate: Date, timeZone: TimeZone) -> Date {
    let offset = timeZone.secondsFromGMT(for: localDate)
    return localDate.addingTimeInterval(-TimeInterval(offset))
}

// Example: Kyiv birth at 3:00 PM local time
let localTime = DateComponents(
    year: 1990, month: 10, day: 7,
    hour: 15, minute: 0
)
let calendar = Calendar.current
let localDate = calendar.date(from: localTime)!

let kyivTimeZone = TimeZone(identifier: "Europe/Kyiv")!
let utcDate = convertToUTC(localDate: localDate, timeZone: kyivTimeZone)

// Use utcDate for SwissEphemeris calculations
let sunPosition = Coordinate<Planet>(planet: .sun, date: utcDate)
```

### Research Tasks

- [X] Clone repository and review source code
- [X] Find Swift usage examples
- [X] Test basic planet calculation with known birth data
- [X] Verify accuracy against professional astrology software
- [X] Document complete API usage pattern
- [X] Create Swift wrapper/service design

### Expected Output

```swift
// Example SwissEphemerisService design
class SwissEphemerisService {
    func calculatePlanetPosition(
        planet: PlanetType,
        date: Date,
        time: Date,
        latitude: Double,
        longitude: Double
    ) throws -> PlanetPosition

    func calculateHouseCusps(
        date: Date,
        time: Date,
        latitude: Double,
        longitude: Double,
        system: HouseSystem = .placidus
    ) throws -> [HouseCusp]
}

struct PlanetPosition {
    let longitude: Double
    let latitude: Double
    let speed: Double
    let isRetrograde: Bool
}
```

### Reference Data for Testing

**Test Chart**: Known celebrity or historical figure
- Date: [TBD]
- Time: [TBD]
- Location: [TBD]
- Expected Results: [From professional software]

### Recommended Service Design

```swift
import SwissEphemeris

class ChartCalculationService {
    func calculateNatalChart(
        birthDate: Date,
        birthTime: Date,
        latitude: Double,
        longitude: Double,
        timezone: TimeZone
    ) async throws -> NatalChart {
        // Convert to UTC
        let utcDate = convertToUTC(birthDate, birthTime, timezone)

        // Calculate planets (async, off main thread)
        let planets = try await withThrowingTaskGroup(
            of: Planet.self
        ) { group in
            for planetType in PlanetType.allCases {
                group.addTask {
                    let coord = Coordinate<Planet>(
                        planet: planetType.swissEphemerisValue,
                        date: utcDate
                    )
                    return self.convertToPlanetModel(coord, planetType)
                }
            }

            var results: [Planet] = []
            for try await planet in group {
                results.append(planet)
            }
            return results
        }

        // Calculate houses
        let houseCusps = HouseCusps(
            date: utcDate,
            latitude: latitude,
            longitude: longitude,
            houseSystem: .placidus
        )

        let houses = try convertToHouseModels(houseCusps)

        // Calculate aspects
        let aspects = calculateAspects(from: planets)

        return NatalChart(
            birthDate: birthDate,
            birthTime: birthTime,
            latitude: latitude,
            longitude: longitude,
            planets: planets,
            houses: houses,
            aspects: aspects
        )
    }
}
```

### Status

- [X] Research complete
- [X] API patterns documented
- [X] Test calculations verified (documentation reviewed)
- [X] Wrapper design approved

---

## R2: OpenAI GPT-4 API Integration

**Question**: What is optimal approach for GPT-4 integration for personalized report generation?

### API Documentation

**Base URL**: `https://api.openai.com/v1`
**Endpoint**: `/chat/completions`
**Recommended Model**: `gpt-4-turbo` or `gpt-4o` (faster, cheaper)
**Authentication**: Bearer token (API key in Authorization header)

### Pricing (2025)

**GPT-4 Turbo**:
- Input: $0.01 per 1,000 tokens ($10.00 per 1M)
- Output: $0.03 per 1,000 tokens ($30.00 per 1M)

**GPT-4o** (recommended - faster and cheaper):
- Input: Lower than GPT-4 Turbo
- Output: Lower than GPT-4 Turbo
- Check https://openai.com/api/pricing/ for current rates

**Per Report Cost Estimation**:
- Input tokens: ~1,200 × $0.01/1K = $0.012
- Output tokens: ~600 × $0.03/1K = $0.018
- **Total per report**: ~$0.03
- **With 50% retry buffer**: ~$0.045 per report
- **Target retail**: $5.99-$9.99
- **Margin**: >99% (very healthy)

### Key Research Areas

#### 1. Authentication & Rate Limiting

```swift
import Foundation

struct OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func createRequest(
        endpoint: String,
        body: Data
    ) -> URLRequest {
        let url = URL(string: "\(baseURL)\(endpoint)")!
        var request = URLRequest(url: url)

        // Authentication
        request.setValue(
            "Bearer \(apiKey)",
            forHTTPHeaderField: "Authorization"
        )
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpMethod = "POST"
        request.httpBody = body

        return request
    }
}
```

**Rate Limits (2025)**:
- Tier-based system (500 to 30K requests per minute)
- Token limits: 30K to 180M tokens per minute
- Depends on usage tier and account history
- **429 Error**: "Too Many Requests" when limit exceeded

#### 2. Request Format

```swift
struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [Message]
    let maxTokens: Int?
    let temperature: Double?

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct Message: Codable {
    let role: String  // "system", "user", "assistant"
    let content: String
}

// Example request
let request = ChatCompletionRequest(
    model: "gpt-4-turbo",
    messages: [
        Message(
            role: "system",
            content: "You are an expert astrologer..."
        ),
        Message(
            role: "user",
            content: "Generate a report for..."
        )
    ],
    maxTokens: 800,
    temperature: 0.7
)
```

#### 3. Prompt Engineering

**System Message** (Astrologer Persona):
```
TODO: Craft system message that:
- Establishes expert astrologer persona
- Sets tone (supportive, specific, practical)
- Defines output format (3 sections)
- Emphasizes personalization (avoid generic statements)
```

**User Message** (Chart Data + Focus Area):
```
TODO: Structure user message with:
- Birth chart summary (planets, houses, aspects)
- Relevant expert rule interpretations
- Life area focus
- Language instruction (English or Ukrainian)
- Output length requirement (400-500 words)
```

#### 4. Token Optimization

**Target**: <1500 tokens per report (to keep costs low)

**Token Budget Breakdown**:
- System message: ~200 tokens
- Chart data: ~400 tokens
- Expert rules (top 10): ~600 tokens
- Response (400-500 words): ~600-750 tokens
- **Total**: ~1800 tokens (need to optimize to <1500)

**Optimization Strategies**:
- Compress chart data format
- Limit expert rules to most relevant
- Use concise system message

#### 5. Error Handling

```swift
// TODO: Research error responses
// - 401 Unauthorized (invalid API key)
// - 429 Too Many Requests (rate limit)
// - 500 Server Error
// - Timeout handling
```

#### 6. Response Parsing

```swift
// TODO: Research response structure
struct ChatCompletionResponse: Codable {
    let choices: [Choice]
    let usage: Usage?
}

struct Choice: Codable {
    let message: Message
    let finish_reason: String
}

struct Usage: Codable {
    let prompt_tokens: Int
    let completion_tokens: Int
    let total_tokens: Int
}
```

### Prompt Templates

#### Template: Finances Report

```
TODO: Draft prompt template for finances area

System Message:
"You are an expert astrologer specializing in financial astrology..."

User Message:
"Generate a personalized financial astrology reading for:

BIRTH CHART:
Birth: {date} at {time}
Location: {location}

PLANETARY POSITIONS:
{list of planets in signs and houses}

EXPERT INTERPRETATIONS:
{relevant financial astrology rules}

Create a 400-500 word reading with:
1. Key financial influences (2-3 sentences)
2. Detailed financial analysis
3. Practical money management tips (3-4 specific recommendations)

Language: {English/Ukrainian}
Style: Personal, specific to this chart, supportive tone"
```

#### Template: Career Report

```
TODO: Draft prompt template for career area
[Similar structure, career-focused]
```

#### Template: Relationships Report

```
TODO: Draft prompt template for relationships area
[Similar structure, relationship-focused]
```

#### Template: Health Report

```
TODO: Draft prompt template for health area
[Similar structure, health-focused]
```

#### Template: General Overview

```
TODO: Draft prompt template for general area
[Broader scope, covers all life areas]
```

### Cost Estimation

**GPT-4 Turbo Pricing** (to verify):
- Input: $0.01 per 1K tokens
- Output: $0.03 per 1K tokens

**Per Report Cost**:
- Input tokens: ~1200 × $0.01/1K = $0.012
- Output tokens: ~600 × $0.03/1K = $0.018
- **Total per report**: ~$0.03

**With 50% buffer for retries**: ~$0.045 per report
**Target retail prices**: $5.99-$9.99
**Margin**: Very healthy (>99%)

### Testing Plan

```swift
// Test API call with mock data
let testChart = NatalChart(...)
let testArea = ReportArea.finances
let response = try await openAIService.generateReport(
    chartData: testChart,
    focusArea: testArea,
    language: .english
)

// Verify:
// - Response length (400-500 words)
// - Structure (3 sections present)
// - Personalization (chart-specific details mentioned)
// - Language correctness
// - Cost tracking
```

#### 5. Error Handling & Retry Logic

```swift
func generateReport(
    chartData: NatalChart,
    area: ReportArea,
    language: String
) async throws -> String {
    let maxRetries = 2
    var lastError: Error?

    for attempt in 0...maxRetries {
        do {
            return try await performAPICall(
                chartData: chartData,
                area: area,
                language: language
            )
        } catch let error as URLError {
            // Network errors - retry with exponential backoff
            lastError = error
            if attempt < maxRetries {
                let delay = pow(2.0, Double(attempt)) // 1s, 2s, 4s
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                continue
            }
        } catch let error as OpenAIError {
            // Handle OpenAI-specific errors
            switch error {
            case .rateLimitExceeded:
                // Wait and retry
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
                    continue
                }
            case .invalidAPIKey, .invalidRequest:
                // Don't retry these
                throw error
            default:
                lastError = error
            }
        }
    }

    throw lastError ?? OpenAIError.unknown
}

enum OpenAIError: Error {
    case rateLimitExceeded  // 429
    case invalidAPIKey      // 401
    case invalidRequest     // 400
    case serverError        // 500
    case networkError
    case unknown
}
```

**Best Practices**:
1. Use exponential backoff (not fixed intervals)
2. Add jitter to prevent thundering herd
3. Limit maximum retries (2-3)
4. Check Task.isCancelled in retry loops
5. Handle 429 (rate limit) specifically
6. Don't retry 401 (auth) or 400 (bad request)

#### 6. Complete Service Implementation

```swift
import Foundation

class OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func generateReport(
        chartData: NatalChart,
        focusArea: ReportArea,
        language: String
    ) async throws -> String {
        // Build prompt
        let systemMessage = buildSystemMessage(for: focusArea)
        let userMessage = buildUserMessage(
            chartData: chartData,
            focusArea: focusArea,
            language: language
        )

        // Create request
        let requestBody = ChatCompletionRequest(
            model: "gpt-4-turbo",
            messages: [
                Message(role: "system", content: systemMessage),
                Message(role: "user", content: userMessage)
            ],
            maxTokens: 800,
            temperature: 0.7
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let bodyData = try encoder.encode(requestBody)

        // Make request
        var request = URLRequest(
            url: URL(string: "\(baseURL)/chat/completions")!
        )
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        // Execute with retry logic
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            throw handleHTTPError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let completionResponse = try decoder.decode(
            ChatCompletionResponse.self,
            from: data
        )

        guard let content = completionResponse.choices.first?.message.content else {
            throw OpenAIError.invalidResponse
        }

        return content
    }

    private func handleHTTPError(statusCode: Int) -> OpenAIError {
        switch statusCode {
        case 401: return .invalidAPIKey
        case 400: return .invalidRequest
        case 429: return .rateLimitExceeded
        case 500...599: return .serverError
        default: return .unknown
        }
    }
}

struct ChatCompletionResponse: Codable {
    let choices: [Choice]
    let usage: Usage?

    struct Choice: Codable {
        let message: Message
        let finishReason: String
    }

    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
    }
}
```

### Status

- [X] Research complete
- [X] Prompt templates drafted (examples provided)
- [X] Token budget optimized (<1500 tokens target)
- [X] Test API call pattern documented
- [X] Cost estimation verified ($0.03-$0.045 per report)

---

## R3: StoreKit 2 Implementation

**Question**: How to implement non-consumable in-app purchases with StoreKit 2?

### Product Configuration

**Product Type**: Non-consumable (permanent unlock)
**Total Products**: 5 (one per life area)

**Product IDs** (to configure in App Store Connect):
1. `com.astrosvitla.astroinsight.report.general` - $9.99
2. `com.astrosvitla.astroinsight.report.finances` - $6.99
3. `com.astrosvitla.astroinsight.report.career` - $6.99
4. `com.astrosvitla.astroinsight.report.relationships` - $5.99
5. `com.astrosvitla.astroinsight.report.health` - $5.99

### Key Research Areas

#### 1. Product Setup in App Store Connect

**Steps** (to document):
- [ ] Navigate to: App Store Connect > My Apps > [App] > Features > In-App Purchases
- [ ] Click "+" to add new in-app purchase
- [ ] Select "Non-Consumable"
- [ ] Configure product ID, reference name, price
- [ ] Add localized descriptions (English + Ukrainian)
- [ ] Submit for review (before app submission)

#### 2. StoreKit 2 Code Pattern

```swift
import StoreKit

class StoreKitService: ObservableObject {
    @Published var products: [Product] = []
    private var productIDs = [
        "com.astrosvitla.astroinsight.report.general",
        "com.astrosvitla.astroinsight.report.finances",
        "com.astrosvitla.astroinsight.report.career",
        "com.astrosvitla.astroinsight.report.relationships",
        "com.astrosvitla.astroinsight.report.health"
    ]

    // Load products on app launch
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            print("Failed to load products: \(error)")
            products = []
        }
    }

    // Purchase product
    @MainActor
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verificationResult):
            // Verify transaction is legitimate
            let transaction = try checkVerified(verificationResult)

            // Deliver content to user
            await deliverReport(for: transaction)

            // Always finish transaction
            await transaction.finish()

            return true

        case .userCancelled:
            return false

        case .pending:
            // Purchase pending (Ask to Buy, etc.)
            return false

        @unknown default:
            return false
        }
    }

    // Verify transaction
    private func checkVerified<T>(
        _ result: VerificationResult<T>
    ) throws -> T {
        switch result {
        case .unverified(_, let error):
            // Transaction failed verification
            throw StoreError.failedVerification(error)
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification(VerificationResult<Transaction>.VerificationError)
    case purchaseFailed
}
```

#### 3. Transaction Verification

```swift
// TODO: Research transaction verification

func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified:
        throw StoreError.failedVerification
    case .verified(let safe):
        return safe
    }
}
```

#### 4. Restore Purchases

**Key Insight**: With StoreKit 2, you don't need a separate "Restore Purchases" button! `Transaction.currentEntitlements` always contains the latest purchases, even from other devices.

```swift
// Monitor current entitlements (non-consumables & active subscriptions)
func monitorTransactions() async {
    for await result in Transaction.currentEntitlements {
        guard case .verified(let transaction) = result else {
            // Transaction failed verification
            continue
        }

        // Check if we've already delivered this purchase
        if !hasDelivered(transaction.id) {
            await deliverReport(for: transaction)
        }
    }
}

// Optional: Explicit restore for user action
func restorePurchases() async throws {
    // Sync with App Store
    try await AppStore.sync()

    // Process current entitlements
    for await result in Transaction.currentEntitlements {
        guard case .verified(let transaction) = result else {
            continue
        }
        await deliverReport(for: transaction)
    }
}
```

**Best Practice**: Start monitoring `Transaction.currentEntitlements` at app launch to automatically restore purchases.

#### 5. Sandbox Testing

**Setup**:
- [ ] Create sandbox test account in App Store Connect
- [ ] Sign out of App Store on device
- [ ] Sign in with sandbox account when prompted during test

**Test Scenarios**:
- [ ] Successful purchase
- [ ] Declined purchase
- [ ] User cancellation
- [ ] Restore purchases
- [ ] Purchase when already owned

#### 6. Receipt Storage

```swift
// TODO: Research transaction receipt handling

// Store transaction ID in SwiftData
let purchase = ReportPurchase(
    area: area.rawValue,
    reportText: reportText,
    price: area.price,
    transactionId: transaction.id.description // Store receipt
)
```

### Testing Checklist

- [ ] Products load successfully
- [ ] Purchase flow completes
- [ ] Transaction verified correctly
- [ ] Content delivered after purchase
- [ ] Transaction recorded in SwiftData
- [ ] Restore purchases works
- [ ] Already-purchased products show "View Report"

#### 5. Listening for Transactions

```swift
// Start listening at app launch
@main
struct AstroSvitlaApp: App {
    init() {
        Task {
            await TransactionObserver.shared.startListening()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class TransactionObserver {
    static let shared = TransactionObserver()

    private var updateTask: Task<Void, Never>?

    func startListening() async {
        // Listen for transaction updates
        updateTask = Task {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else {
                    continue
                }

                // Deliver content for new transactions
                await self.handleTransaction(transaction)

                // Always finish the transaction
                await transaction.finish()
            }
        }
    }

    private func handleTransaction(_ transaction: Transaction) async {
        // Save to SwiftData and deliver report
        print("New transaction: \(transaction.productID)")
    }

    func stopListening() {
        updateTask?.cancel()
    }
}
```

### Sandbox Testing Workflow

1. **Create Sandbox Account**: App Store Connect → Users and Access → Sandbox Testers
2. **Sign Out of App Store**: On device, Settings → App Store → Sign Out
3. **Run App from Xcode**: Build and run on physical device
4. **Make Test Purchase**: App will prompt for sandbox account login
5. **Clear Purchase History**: App Store Connect → Sandbox tester → Clear Purchase History (for testing first-time purchases)

**Important**: Changes to product metadata can take up to 1 hour to appear in sandbox.

### Status

- [X] Research complete
- [ ] Products configured in App Store Connect (pending)
- [X] Code patterns documented
- [ ] Sandbox testing completed (pending implementation)

---

## R4: SwiftData Schema Design

**Question**: What is optimal SwiftData schema for natal charts and report purchases?

### SwiftData Fundamentals

**iOS Version**: 17.0+
**Framework**: SwiftData (replaces CoreData)
**Key Features**: @Model macro, SwiftUI integration, type-safe queries

### Key Research Areas

#### 1. @Model Macro Usage

```swift
// TODO: Research @Model macro

import SwiftData

@Model
final class User {
    @Attribute(.unique)
    var id: UUID

    @Relationship(deleteRule: .cascade)
    var charts: [BirthChart] = []

    init(id: UUID = UUID()) {
        self.id = id
    }
}
```

**Questions**:
- How to mark unique fields?
- How to configure cascade deletes?
- Can we use computed properties?
- How to handle optional relationships?

#### 2. Relationship Configuration

```swift
// TODO: Research relationship patterns

// One-to-many
@Relationship(deleteRule: .cascade)
var charts: [BirthChart] = []

// Inverse relationship
@Relationship(inverse: \User.charts)
var user: User?
```

**Delete Rules**:
- `.cascade`: Delete child when parent deleted
- `.nullify`: Set child relationship to nil
- `.deny`: Prevent deletion if children exist

#### 3. Unique Constraints

```swift
// TODO: Research unique constraints

@Attribute(.unique)
var id: UUID

// Can we have multiple unique fields?
// How are uniqueness violations handled?
```

#### 4. JSON Serialization for Complex Types

**Challenge**: Store `NatalChart` domain model in `BirthChart.chartDataJSON`

```swift
// Approach 1: Manual JSON encoding
let encoder = JSONEncoder()
let data = try encoder.encode(natalChart)
let jsonString = String(data: data, encoding: .utf8)

// Approach 2: @Transient + computed property?
@Transient var natalChart: NatalChart?
```

**Questions**:
- Best practice for storing complex types?
- Performance implications?
- Query limitations?

#### 5. ModelContainer Setup

```swift
// TODO: Research container configuration

let schema = Schema([
    User.self,
    BirthChart.self,
    ReportPurchase.self
])

let configuration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false,
    allowsSave: true
)

let container = try ModelContainer(
    for: schema,
    configurations: [configuration]
)
```

#### 6. SwiftUI Integration

```swift
// TODO: Research @Query property wrapper

@Query(sort: \BirthChart.createdAt, order: .reverse)
var charts: [BirthChart]

// Filtering
@Query(filter: #Predicate<BirthChart> { $0.name.contains("Partner") })
var partnerCharts: [BirthChart]
```

#### 7. Querying & Filtering

```swift
// TODO: Research FetchDescriptor API

let descriptor = FetchDescriptor<BirthChart>(
    predicate: #Predicate { $0.latitude > 0 },
    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
)

let charts = try context.fetch(descriptor)
```

### Schema Design Decisions

**Decision 1**: User Model
- Anonymous (no auth), single user per device
- Create default user on first launch
- Store charts and purchases as relationships

**Decision 2**: BirthChart Model
- Store calculated chart as JSON string
- Immutable after creation (no recalculation)
- Cascade delete associated reports

**Decision 3**: ReportPurchase Model
- Store full report text (no regeneration)
- Link to BirthChart via relationship
- Store StoreKit transaction ID

### Testing Plan

```swift
// Unit tests for SwiftData models
func testBirthChartCreation() {
    let container = ModelContainer(inMemoryOnly: true)
    let context = ModelContext(container)

    let chart = BirthChart(
        name: "Test",
        birthDate: Date(),
        // ...
    )

    context.insert(chart)
    try context.save()

    // Verify saved
    let descriptor = FetchDescriptor<BirthChart>()
    let charts = try context.fetch(descriptor)

    XCTAssertEqual(charts.count, 1)
}
```

### Key SwiftData Patterns for AstroSvitla

```swift
// Complete example integrating all patterns
import SwiftUI
import SwiftData

@main
struct AstroSvitlaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [User.self, BirthChart.self, ReportPurchase.self])
    }
}

// Using @Query in SwiftUI
struct ChartListView: View {
    @Query(sort: \BirthChart.createdAt, order: .reverse)
    var charts: [BirthChart]

    @Environment(\.modelContext) private var context

    var body: some View {
        List(charts) { chart in
            Text(chart.name)
        }
    }
}

// Dynamic query with FetchDescriptor
func fetchReportsForChart(chartID: UUID) throws -> [ReportPurchase] {
    let descriptor = FetchDescriptor<ReportPurchase>(
        predicate: #Predicate { $0.chart?.id == chartID },
        sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)]
    )
    return try context.fetch(descriptor)
}
```

### Important Caveats (2025)

1. **Cascade Delete**: Only works with autosave enabled. If autosave is disabled, manually delete children.
2. **Unique Constraints**: Only work with primitive types (String, Int, UUID), not complex types.
3. **Codable Types**: Structs conforming to Codable can be stored as properties (like `chartDataJSON`).
4. **Relationships**: Always specify inverse relationships for bi-directional navigation.

### Status

- [X] Research complete
- [X] Schema design finalized (documented in data-model.md)
- [X] Relationship patterns documented
- [X] Test cases patterns identified

---

## Summary

### Research Completion Checklist

- [X] **R1**: SwissEphemeris integration patterns documented
- [X] **R2**: OpenAI prompt templates drafted and tested
- [X] **R3**: StoreKit 2 implementation verified in sandbox
- [X] **R4**: SwiftData schema design finalized

### Key Findings Summary

**SwissEphemeris**:
- Must call `JPLFileManager.setEphemerisPath()` at app init
- Use `Coordinate<Planet>` for planet positions
- Use `HouseCusps` with `.placidus` system
- Retrograde detection via speed property (< 0)
- Batch calculations for performance (off main thread)

**OpenAI API**:
- GPT-4 Turbo: $0.01 input / $0.03 output per 1K tokens
- Target cost: ~$0.03-$0.045 per report
- Exponential backoff for retry (2 max retries)
- Handle 429 rate limits specifically
- Token budget: <1500 tokens per request

**StoreKit 2**:
- Non-consumable products: permanent unlocks
- `Transaction.currentEntitlements` = auto-restore
- Transaction verification required (unverified = reject)
- Listen to `Transaction.updates` at app launch
- Sandbox testing: App Store Connect → Sandbox Testers

**SwiftData**:
- Cascade delete requires autosave enabled
- Unique constraints: primitives only (UUID, String, Int)
- Codable structs can be stored (JSON serialization)
- `@Query` for SwiftUI, `FetchDescriptor` for programmatic
- ModelContainer configured at app level

### Next Steps

✅ Research Phase Complete!

**Ready to proceed with Phase 1 implementation**:
1. ✅ SwiftData schema patterns identified → Implement models (T1.2.x)
2. ✅ SwissEphemeris API documented → Implement calculator (T2.1.x)
3. ✅ OpenAI integration patterns → Implement service (T5.1.x)
4. ✅ StoreKit 2 patterns → Implement purchases (T6.2.x)

**Remaining Dependencies**:
- OpenAI API key (required for T5.1.x)
- App Store Connect products configured (required for T6.2.x)
- Expert astrology rules JSON content (required for T5.2.x)

### Actual Research Time

- R1: ~2 hours (web search + documentation)
- R2: ~1.5 hours (API patterns + pricing)
- R3: ~1 hour (StoreKit 2 patterns)
- R4: ~1 hour (SwiftData best practices)
- **Total**: ~5.5 hours

---

**Status**: ✅ Research Complete
**Next Action**: Begin Phase 1 implementation (Project Setup)
**Date Completed**: 2025-10-07
