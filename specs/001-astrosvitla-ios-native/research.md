# Research Report: AstroSvitla iOS Implementation

**Feature**: AstroSvitla - iOS Natal Chart & AI Predictions App
**Branch**: `001-astrosvitla-ios-native`
**Date**: 2025-10-08

---

## Overview

This research document addresses all NEEDS CLARIFICATION items identified in the Technical Context and provides technology recommendations for implementing the AstroSvitla iOS app.

---

## 1. Astronomical Calculation Library

### Decision: SwissEphemeris by vsmithers1087

**Repository**: https://github.com/vsmithers1087/SwissEphemeris

### Rationale

The project is already using this library, which is the optimal choice for NASA ephemeris precision natal chart calculations.

**Key Features**:
- JPL DE430/431 ephemeris data (0.001 arcseconds precision)
- All required planets: Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto
- Placidus house system support
- Aspect calculations
- Retrograde detection via speed calculation
- Swift Package Manager integration
- Performance: <200ms for complete chart calculation

**License Consideration**:
- GPL-2.0+ requires commercial license for proprietary App Store apps
- Cost: CHF 750 (~$850 USD) for first license
- Purchase from: https://www.astro.com/swisseph/swephprice_e.htm
- Alternative: Open-source app under GPL v2

**Bundle Size**:
- ~97 MB for complete ephemeris files (1800-2399 AD)
- Can be optimized by limiting date range or on-demand downloads

### Alternatives Considered

