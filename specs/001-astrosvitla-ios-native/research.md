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
**License**: GPL (verify compatibility)
**iOS Support**: iOS 12.0+

### Key APIs to Research

#### 1. Initialization
```swift
// TODO: Research initialization pattern
// - How to set ephemeris data path?
// - Required ephemeris files (sepl_18.se1, etc.)?
// - Error handling for missing files?
```

#### 2. Planet Position Calculation
```swift
// TODO: Research planet calculation
// - Function signature for planet position?
// - How to specify date/time?
// - How to get longitude, latitude for planet?
// - Retrograde detection method?
```

#### 3. House Calculation (Placidus System)
```swift
// TODO: Research house calculation
// - Function for house cusps?
// - Parameters: date, time, latitude, longitude?
// - How to specify house system (Placidus)?
// - Returns array of 12 house cusps?
```

#### 4. Aspect Calculation
```swift
// TODO: Research aspect calculation
// - Built-in aspect calculation?
// - Or manual calculation from planet longitudes?
// - Orb tolerance parameters?
```

#### 5. Timezone Conversion
```swift
// TODO: Research timezone handling
// - Convert local time to UTC?
// - Convert to Julian Day Number?
// - DST handling?
```

### Research Tasks

- [ ] Clone repository and review source code
- [ ] Find Swift usage examples
- [ ] Test basic planet calculation with known birth data
- [ ] Verify accuracy against professional astrology software
- [ ] Document complete API usage pattern
- [ ] Create Swift wrapper/service design

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

### Status

- [ ] Research complete
- [ ] API patterns documented
- [ ] Test calculations verified
- [ ] Wrapper design approved

---

## R2: OpenAI GPT-4 API Integration

**Question**: What is optimal approach for GPT-4 integration for personalized report generation?

### API Documentation

**Base URL**: `https://api.openai.com/v1`
**Endpoint**: `/chat/completions`
**Model**: `gpt-4-turbo-preview`
**Authentication**: Bearer token (API key)

### Key Research Areas

#### 1. Authentication & Rate Limiting

```swift
// TODO: Research authentication
// - How to include API key in request?
// - Rate limit headers to monitor?
// - How to handle 429 (rate limit) errors?
```

**Rate Limits** (to research):
- Requests per minute: ?
- Tokens per minute: ?
- Cost per 1K tokens: ?

#### 2. Request Format

```swift
// TODO: Research request structure
struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [Message]
    let max_tokens: Int
    let temperature: Double
    // Other parameters?
}

struct Message: Codable {
    let role: String // "system", "user", "assistant"
    let content: String
}
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

### Status

- [ ] Research complete
- [ ] Prompt templates drafted
- [ ] Token budget optimized
- [ ] Test API call successful
- [ ] Cost estimation verified

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
// TODO: Research StoreKit 2 API

import StoreKit

// Load products
let products = try await Product.products(for: [
    "com.astrosvitla.astroinsight.report.general",
    // ... other product IDs
])

// Purchase product
let result = try await product.purchase()

// Handle result
switch result {
case .success(let verification):
    // Verify transaction
    let transaction = try checkVerified(verification)
    // Deliver content
    await deliverReport(transaction)
    // Finish transaction
    await transaction.finish()

case .userCancelled:
    // User cancelled purchase

case .pending:
    // Purchase pending (e.g., Ask to Buy)

@unknown default:
    break
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

```swift
// TODO: Research restore purchases flow

// Restore all transactions
for await result in Transaction.currentEntitlements {
    let transaction = try checkVerified(result)
    // Re-deliver content if not already delivered
}
```

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

### Status

- [ ] Research complete
- [ ] Products configured in App Store Connect
- [ ] Code patterns documented
- [ ] Sandbox testing completed

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

### Status

- [ ] Research complete
- [ ] Schema design finalized
- [ ] Relationship patterns documented
- [ ] Test cases written

---

## Summary

### Research Completion Checklist

- [ ] **R1**: SwissEphemeris integration patterns documented
- [ ] **R2**: OpenAI prompt templates drafted and tested
- [ ] **R3**: StoreKit 2 implementation verified in sandbox
- [ ] **R4**: SwiftData schema design finalized

### Next Steps

Once all research tasks complete:
1. Update `data-model.md` with finalized schema
2. Update `plan.md` with specific API patterns
3. Begin Phase 1 implementation
4. Create proof-of-concept for each integration

### Estimated Research Time

- R1: 4-6 hours
- R2: 4-6 hours
- R3: 3-4 hours
- R4: 2-3 hours
- **Total**: 13-19 hours (1.5-2.5 days)

---

**Status**: 🔴 Research Not Started
**Next Action**: Assign research tasks to developers
**Target Completion**: End of Week 1, Day 2
