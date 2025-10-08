# Implementation Plan: AstroSvitla - iOS Natal Chart & AI Predictions App

**Feature**: 001-astrosvitla-ios-native
**Spec**: [spec.md](./spec.md)
**Constitution**: [/memory/constitution.md](/memory/constitution.md)
**Created**: 2025-10-07
**Status**: Draft

---

## Executive Summary

Building native iOS astrology app with accurate natal chart calculations and AI-powered personalized predictions. App uses pay-per-report monetization model where users purchase individual life area reports ($5.99-$9.99) instead of subscriptions. Core technical approach: SwiftUI + SwiftData + SwissEphemeris for calculations + OpenAI GPT-4 for report generation + StoreKit 2 for payments. Bilingual support (English/Ukrainian). Offline-first architecture with local data persistence.

### Technical Context from User

Tech stack specified in PRD:
- **Platform**: iOS 17+ native (iPhone only, portrait orientation)
- **UI Framework**: SwiftUI (modern Apple native patterns)
- **Persistence**: SwiftData (Apple's modern replacement for CoreData)
- **Architecture**: MVVM + Clean Architecture
- **Chart Calculations**: SwissEphemeris library (vsmithers1087/SwissEphemeris via SPM)
- **AI Integration**: OpenAI GPT-4 API for report generation
- **Purchases**: StoreKit 2 for in-app purchases
- **Localization**: English (primary) + Ukrainian (secondary)
- **Geocoding**: CoreLocation framework

---

## Constitutional Alignment

### Article II: SwiftUI & SwiftData Native ✅
- Using SwiftUI for all UI (no UIKit)
- Using SwiftData for persistence (modern Apple pattern)
- Structured concurrency (async/await) for networking

### Article III: Test-Driven Reliability ✅
- TDD approach: tests before implementation
- Unit tests for chart calculations
- Integration tests for AI report generation
- Snapshot tests for UI components

### Article IV: Performance & Battery Stewardship ✅
- Chart calculation budget: <3 seconds
- Report generation budget: <10 seconds
- App launch budget: <2 seconds
- 60 FPS UI interactions
- Offline-first architecture (minimal network usage)

### Article V: Accessible Astronomy for All ✅
- High contrast mode support
- Bilingual: English + Ukrainian
- Color-safe palettes

---

## Phase 0: Research & Validation

### Research Tasks

#### R1: SwissEphemeris Integration
**Question**: How to integrate SwissEphemeris library in Swift for accurate astronomical calculations?

**Findings Required**:
- Library SPM package URL: https://github.com/vsmithers1087/SwissEphemeris
- API for calculating planetary positions
- House calculation methods (Placidus system)
- Aspect calculation capabilities
- Retrograde motion detection
- UTC timezone handling

**Research Output**: Document in `research.md` with code examples

#### R2: OpenAI API Best Practices
**Question**: What is optimal approach for GPT-4 integration for personalized report generation?

**Findings Required**:
- API authentication and rate limiting
- Prompt engineering for astrological interpretations
- Token cost optimization (target <1500 tokens per report)
- Error handling and retry strategies
- Streaming vs batch responses
- Context window management for expert rules

**Research Output**: Document in `research.md` with prompt templates

#### R3: StoreKit 2 Implementation
**Question**: How to implement non-consumable in-app purchases with StoreKit 2?

**Findings Required**:
- Product configuration in App Store Connect
- Transaction verification
- Receipt validation
- Restore purchases mechanism
- Sandbox testing workflow
- Error handling for declined payments

**Research Output**: Document in `research.md` with code examples

#### R4: SwiftData Schema Design
**Question**: What is optimal SwiftData schema for natal charts and report purchases?

**Findings Required**:
- @Model macro usage
- Relationship configuration (@Relationship)
- Unique constraints (@Attribute(.unique))
- Cascade delete rules
- JSON serialization for complex chart data
- ModelContainer setup

**Research Output**: Document in `data-model.md`

---

## Phase 1: Core Foundation

### P1.1: Project Setup & Configuration

**Goal**: Initialize Xcode project with proper structure and dependencies

**Tasks**:
1. Create new iOS App project (SwiftUI, iOS 17.0+)
2. Configure project settings:
   - Product Name: AstroSvitla
   - Organization Identifier: com.astrosvitla
   - Bundle ID: com.astrosvitla.astroinsight
   - Portrait orientation only
   - Dark Mode: Yes
3. Add Swift Package Dependencies:
   - SwissEphemeris: `https://github.com/vsmithers1087/SwissEphemeris`
4. Create folder structure:
   ```
   AstroSvitla/
   ├── App/
   │   ├── AstroSvitlaApp.swift
   │   └── Config.swift (gitignored)
   ├── Core/
   │   ├── Navigation/
   │   ├── Networking/
   │   ├── Storage/
   │   └── Extensions/
   ├── Models/
   │   ├── SwiftData/
   │   └── Domain/
   ├── Features/
   │   ├── Onboarding/
   │   ├── ChartInput/
   │   ├── ChartCalculation/
   │   ├── ChartVisualization/
   │   ├── AreaSelection/
   │   ├── ReportGeneration/
   │   └── Purchase/
   ├── Resources/
   │   ├── Assets.xcassets/
   │   ├── AstrologyRules/ (JSON files)
   │   └── Localizations/
   │       ├── en.lproj/
   │       └── uk.lproj/
   └── Shared/
       ├── Components/
       └── Utilities/
   ```
5. Create `.gitignore` with `Config.swift` excluded
6. Create `Config.swift.example` template for API keys

**Testing**: Project builds successfully, no warnings

### P1.2: SwiftData Models

**Goal**: Define persistent data models for charts and reports

**Tasks**:
1. Create `User.swift` model (anonymous device user)
2. Create `BirthChart.swift` model with:
   - Basic info: name, birthDate, birthTime, latitude, longitude, locationName
   - Calculated data: chartDataJSON (serialized)
   - Relationships: many ReportPurchases
3. Create `ReportPurchase.swift` model with:
   - Report data: area, reportText, generatedAt
   - Purchase info: price, transactionId
   - Relationships: belongs to BirthChart
4. Setup `ModelContainer` in App struct
5. Create sample data generators for testing

**Testing**:
- Unit tests for model creation
- Relationship tests (cascade deletes)
- JSON serialization tests

**Output**: `data-model.md` documenting schema

### P1.3: Domain Models

**Goal**: Define non-persistent business logic models

**Tasks**:
1. Create `NatalChart.swift` (calculated chart structure):
   ```swift
   struct NatalChart {
       let birthDate: Date
       let latitude: Double
       let longitude: Double
       let planets: [Planet]
       let houses: [House]
       let aspects: [Aspect]
   }
   ```
2. Create `Planet.swift`:
   ```swift
   struct Planet {
       let name: PlanetType
       let longitude: Double
       let sign: ZodiacSign
       let house: Int
       let isRetrograde: Bool
   }
   ```
3. Create `House.swift`:
   ```swift
   struct House {
       let number: Int
       let cusp: Double
       let sign: ZodiacSign
   }
   ```
4. Create `Aspect.swift`:
   ```swift
   struct Aspect {
       let planet1: PlanetType
       let planet2: PlanetType
       let type: AspectType
       let orb: Double
   }
   ```
5. Create enums: `PlanetType`, `ZodiacSign`, `AspectType`

**Testing**: Unit tests for domain model initialization

---

## Phase 2: Chart Calculation Engine

### P2.1: SwissEphemeris Wrapper

**Goal**: Create Swift wrapper around SwissEphemeris C library

**Tasks**:
1. Create `SwissEphemerisService.swift`:
   - Initialize ephemeris data path
   - Calculate planet positions for given date/time/location
   - Calculate house cusps (Placidus system)
   - Calculate aspects between planets
   - Detect retrograde motion
2. Implement timezone conversion (local time → UTC → Julian Day)
3. Handle ephemeris file loading and errors
4. Create comprehensive unit tests with known chart data

**Testing**:
- Test against reference chart (e.g., known celebrity birth data)
- Verify accuracy matches professional astrology software
- Edge case testing (midnight births, DST transitions, date line)

**Acceptance**: Calculations match reference within 0.1 degree accuracy

### P2.2: Chart Calculator

**Goal**: High-level service for complete natal chart calculation

**Tasks**:
1. Create `ChartCalculator.swift`:
   ```swift
   class ChartCalculator {
       func calculate(
           birthDate: Date,
           birthTime: Date,
           latitude: Double,
           longitude: Double
       ) throws -> NatalChart
   }
   ```
2. Orchestrate SwissEphemeris calls for all planets
3. Calculate all 12 houses
4. Calculate major aspects (conjunction, opposition, square, trine, sextile)
5. Determine zodiac signs for planets and house cusps
6. Identify retrograde planets
7. Add performance optimization (async/await, caching)

**Testing**:
- Integration tests with complete calculation flow
- Performance tests (must complete <3 seconds)
- Error handling tests (invalid dates, out-of-range locations)

### P2.3: Chart Data Serialization

**Goal**: Convert calculated chart to storable format

**Tasks**:
1. Create `NatalChart+JSON.swift` extension
2. Implement `Codable` conformance
3. Handle nested structures (planets, houses, aspects)
4. Create deserialization helpers
5. Add validation on deserialization

**Testing**:
- Round-trip tests (serialize → deserialize → compare)
- Large chart data tests
- Corrupted data handling tests

---

## Phase 3: User Interface - Data Input

### P3.1: Onboarding Flow

**Goal**: 3-screen onboarding explaining app value proposition

**Tasks**:
1. Create `OnboardingView.swift` with PageTabViewStyle
2. Create `OnboardingPage.swift` component:
   - Screen 1: "Discover Your Destiny" + illustration
   - Screen 2: "Pay Only for What You Need" + no subscriptions message
   - Screen 3: "Expert Knowledge + AI Power" + CTA button
3. Add onboarding images to Assets.xcassets
4. Implement "Skip" and "Next" buttons
5. Save onboarding completion to UserDefaults
6. Add localized strings (en + uk)

**Testing**:
- Snapshot tests for each onboarding screen
- Navigation flow tests
- Localization tests (English + Ukrainian)
- UserDefaults persistence tests

**Acceptance**: Onboarding screens display expected content and state persists after completion

### P3.2: Birth Data Input Form

**Goal**: Collect required birth information from user

**Tasks**:
1. Create `ChartInputView.swift` with Form:
   - DatePicker for birth date (1900-2100 range)
   - DatePicker for birth time (minute precision)
   - Custom location search field
   - "Calculate Chart" button (disabled until all fields valid)
2. Create `ChartInputViewModel.swift`:
   - Form validation logic
   - Save to SwiftData on successful calculation
3. Add input validation with error messages
4. Implement proper keyboard handling
5. Add localized strings

**Testing**:
- Unit tests for ViewModel validation logic
- UI tests for form interaction
- Edge case tests (midnight times, century-old dates)

### P3.3: Location Search

**Goal**: Geocode location names to coordinates

**Tasks**:
1. Create `LocationSearchView.swift`:
   - SearchableTextField with autocomplete
   - Results list with city + country
   - Selection handling
2. Create `LocationService.swift`:
   - CLGeocoder integration
   - Debounced search (300ms delay)
   - Result formatting (City, Country)
   - Coordinate extraction
3. Handle errors (no internet, no results)
4. Cache recent searches

**Testing**:
- Integration tests with CLGeocoder
- Mock tests for offline scenarios
- Debounce timing tests
- Multiple results handling tests

---

## Phase 4: Chart Visualization

### P4.1: Chart Rendering Engine

**Goal**: Display natal chart as circular diagram

**Tasks**:
1. Create `ChartView.swift` using Canvas or custom SwiftUI shapes
2. Implement circular layout:
   - Outer ring: 12 zodiac signs (30° each)
   - Inner ring: house cusps
   - Center: planet positions with symbols
   - Ascendant marker
3. Create `ChartRenderer.swift`:
   - Convert degrees to canvas coordinates
   - Draw zodiac wheel
   - Draw planet glyphs
   - Draw house lines
4. Support light/dark mode color schemes
5. Add SF Symbols or custom glyphs for planets

**Testing**:
- Snapshot tests for various chart configurations
- Light/dark mode tests
- Size adaptation tests (different iPhone screens)
- Performance tests (render time <100ms)

**Acceptance**: Chart rendering matches design references and displays accurate planetary positioning

### P4.2: Chart Display Screen

**Goal**: Show calculated chart with basic info

**Tasks**:
1. Create `ChartDisplayView.swift`:
   - Chart visualization (300x300 points)
   - Birth info display (date, time, location)
   - "Select Life Area" button
2. Add navigation from input screen
3. Handle loading states during calculation
4. Add error states for calculation failures
5. Implement retry mechanism

**Testing**:
- Navigation flow tests
- Loading state tests
- Error handling tests
- Layout tests for different screen sizes

---

## Phase 5: AI Report Generation

### P5.0: Astrology Knowledge Vector Store

**Goal**: Ingest the proprietary 50MB knowledge corpus, generate embeddings, and expose retrieval APIs via an OpenAI-hosted vector store for report prompts.

**Tasks**:
1. Build ingestion pipeline (`scripts/ingest-knowledge.swift`):
   - Extract Ukrainian text from PDF books (Swift + pdfminer/SwiftDocC pipeline).
   - Chunk rules into 400–600 character snippets with metadata (planet, aspect, life area).
   - Upload chunks to OpenAI Files API and attach them to a vector store (`vector_store_id`).
2. Let OpenAI manage embeddings (files attached to the vector store automatically generate embeddings via `text-embedding-3-large`); capture upload IDs for refresh workflows.
3. Create `AstrologyKnowledgeProvider` that queries the vector store (top-K) using chart metadata filters and returns Ukrainian bullet points for prompts.
4. Add CLI/automated job to refresh the vector store when rules change; log token spend and clean up obsolete files.
5. Fallback strategy: if vector store unavailable, return curated sample rules so prompt still succeeds (already wired in app).

**Testing**:
- Unit tests for chunking + metadata tagging.
- Retrieval smoke test ensuring relevant snippets returned for sample charts.
- Bench embedding pipeline time/cost.

### P5.1: OpenAI Service

**Goal**: Integrate OpenAI GPT-4 API via MacPaw’s OpenAI Swift client

**Tasks**:
1. Add `https://github.com/MacPaw/OpenAI` SPM dependency and create `OpenAIService.swift`:
   ```swift
   class OpenAIService {
       func generateReport(
           chartData: NatalChartData,
           focusArea: ReportArea,
           language: Language
       ) async throws -> String
   }
   ```
2. Implement authentication with API key from Config.swift using MacPaw client
3. Build structured prompts with:
   - System message (astrologer persona)
   - Chart data (planets, houses, aspects)
   - Life area focus
   - Vector-retrieved rule snippets (Ukrainian)
   - Language instruction (en/uk)
4. Handle API errors (rate limits, network failures, invalid responses)
5. Implement retry logic (exponential backoff, max 2 retries)
6. Add request/response logging (debug mode only)

**Testing**:
- Integration tests with OpenAI API (actual calls)
- Mock tests for error scenarios
- Retry logic tests
- Token usage tracking tests
- Cost estimation tests ($0.15 per report target)

### P5.2: Astrology Rules Engine

**Goal**: Match chart patterns to expert interpretation rules

**Tasks**:
1. Create `AstrologyRule.swift` model:
   ```swift
   struct AstrologyRule: Codable {
       let ruleId: String
       let category: ReportArea
       let condition: RuleCondition
       let interpretationEn: String
       let interpretationUk: String
       let weight: Double
       let tags: [String]
   }
   ```
2. Create `AstrologyRulesEngine.swift`:
   - Load rules from JSON files in bundle
   - Match rules to chart data
   - Score rules by relevance
   - Return top 10 relevant rules for context
3. Create JSON rule files in `Resources/AstrologyRules/`:
   - `finances/planets_in_houses.json`
   - `career/mc_analysis.json`
   - `relationships/venus_aspects.json`
   - `health/6th_house.json`
   - `general/dominant_planets.json`
4. Implement simple matching logic (planet + house + sign)

**Testing**:
- Unit tests for rule matching
- JSON parsing tests
- Relevance scoring tests
- Edge case tests (no matching rules)

**Note**: Initial MVP uses simple keyword matching; future version will use OpenAI embeddings for semantic search

### P5.3: AI Report Generator

**Goal**: Orchestrate report generation flow

**Tasks**:
1. Create `AIReportGenerator.swift`:
   - Get relevant rules from rules engine
   - Build comprehensive prompt
   - Call OpenAI service
   - Parse and validate response
   - Return formatted Report object
2. Implement prompt templates for each life area
3. Add response validation (length, structure, language)
4. Handle generation errors gracefully
5. Add progress callbacks for UI loading states

**Testing**:
- End-to-end tests with actual chart + API
- Mock tests for various scenarios
- Prompt engineering tests (quality of output)
- Language tests (Ukrainian output validation)
- Performance tests (<10 second target)

---

## Phase 6: Life Area Selection & Purchase

### P6.1: Area Selection Screen

**Goal**: Present 5 life area options for purchase

**Tasks**:
1. Create `ReportArea.swift` enum:
   ```swift
   enum ReportArea: String, CaseIterable {
       case finances = "finances"
       case career = "career"
       case relationships = "relationships"
       case health = "health"
       case general = "general"

       var price: Decimal { ... }
       var displayName: String { ... }
       var icon: String { ... } // SF Symbol name
   }
   ```
2. Create `AreaSelectionView.swift`:
   - Grid/list of area cards
   - Each card: icon, title, description, price
   - Tap to initiate purchase
   - "Already Purchased" badge for owned reports
3. Create `AreaCard.swift` reusable component
4. Add animations (card press, selection)
5. Add localized strings for all areas

**Testing**:
- Snapshot tests for each area card
- Interaction tests
- Purchased state tests
- Localization tests

### P6.2: StoreKit Integration

**Goal**: Handle in-app purchases through Apple

**Tasks**:
1. Configure products in App Store Connect:
   - `com.astrosvitla.astroinsight.report.general` ($9.99)
   - `com.astrosvitla.astroinsight.report.finances` ($6.99)
   - `com.astrosvitla.astroinsight.report.career` ($6.99)
   - `com.astrosvitla.astroinsight.report.relationships` ($5.99)
   - `com.astrosvitla.astroinsight.report.health` ($5.99)
2. Create `StoreKitService.swift`:
   - Load products on app launch
   - Request product info from App Store
   - Handle purchase transactions
   - Verify transaction receipts
   - Restore purchases functionality
3. Create `PurchaseManager.swift`:
   - Coordinate purchase → report generation → storage flow
   - Handle purchase states (pending, success, failed, cancelled)
   - Save transaction receipts to SwiftData
4. Implement sandbox testing support

**Testing**:
- Sandbox purchase tests (all product IDs)
- Transaction verification tests
- Restore purchases tests
- Error handling tests (declined payment, network failure)
- Receipt validation tests

### P6.3: Purchase Flow UI

**Goal**: Smooth purchase confirmation and execution

**Tasks**:
1. Create `PurchaseSheet.swift`:
   - Display area name, price
   - "Confirm Purchase" button
   - Loading state during transaction
   - Error messages for failed purchases
2. Create `PurchaseViewModel.swift`:
   - Initiate StoreKit purchase
   - Show progress indicator
   - Handle transaction results
   - Trigger report generation on success
3. Add haptic feedback for success/failure
4. Add localized error messages

**Testing**:
- UI tests for purchase flow
- Mock tests for StoreKit scenarios
- Error message tests
- Haptic feedback tests

---

## Phase 7: Report Display & Export

### P7.1: Report Display Screen

**Goal**: Present generated report with chart

**Tasks**:
1. Create `ReportView.swift`:
   - Scroll view with chart at top
   - Report content sections:
     * Key Influences (bold, larger font)
     * Detailed Analysis (body text, good line spacing)
     * Practical Recommendations (bulleted list)
   - Purchase date footer
   - Action buttons (Export PDF, Share)
2. Add dark mode support
3. Implement scroll-to-top button for long reports
4. Add localized strings

**Testing**:
- Snapshot tests for report layout
- Dark mode tests
- Long content scrolling tests

### P7.2: PDF Export

**Goal**: Generate PDF from report for saving/printing

**Tasks**:
1. Create `PDFGenerator.swift`:
   - Render report content to PDF context
   - Include chart image
   - Format text sections
   - Add footer with generation date
   - Return PDF Data
2. Integrate with UIActivityViewController for save/share
3. Handle PDF generation errors
4. Add "Saved" confirmation feedback

**Testing**:
- PDF generation tests (verify output)
- Different report lengths tests
- Image embedding tests
- Sharing flow tests

### P7.3: Report List Screen

**Goal**: Show all purchased reports organized by chart

**Tasks**:
1. Create `ReportListView.swift`:
   - Group reports by birth chart
   - Show chart name, birth date
   - List reports with area icon, purchase date
   - Tap to view full report
2. Create `ReportListViewModel.swift`:
   - Fetch reports from SwiftData
   - Group by chart
   - Sort by purchase date
3. Add search/filter capabilities (future enhancement placeholder)
4. Handle empty states ("No reports yet")

**Testing**:
- Data fetching tests
- Grouping logic tests
- Navigation tests
- Empty state tests

---

## Phase 8: Localization

### P8.1: English Localization (Primary)

**Goal**: Complete English language support

**Tasks**:
1. Create `en.lproj/Localizable.strings`:
   - All UI labels, buttons, messages
   - Error messages
   - Onboarding content
   - Life area names and descriptions
2. Use `LocalizedStringKey` in SwiftUI views
3. Format dates/numbers for English locale
4. Test all screens in English

**Testing**: Manual review of all English strings

### P8.2: Ukrainian Localization (Secondary)

**Goal**: Complete Ukrainian language support

**Tasks**:
1. Create `uk.lproj/Localizable.strings`:
   - Translate all English strings to Ukrainian
   - Use proper grammar (including declensions)
   - Adapt cultural references if needed
2. Test all screens in Ukrainian
3. Verify OpenAI generates Ukrainian reports correctly
4. Add Ukrainian-specific date/number formatting

**Testing**:
- Manual review by native Ukrainian speaker
- Screenshot tests for text overflow issues
- Report generation tests in Ukrainian

### P8.3: Language Detection

**Goal**: Automatically detect and apply user's preferred language

**Tasks**:
1. Read device language setting
2. Default to English if language not supported
3. Update UI immediately on language change
4. Pass language to OpenAI for report generation

**Testing**:
- Language detection tests
- Fallback to English tests
- Dynamic language switching tests

---

## Phase 9: Testing & Quality Assurance

### P9.1: Unit Tests

**Goal**: Comprehensive test coverage for business logic

**Test Coverage Targets**:
- Chart calculation: 90%+
- Data models: 85%+
- ViewModels: 80%+
- Services: 85%+

**Tasks**:
1. Write unit tests for all ViewModels
2. Write unit tests for all services
3. Write unit tests for chart calculations
4. Create mock objects for testing
5. Setup test data fixtures

**Acceptance**: CI passes all unit tests

### P9.2: Integration Tests

**Goal**: Test cross-component interactions

**Tasks**:
1. Test chart calculation → storage flow
2. Test purchase → report generation → storage flow
3. Test OpenAI API integration (with test API key)
4. Test StoreKit sandbox purchases
5. Test location geocoding

**Acceptance**: All critical user flows work end-to-end

### P9.3: UI Tests

**Goal**: Automated testing of user interface

**Tasks**:
1. Test onboarding flow
2. Test chart input and calculation flow
3. Test area selection and purchase flow
4. Test report viewing and export flow
5. Test navigation between screens
6. Test error states

**Acceptance**: All UI tests pass on iPhone SE and iPhone 15 Pro Max

### P9.5: Performance Testing Performance Testing

**Goal**: Verify performance meets requirements

**Tasks**:
1. Measure app launch time (target: <2s)
2. Measure chart calculation time (target: <3s)
3. Measure report generation time (target: <10s)
4. Measure UI frame rate (target: 60 FPS)
5. Measure memory usage
6. Measure battery drain during typical session
7. Test on iPhone SE (oldest supported device)

**Acceptance**: All performance targets met on iPhone SE

---

## Phase 10: App Store Preparation

### P10.1: App Store Assets

**Goal**: Prepare all required assets for submission

**Tasks**:
1. Create app icon (1024x1024)
2. Create screenshots for required device sizes:
   - 6.7" (iPhone 15 Pro Max)
   - 6.5" (iPhone 11 Pro Max)
   - 5.5" (iPhone 8 Plus)
3. Write App Store description (English + Ukrainian)
4. Create promotional text
5. Choose keywords for ASO
6. Create privacy policy document
7. Create terms of service document
8. Add app rating prompts (after positive interactions)

### P10.2: Privacy & Compliance

**Goal**: Meet Apple's privacy requirements

**Tasks**:
1. Fill out Privacy Nutrition Labels:
   - No data collection (anonymous usage)
   - Location used only for chart calculation
   - No tracking
   - No data shared with third parties
2. Implement App Tracking Transparency (ATT) if needed
3. Add privacy policy URL in App Store Connect
4. Review GDPR compliance (right to delete data)

### P10.3: TestFlight Beta

**Goal**: Conduct beta testing before public release

**Tasks**:
1. Upload build to App Store Connect
2. Configure TestFlight testing
3. Invite internal testers (5-10 people)
4. Collect feedback on:
   - Bugs and crashes
   - Report quality
   - UX issues
   - Performance problems
5. Iterate based on feedback
6. Conduct second beta round if needed

**Acceptance**: >4.5 star average from beta testers; crash-free rate >99%

### P10.4: App Store Submission

**Goal**: Submit app for App Store review

**Tasks**:
1. Complete all App Store Connect fields
2. Set pricing and availability
3. Configure in-app purchases
4. Add age rating
5. Submit for review
6. Prepare for review questions
7. Monitor review status
8. Respond to any rejection feedback

**Acceptance**: App approved and live on App Store

---

## Phase 11: Post-Launch

### P11.1: Monitoring

**Goal**: Track app health and usage

**Tasks**:
1. Monitor crash reports in Xcode Organizer
2. Track review ratings and feedback
3. Monitor StoreKit purchase analytics
4. Track OpenAI API usage and costs
5. Collect user feedback
6. Identify top bugs for hotfix priority

### P11.2: Iteration Planning

**Goal**: Plan next features based on feedback

**Future Enhancements** (see spec.md "Out of Scope"):
- Transits and predictions
- Synastry (compatibility) charts
- Progressions
- Social sharing features
- Premium subscription tier
- Cloud sync
- Additional languages

---

## Technical Decisions

### Decision 1: SwiftData vs CoreData

**Choice**: SwiftData

**Rationale**:
- Modern Apple framework (iOS 17+)
- Better SwiftUI integration
- Simpler API (@Model macro)
- Aligns with Constitutional Article II (modern Apple patterns)

**Trade-offs**:
- Newer framework (less mature than CoreData)
- Fewer resources/tutorials available
- iOS 17+ only (acceptable given target)

### Decision 2: OpenAI vs Claude for Report Generation

**Choice**: OpenAI GPT-4

**Rationale**:
- PRD specifies OpenAI
- Embeddings API available for future semantic search
- Well-documented Swift integration
- Cost-effective for report generation (~$0.15/report)

**Trade-offs**:
- Network dependency (mitigated by retry logic)
- Ongoing API costs (covered by per-report pricing)

### Decision 3: Local Rules vs Cloud Rules

**Choice**: Embedded JSON files in app bundle

**Rationale**:
- MVP simplicity (no backend needed)
- Offline capability
- Zero latency for rule matching
- Smaller attack surface (no API to secure)

**Trade-offs**:
- Rules updates require app update
- Cannot personalize rules per user
- Future migration to cloud/embeddings needed

### Decision 4: Pay-Per-Report vs Subscription

**Choice**: Pay-per-report (non-consumable IAP)

**Rationale**:
- PRD requirement
- User-friendly pricing model
- Lower barrier to entry
- Differentiator from competitors

**Trade-offs**:
- Lower lifetime value per user
- More complex purchase flow (multiple products)
- Cannot offer "unlimited" tier initially

### Decision 5: Portrait-Only vs Universal Orientation

**Choice**: Portrait-only

**Rationale**:
- PRD requirement
- Simplified UI design (circular chart fits better)
- Reduces testing matrix
- Typical astrology app usage pattern

**Trade-offs**:
- Less flexibility for users
- iPad experience suboptimal (future consideration)

---

## Risk Mitigation

### Risk 1: OpenAI API Reliability

**Mitigation**:
- Retry logic with exponential backoff
- Clear error messages for users
- Timeout handling (30 second max)
- Cost tracking to prevent runaway spending

### Risk 2: SwissEphemeris Integration Issues

**Mitigation**:
- Extensive testing with known charts
- Fallback error handling
- Reference documentation from library maintainer
- Research phase validation

### Risk 3: StoreKit Sandbox Testing Limitations

**Mitigation**:
- TestFlight testing with real purchases (refunded)
- Comprehensive mock testing
- Staged rollout to catch production issues early

### Risk 4: Report Quality Consistency

**Mitigation**:
- Prompt engineering with examples
- Expert rule curation process
- Beta tester feedback on report quality
- Iterative prompt refinement based on feedback

### Risk 5: App Store Rejection

**Mitigation**:
- Follow Apple Human Interface Guidelines strictly
- Complete privacy policy and terms
- No prohibited content in astrology interpretations
- Performance optimization for App Store review devices

---

## Dependencies

### External Dependencies

1. **SwissEphemeris Library**
   - Source: https://github.com/vsmithers1087/SwissEphemeris
   - Risk: Library maintenance/updates
   - Mitigation: Fork repository if needed

2. **OpenAI API**
   - Service: OpenAI GPT-4 API
   - Risk: API changes, rate limits, costs
   - Mitigation: API version pinning, cost monitoring

3. **Expert Astrology Rules**
   - Source: Professional astrologer consultant
   - Risk: Content quality, completeness
   - Mitigation: Expert review process, iterative refinement

### Apple Platform Dependencies

1. **StoreKit 2** (iOS 15+)
2. **SwiftData** (iOS 17+)
3. **CoreLocation** (Geocoding)
4. **App Store Connect** (Product configuration)

---

## Success Metrics

### Technical Metrics

- **Performance**:
  - App launch: <2 seconds ✅
  - Chart calculation: <3 seconds ✅
  - Report generation: <10 seconds ✅
  - UI interactions: 60 FPS ✅

- **Reliability**:
  - Crash-free rate: >99% ✅
  - Report generation success rate: >95% ✅

- **Quality**:
  - Unit test coverage: >80% ✅
    - App Store review: 4.5+ stars ✅

### Business Metrics (from spec.md)

- Month 1: 100 downloads, $200-300 revenue
- Month 3: 1,000 downloads, $2,000-2,500 revenue
- Month 6: 5,000 downloads, $10,000-15,000 revenue
- Conversion rate: 30% (charts created → purchases)

---

## Timeline Estimate

### Phase 0-1: Setup & Foundation (Week 1)
- Days 1-2: Project setup, dependencies, folder structure
- Days 3-5: SwiftData models, domain models, research validation

### Phase 2: Chart Calculation (Week 2)
- Days 1-3: SwissEphemeris integration and testing
- Days 4-5: ChartCalculator implementation and serialization

### Phase 3-4: UI Foundation (Week 3)
- Days 1-2: Onboarding flow
- Days 2-3: Birth data input form
- Days 4-5: Chart visualization

### Phase 5: AI Integration (Week 4)
- Days 1-2: OpenAI service integration
- Days 3-4: Astrology rules engine
- Days 4-5: Report generator and testing

### Phase 6: Purchase Flow (Week 5)
- Days 1-2: Area selection UI
- Days 3-4: StoreKit integration
- Day 5: Purchase flow testing

### Phase 7: Reports & Export (Week 6)
- Days 1-2: Report display screen
- Days 3-4: PDF export and report list
- Day 5: End-to-end flow testing

### Phase 8: Localization (Week 7)
- Days 1-2: English localization
- Days 3-4: Ukrainian localization
- Day 5: Language detection and testing

### Phase 9: Testing & QA (Week 8)
- Days 1-2: Unit and integration tests
- Days 3-4: UI and accessibility tests
- Day 5: Performance testing and optimization

### Phase 10: App Store (Week 9)
- Days 1-2: App Store assets and descriptions
- Days 3-4: Privacy compliance and TestFlight
- Day 5: App Store submission

### Phase 11: Launch & Iteration (Week 10+)
- Week 10: Monitor launch, collect feedback
- Week 11+: Iterate based on user feedback

**Total Estimated Timeline**: 10 weeks to App Store launch

---

## Appendix: File Structure

```
AstroSvitla/
├── AstroSvitla/
│   ├── App/
│   │   ├── AstroSvitlaApp.swift
│   │   └── Config.swift (gitignored - contains OpenAI API key)
│   │
│   ├── Core/
│   │   ├── Navigation/
│   │   │   └── AppNavigationCoordinator.swift
│   │   ├── Networking/
│   │   │   ├── OpenAIService.swift
│   │   │   └── NetworkError.swift
│   │   ├── Storage/
│   │   │   ├── ModelContainer+Shared.swift
│   │   │   └── SwiftDataManager.swift
│   │   └── Extensions/
│   │       ├── Date+Astrology.swift
│   │       ├── String+Localization.swift
│   │       └── View+Extensions.swift
│   │
│   ├── Models/
│   │   ├── SwiftData/
│   │   │   ├── User.swift
│   │   │   ├── BirthChart.swift
│   │   │   └── ReportPurchase.swift
│   │   └── Domain/
│   │       ├── NatalChart.swift
│   │       ├── Planet.swift
│   │       ├── House.swift
│   │       ├── Aspect.swift
│   │       ├── ReportArea.swift
│   │       └── AstrologyRule.swift
│   │
│   ├── Features/
│   │   ├── Onboarding/
│   │   │   ├── Views/
│   │   │   │   ├── OnboardingView.swift
│   │   │   │   └── OnboardingPageView.swift
│   │   │   └── ViewModels/
│   │   │       └── OnboardingViewModel.swift
│   │   │
│   │   ├── ChartInput/
│   │   │   ├── Views/
│   │   │   │   ├── ChartInputView.swift
│   │   │   │   └── LocationSearchView.swift
│   │   │   ├── ViewModels/
│   │   │   │   └── ChartInputViewModel.swift
│   │   │   └── Services/
│   │   │       └── LocationService.swift
│   │   │
│   │   ├── ChartCalculation/
│   │   │   ├── Services/
│   │   │   │   ├── SwissEphemerisService.swift
│   │   │   │   ├── ChartCalculator.swift
│   │   │   │   └── AstrologyRulesEngine.swift
│   │   │   └── Models/
│   │   │       └── ChartCalculationResult.swift
│   │   │
│   │   ├── ChartVisualization/
│   │   │   ├── Views/
│   │   │   │   ├── ChartView.swift
│   │   │   │   └── ChartDisplayView.swift
│   │   │   └── Renderers/
│   │   │       └── ChartRenderer.swift
│   │   │
│   │   ├── AreaSelection/
│   │   │   ├── Views/
│   │   │   │   ├── AreaSelectionView.swift
│   │   │   │   └── AreaCard.swift
│   │   │   └── ViewModels/
│   │   │       └── AreaSelectionViewModel.swift
│   │   │
│   │   ├── ReportGeneration/
│   │   │   ├── Views/
│   │   │   │   ├── ReportView.swift
│   │   │   │   ├── ReportListView.swift
│   │   │   │   └── LoadingView.swift
│   │   │   ├── ViewModels/
│   │   │   │   ├── ReportViewModel.swift
│   │   │   │   └── ReportListViewModel.swift
│   │   │   └── Services/
│   │   │       ├── AIReportGenerator.swift
│   │   │       ├── PDFGenerator.swift
│   │   │       └── CostTracker.swift
│   │   │
│   │   └── Purchase/
│   │       ├── Views/
│   │       │   └── PurchaseSheet.swift
│   │       ├── ViewModels/
│   │       │   └── PurchaseViewModel.swift
│   │       └── Services/
│   │           ├── PurchaseManager.swift
│   │           └── StoreKitService.swift
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets/
│   │   │   ├── AppIcon.appiconset/
│   │   │   ├── Colors/
│   │   │   └── Images/
│   │   │       ├── Onboarding/
│   │   │       └── Planets/
│   │   │
│   │   ├── AstrologyRules/
│   │   │   ├── finances/
│   │   │   │   ├── planets_in_houses.json
│   │   │   │   └── aspects.json
│   │   │   ├── career/
│   │   │   │   └── mc_analysis.json
│   │   │   ├── relationships/
│   │   │   │   └── venus_aspects.json
│   │   │   ├── health/
│   │   │   │   └── 6th_house.json
│   │   │   └── general/
│   │   │       └── dominant_planets.json
│   │   │
│   │   └── Localizations/
│   │       ├── en.lproj/
│   │       │   └── Localizable.strings
│   │       └── uk.lproj/
│   │           └── Localizable.strings
│   │
│   └── Shared/
│       ├── Components/
│       │   ├── CustomButton.swift
│       │   ├── CustomTextField.swift
│       │   ├── LoadingSpinner.swift
│       │   └── ErrorView.swift
│       └── Utilities/
│           ├── Constants.swift
│           ├── AppColors.swift
│           └── Formatters.swift
│
├── AstroSvitlaTests/
│   ├── ChartCalculationTests/
│   │   ├── SwissEphemerisServiceTests.swift
│   │   ├── ChartCalculatorTests.swift
│   │   └── AstrologyRulesEngineTests.swift
│   ├── ViewModelTests/
│   │   ├── ChartInputViewModelTests.swift
│   │   ├── ReportViewModelTests.swift
│   │   └── PurchaseViewModelTests.swift
│   ├── ServiceTests/
│   │   ├── OpenAIServiceTests.swift
│   │   ├── LocationServiceTests.swift
│   │   └── StoreKitServiceTests.swift
│   └── MockData/
│       ├── MockChartData.swift
│       ├── MockOpenAIResponses.swift
│       └── MockStoreKitProducts.swift
│
├── AstroSvitlaUITests/
│   ├── OnboardingFlowTests.swift
│   ├── ChartInputFlowTests.swift
│   ├── PurchaseFlowTests.swift
│
├── docs/
│   ├── ARCHITECTURE.md
│   ├── SETUP.md
│   ├── API_KEYS.md
│   ├── LOCALIZATION.md
│   └── TESTING.md
│
├── .gitignore
├── Config.swift.example
├── README.md
├── LICENSE
└── Privacy Policy.md
```

---

## Next Steps

1. **Review this plan** with stakeholders
2. **Answer open questions** from spec.md (7 clarifications needed)
3. **Obtain expert astrology rules** content
4. **Acquire OpenAI API key** (development + production)
5. **Setup App Store Connect** account and product IDs
6. **Begin Phase 0** (Research & Validation)

---

## Notes

- All API keys must be in `Config.swift` (gitignored)
- Follow TDD: write tests before implementation (Constitutional Article III)
- Use async/await for all network calls
- Localize all user-facing strings (English + Ukrainian)
- Chart calculations must match professional astrology software accuracy
- Report generation must complete within 10 seconds
- App must work offline except for initial report generation

**Constitutional Compliance**: This plan aligns with all articles of the AstroSvitla Constitution, using SwiftUI + SwiftData (Article II), TDD approach (Article III), performance budgets (Article IV), and accessibility requirements (Article V).

---

**Status**: Ready for implementation once open questions from spec are resolved and dependencies (expert rules, API keys) are obtained.