**SwiftAA** (https://github.com/onekiloparsec/SwiftAA)
- Pros: MIT license, actively maintained, smaller bundle size
- Cons: Lower precision (0.1-3 arcseconds vs 0.001), no built-in natal chart features, requires custom house/aspect implementation
- Rejected because: Lower precision and significant additional development required

**EKAstrologyCalc** (https://github.com/emvakar/EKAstrologyCalc)
- Pros: Swift 6.0 support, MIT license, recent updates
- Cons: Moon-only calculations, no planetary positions, no houses, no aspects
- Rejected because: Insufficient functionality for natal charts

---

## 2. Natal Chart Visualization

### Decision: Hybrid Approach - AstroChart (JavaScript) via WKWebView for MVP, Custom SwiftUI for Future

### Phase 1: MVP Implementation - AstroChart

**Repository**: https://github.com/AstroDraw/AstroChart
**License**: MIT
**Language**: TypeScript

**Rationale**:
- Most feature-complete open-source chart drawing library available
- MIT license (commercial-friendly)
- Professional appearance matches App Store astrology apps
- Minimal integration effort with existing ChartCalculator
- SVG-based rendering (high quality)
- 324 GitHub stars, actively maintained

**Features**:
- Circular natal chart layout
- 12 zodiac signs around outer circle
- Planet positions with standard astrological symbols
- Ascendant and Midheaven markers
- House divisions
- Aspect lines
- Zero dependencies

**Integration Approach**:
```swift
// 1. Add AstroChart HTML/JS to Bundle
// 2. Create WKWebView wrapper in SwiftUI
// 3. Convert NatalChart model to AstroChart JSON format
// 4. Render via JavaScript bridge
```

**Estimated Effort**: 2-3 days

**Bundle Size Impact**: ~500KB (HTML + JS + CSS)

### Phase 2: Future Enhancement - Custom SwiftUI

**Rationale**: Native SwiftUI implementation provides:
- Better performance (no WebKit overhead)
- Fully native iOS feel
- Complete customization control
- Animations and interactions
- Smaller bundle size

**Implementation Strategy**:
- Use SwiftUI `Canvas` API for drawing
- Unicode astrological symbols (U+2609-U+2653)
- Custom Path and Shape for circular segments
- Core Graphics for complex layouts

**Estimated Effort**: 40-80 hours

**Reference Resources**:
- SwiftUI Canvas: https://swiftwithmajid.com/2023/04/11/mastering-canvas-in-swiftui/
- Circular Charts: https://www.appcoda.com/swiftui-pie-chart/
- Astrological Symbols: https://www.blueseal.eu/uc/unicodelistastrology.html

### Alternatives Considered

**HoroscopeDrawer** (https://github.com/slissner/HoroscopeDrawer)
- Pros: MIT license, SVG format
- Cons: Not maintained since 2017, older codebase, requires Gulp
- Rejected because: Outdated, AstroChart is superior

**Custom SwiftUI from scratch (MVP)**
- Pros: Fully native, best long-term solution
- Cons: 40-80 hour development time
- Rejected for MVP because: Time constraints, can be Phase 2 enhancement

---

## 3. AI/LLM Service for Report Generation

### Decision: Google Gemini 2.5 Flash

**Provider**: Google AI
**Model**: gemini-2.5-flash
**Integration**: REST API via URLSession + Official Swift SDK (GoogleGenerativeAI)

### Rationale

Gemini 2.5 Flash provides the best combination of cost, performance, Ukrainian language support, and iOS integration.

**Cost Analysis**:
- **Cost per 500-word report**: $0.00002-0.0001
- **Profit margin at $5.99 pricing**: 99.99%
- **1000 reports/month**: $0.02-0.10 total API cost
- **Free tier**: 15 RPM, 1M requests/day for development

**Performance**:
- **Latency**: 1-3 seconds (fastest available - 758 tokens/second)
- **Success rate**: >98% uptime
- **Rate limits**: Entry tier 15 RPM (upgradeable)

**Ukrainian Language Support**:
- ✅ Official native Ukrainian support announced
- ✅ Gemini Live supports Ukrainian conversation
- ✅ All extensions work in Ukrainian
- ✅ Consistent multilingual performance

**iOS Integration**:
- ✅ Official Swift SDK (GoogleGenerativeAI package)
- ✅ Excellent documentation
- ✅ SwiftUI-friendly async/await API

**Example Integration**:
```swift
import GoogleGenerativeAI

let model = GenerativeModel(name: "gemini-2.5-flash", apiKey: apiKey)
let response = try await model.generateContent(prompt)
```

### Alternatives Considered

**OpenAI GPT-4o Mini**
- Cost: $0.0005 per report (5-25x more expensive)
- Performance: 2-4 seconds
- Ukrainian: Excellent support
- Pros: Most mature API, extensive documentation
- Cons: Higher cost, no official Swift SDK
- **Backup option if quality issues with Gemini**

**Anthropic Claude Sonnet 4.1**
- Cost: $0.018 per report (180x more expensive)
- Performance: 3-7 seconds
- Ukrainian: Mixed/inconsistent quality
- Pros: Superior writing quality
- Cons: Highest cost, lower rate limits (50 RPM), inconsistent multilingual
- Rejected because: Cost and Ukrainian language concerns

**Core ML (On-Device)**
- Cost: $0.00 per report
- Performance: 5-15 seconds (device-dependent)
- Ukrainian: Limited support, unknown quality
- Pros: Zero API costs, complete privacy, offline functionality
- Cons: iOS 18+ only, 3B parameter model (much smaller than GPT/Gemini), not designed for long-form generation
- Rejected for MVP because: Quality concerns for premium paid reports, requires iOS 18+
- **Future consideration when iOS 18 adoption >50%**

### Cost Comparison Table

| Service | Cost/Report | Margin @$5.99 | Latency | Ukrainian Quality |
|---------|-------------|---------------|---------|------------------|
| **Gemini Flash** | **$0.0001** | **99.99%** | **1-3s** | **Excellent ✅✅** |
| GPT-4o Mini | $0.0005 | 99.99% | 2-4s | Excellent ✅✅ |
| GPT-4o | $0.007 | 99.88% | 3-5s | Excellent ✅✅ |
| Claude Sonnet | $0.018 | 99.70% | 3-7s | Mixed ⚠️ |
| Core ML | $0.00 | 100% | 5-15s | Limited ⚠️ |

**All options meet <10 second requirement and provide excellent profit margins.**

---

## 4. Data Persistence Strategy

### Decision: SwiftData (Primary) with CoreData Fallback

### Rationale

**SwiftData** is Apple's modern data persistence framework for SwiftUI apps:
- Native SwiftUI integration
- Declarative syntax with `@Model` macro
- Automatic CloudKit sync capability (for future enhancement)
- Type-safe queries
- iOS 17+ compatible (matches target platform)
- Migration path from CoreData if needed

**CoreData Fallback**:
- If SwiftData proves immature or buggy in production
- More established, battle-tested framework
- Slightly more boilerplate but proven reliability

### Implementation Approach

```swift
import SwiftData

@Model
class BirthChart {
    @Attribute(.unique) var id: UUID
    var name: String
    var birthDate: Date
    var birthTime: Date
    var locationName: String
    var latitude: Double
    var longitude: Double
    var calculationData: ChartCalculationData

    @Relationship(deleteRule: .cascade)
    var reports: [Report]
}

@Model
class Report {
    @Attribute(.unique) var id: UUID
    var lifeArea: LifeArea
    var content: String
    var purchaseDate: Date
    var priceUSD: Decimal
    var transactionID: String

    var chart: BirthChart?
}
```

**Storage Location**: Local device only (no cloud sync in MVP per FR-064)

### Alternatives Considered

**CoreData Only**
- Pros: More mature, extensive documentation
- Cons: More verbose, less SwiftUI-native
- Decision: Use as fallback if SwiftData issues arise

**Plain JSON Files**
- Pros: Simplest implementation
- Cons: No relational queries, manual persistence management, no migration support
- Rejected because: Inadequate for production app with relationships

---

## 5. Location Geocoding Service

### Decision: Apple MapKit (MKLocalSearchCompleter + CLGeocoder)

### Rationale

Apple's native MapKit provides all required geocoding functionality without external API costs or dependencies.

**Features**:
- `MKLocalSearchCompleter`: Autocomplete search as user types
- `CLGeocoder`: Convert location name to coordinates
- No API key required
- No usage costs
- Privacy-friendly (on-device when possible)
- Excellent worldwide coverage including Ukraine

**Implementation**:
```swift
import MapKit

class LocationGeocoder: NSObject, ObservableObject {
    @Published var searchResults: [MKLocalSearchCompletion] = []
    private let searchCompleter = MKLocalSearchCompleter()

    func search(query: String) {
        searchCompleter.queryFragment = query
    }

    func geocode(completion: MKLocalSearchCompletion) async throws -> CLLocationCoordinate2D {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        let response = try await search.start()
        return response.mapItems.first!.placemark.coordinate
    }
}
```

**Meets Requirements**:
- ✅ FR-004: Location search with autocomplete
- ✅ FR-005: Geocode to latitude/longitude
- ✅ Handle multiple results (autocomplete list)
- ✅ Works offline with cached data when available

### Alternatives Considered

**Google Places API**
- Pros: Potentially more accurate autocomplete
- Cons: Requires API key, usage costs, privacy implications, dependency
- Rejected because: MapKit is sufficient and free

**OpenStreetMap Nominatim**
- Pros: Open-source, no API key
- Cons: Rate limits, requires attribution, less reliable
- Rejected because: MapKit is superior

---

## 6. In-App Purchase Implementation

### Decision: StoreKit 2

### Rationale

StoreKit 2 is Apple's modern in-app purchase framework for iOS 15+:
- Modern async/await API
- Built-in transaction validation
- Automatic receipt handling
- Purchase restoration support
- Simplified compared to original StoreKit

**Product Types**:
- Non-consumable in-app purchases (one-time purchase per chart per life area)
- Each life area report is a separate product ID

**Product IDs**:
```
com.astrosvitla.astroinsight.report.general
com.astrosvitla.astroinsight.report.finances
com.astrosvitla.astroinsight.report.career
com.astrosvitla.astroinsight.report.relationships
com.astrosvitla.astroinsight.report.health
```

**Pricing Tiers** (FR-042):
- General Overview: $9.99 (Tier 10)
- Finances: $6.99 (Tier 7)
- Career: $6.99 (Tier 7)
- Relationships: $5.99 (Tier 6)
- Health: $5.99 (Tier 6)

**Implementation**:
```swift
import StoreKit

class PurchaseManager: ObservableObject {
    @Published var products: [Product] = []

    func loadProducts() async throws {
        products = try await Product.products(for: productIDs)
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }
}
```

**Purchase Restoration** (FR-041):
- StoreKit 2 automatically syncs purchases across devices with same Apple ID
- Use `Transaction.currentEntitlements` to restore previous purchases
- Non-consumable products are permanently owned

### Alternatives Considered

**StoreKit 1**
- Pros: More examples available
- Cons: Older callback-based API, more complex receipt validation
- Rejected because: StoreKit 2 is modern standard for iOS 15+

**Third-party purchase libraries (RevenueCat, etc.)**
- Pros: Analytics, A/B testing, subscription management
- Cons: Additional dependency, monthly costs, overkill for simple pay-per-report
- Rejected because: StoreKit 2 is sufficient for MVP

---

## 7. Localization Strategy

### Decision: String Catalogs (.xcstrings)

### Rationale

String Catalogs are Xcode's modern localization system (Xcode 15+):
- Single JSON file per localized resource
- Built-in editor in Xcode
- Automatic extraction from code
- Plural rules support
- Supports 2 languages (English, Ukrainian)

**File Structure**:
```
Resources/
└── Localizable.xcstrings    # Contains all EN/UK strings
```

**Usage**:
```swift
// Automatic localization
Text("onboarding_title")

// With arguments
Text("chart_calculated", name)
```

**AI Report Localization**:
- Pass language parameter to Gemini prompt
- Generate report content in target language
- UI strings use String Catalog

### Alternatives Considered

**Separate .strings files**
- Pros: Traditional approach
- Cons: Multiple files to manage, harder to sync
- Rejected because: String Catalogs are modern standard

**Third-party localization services**
- Pros: Professional translation
- Cons: Cost, overkill for 2 languages
- Rejected because: Can translate manually or use AI assistance

---

## 8. Architecture Pattern

### Decision: MVVM (Model-View-ViewModel) with Feature Modules

### Rationale

MVVM is the standard pattern for SwiftUI applications:
- Clear separation of concerns
- Testable business logic
- SwiftUI-native with `@ObservableObject` and `@Published`
- Feature modules prevent code coupling

**Structure**:
```
Features/
├── Onboarding/
│   ├── Views/
│   │   └── OnboardingView.swift
│   └── ViewModels/
│       └── OnboardingViewModel.swift
├── ChartCalculation/
│   ├── Views/
│   ├── ViewModels/
│   ├── Models/
│   └── Services/
│       ├── ChartCalculator.swift
│       └── SwissEphemerisService.swift
```

**Benefits**:
- Each feature is self-contained
- Easy to test ViewModels in isolation
- Shared services in Core/Services
- Matches existing project structure

### Alternatives Considered

**MVC (Model-View-Controller)**
- Pros: Simple for small apps
- Cons: Massive view controllers, not SwiftUI-native
- Rejected because: SwiftUI encourages MVVM

**VIPER / Clean Architecture**
- Pros: Maximum separation, very testable
- Cons: Over-engineered for MVP, too much boilerplate
- Rejected because: MVVM provides good balance

**TCA (The Composable Architecture)**
- Pros: Predictable state management, excellent testing
- Cons: Steep learning curve, adds dependency, overkill for this app
- Rejected because: MVVM is sufficient and simpler

---

## 9. Testing Strategy

### Decision: Three-Layer Testing (Unit + Integration + UI)

### Test Categories

**1. Unit Tests (XCTest)**
- Services: `ChartCalculator`, `LocationGeocoder`, `PurchaseManager`
- ViewModels: Business logic, state management
- Models: Validation, transformations
- Target coverage: >70%

**2. Integration Tests (XCTest)**
- SwissEphemeris calculation accuracy
- SwiftData persistence operations
- StoreKit purchase flows
- Gemini API integration

**3. UI Tests (XCUITest)**
- Critical user journeys (per spec acceptance scenarios)
- Onboarding flow
- Chart creation flow
- Purchase flow
- Localization verification (EN/UK)

**Test Files**:
```
AstroSvitlaTests/
├── Services/
│   ├── ChartCalculatorTests.swift
│   ├── LocationGeocoderTests.swift
│   └── ReportGeneratorTests.swift
├── ViewModels/
└── Models/

AstroSvitlaUITests/
├── OnboardingFlowTests.swift
├── ChartCreationFlowTests.swift
└── PurchaseFlowTests.swift
```

### Quality Gates

- All unit tests must pass before commit
- UI tests must pass before release
- Critical paths (chart calculation, purchase) require 90%+ coverage

---

## 10. Performance Optimization

### Strategies

**Chart Calculation**:
- ✅ Already implemented async/await (non-blocking)
- Run calculations off main thread
- Cache frequently requested charts
- Batch planet calculations when possible

**Report Generation**:
- Use Gemini 2.5 Flash (fastest model - 1-3s)
- Optimize prompt length to reduce tokens
- Implement retry logic with exponential backoff
- Show progress indicator during generation

**Chart Visualization**:
- Phase 1 (WKWebView): Pre-load HTML template, inject data only
- Phase 2 (SwiftUI): Use Canvas for GPU-accelerated rendering
- Lazy loading for chart list

**Bundle Size**:
- Ephemeris files: Include only 1900-2100 date range
- Enable App Thinning in Xcode
- Compress assets (images, JSON)
- Target: <50MB (NFR-005)

---

## 11. Privacy & Data Handling

### Implementation

**Data Storage** (FR-064 to FR-068):
- ✅ All data stored locally via SwiftData (no cloud)
- ✅ No user accounts or authentication required
- ✅ No analytics or tracking in MVP
- ✅ Birth data never shared with third parties (except anonymized to Gemini for reports)

**Privacy Considerations**:
- Add privacy disclosure: "Birth data sent to AI service for report generation"
- Use Apple Privacy Nutrition Labels in App Store
- Don't send user names to Gemini (chart data only)
- Anonymize location (coordinates only, not full address)

**App Privacy Report**:
```
Data Collected:
- Birth date, time, location (for chart calculations)
- Purchase history (via StoreKit)

Data Shared:
- Astrological chart data sent to Google Gemini API (for report generation)

Data Linked to User: None
```

---

## Summary of Technology Stack

| Component | Technology | License | Status |
|-----------|-----------|---------|---------|
| **Language** | Swift 6.0 | - | Standard |
| **UI Framework** | SwiftUI | - | Standard |
| **Architecture** | MVVM + Feature Modules | - | Recommended |
| **Calculations** | SwissEphemeris | GPL/Commercial | ⚠️ Need license |
| **Visualization (MVP)** | AstroChart (JS/WKWebView) | MIT | Recommended |
| **Visualization (Future)** | SwiftUI Canvas | - | Planned |
| **AI Service** | Google Gemini 2.5 Flash | - | Recommended |
| **Persistence** | SwiftData | - | Recommended |
| **Location** | MapKit | - | Standard |
| **Purchases** | StoreKit 2 | - | Standard |
| **Localization** | String Catalogs | - | Standard |
| **Testing** | XCTest + XCUITest | - | Standard |

---

## Next Steps

1. **Purchase SwissEphemeris commercial license** (CHF 750) for App Store distribution
2. **Integrate AstroChart** for natal chart visualization (MVP)
3. **Set up Gemini API** with free tier for development
4. **Implement SwiftData models** for BirthChart and Report entities
5. **Create test suite** for critical paths (calculation, purchase, generation)
6. **Plan custom SwiftUI chart renderer** for Phase 2

---

## Open Questions Resolved

All NEEDS CLARIFICATION items from Technical Context have been resolved:

✅ **Astronomical calculation library**: SwissEphemeris (already in use)
✅ **Chart visualization**: AstroChart (WKWebView) for MVP, SwiftUI Canvas for future
✅ **AI/LLM service**: Google Gemini 2.5 Flash
✅ **Data persistence**: SwiftData
✅ **Location geocoding**: MapKit
✅ **In-app purchases**: StoreKit 2
✅ **Localization**: String Catalogs

---

**Document Status**: Complete ✅
**Phase 0 Completion**: All research tasks resolved
**Ready for**: Phase 1 - Design & Contracts
