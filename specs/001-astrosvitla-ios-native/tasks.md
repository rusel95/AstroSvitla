# Implementation Tasks: AstroSvitla

**Feature**: 001-astrosvitla-ios-native
**Spec**: [spec.md](./spec.md)
**Plan**: [plan.md](./plan.md)
**Data Model**: [data-model.md](./data-model.md)

---

## Task Execution Guide

- **[P]**: Tasks that can be executed in parallel
- **Dependencies**: Tasks marked with → must wait for previous task completion
- **Test-First**: All implementation tasks follow TDD (write tests first)

---

## Phase 0: Research & Validation (Week 1, Days 1-2)

### Research Tasks [P]

- [ ] **R1**: Research SwissEphemeris library integration
  - [ ] Review vsmithers1087/SwissEphemeris SPM documentation
  - [ ] Document planet position calculation API
  - [ ] Document house calculation (Placidus) API
  - [ ] Document aspect calculation methods
  - [ ] Test basic calculation with sample date
  - [ ] **Output**: Document findings in `research.md`

- [ ] **R2**: Research OpenAI GPT-4 API integration
  - [ ] Review OpenAI Swift API documentation
  - [ ] Document authentication and rate limiting
  - [ ] Draft prompt templates for each life area
  - [ ] Calculate token cost estimates (target <1500 tokens)
  - [ ] Test sample API call with mock data
  - [ ] **Output**: Document findings and prompts in `research.md`

- [ ] **R3**: Research StoreKit 2 non-consumable IAP
  - [ ] Review StoreKit 2 documentation for iOS 17+
  - [ ] Document product configuration requirements
  - [ ] Document transaction verification flow
  - [ ] Document restore purchases mechanism
  - [ ] Document sandbox testing workflow
  - [ ] **Output**: Document findings in `research.md`

- [ ] **R4**: Research SwiftData schema design best practices
  - [ ] Review SwiftData @Model macro usage
  - [ ] Document relationship configuration
  - [ ] Document cascade delete rules
  - [ ] Test JSON serialization for complex types
  - [ ] **Output**: Finalize schema in `data-model.md`

---

## Phase 1: Core Foundation (Week 1, Days 3-5)

### P1.1: Project Setup

- [ ] **T1.1.1**: Create Xcode iOS App project
  - [ ] Product Name: AstroSvitla
  - [ ] Organization: com.astrosvitla
  - [ ] Interface: SwiftUI
  - [ ] iOS Deployment Target: 17.0
  - [ ] Portrait orientation only

- [ ] **T1.1.2**: Configure project settings
  - [ ] Set bundle identifier: com.astrosvitla.astroinsight
  - [ ] Enable Dark Mode support
  - [ ] Disable landscape orientations
  - [ ] Configure signing & capabilities

- [ ] **T1.1.3**: Add Swift Package Dependencies
  - [ ] Add SwissEphemeris: `https://github.com/vsmithers1087/SwissEphemeris`
  - [ ] Verify package builds successfully

- [X] **T1.1.4**: Create folder structure
  - [X] Create `App/` folder
  - [X] Create `Core/` with subfolders (Navigation, Networking, Storage, Extensions)
  - [X] Create `Models/` with subfolders (SwiftData, Domain)
  - [X] Create `Features/` with subfolders for each feature
  - [X] Create `Resources/` with subfolders (Assets, AstrologyRules, Localizations)
  - [X] Create `Shared/` with subfolders (Components, Utilities)

- [X] **T1.1.5**: Setup .gitignore
  - [X] Add `**/Config.swift` to gitignore
  - [X] Add standard iOS/Xcode ignores
  - [X] Add SwiftData database files ignore

- [X] **T1.1.6**: Create Config.swift template
  - [X] Create `Config.swift.example` with placeholder API key
  - [X] Document setup instructions in comments
  - [X] Verify file is gitignored

### P1.2: SwiftData Models (→ T1.1.6)

- [X] **T1.2.1**: Implement User model
  - [X] Create `Models/SwiftData/User.swift`
  - [X] Add @Model macro
  - [X] Add id (@Attribute(.unique))
  - [X] Add createdAt, lastActiveAt
  - [X] Add relationships to charts and purchases
  - [X] **Test**: Unit test for User creation

- [X] **T1.2.2**: Implement BirthChart model
  - [X] Create `Models/SwiftData/BirthChart.swift`
  - [X] Add all birth data fields
  - [X] Add chartDataJSON field
  - [X] Add relationship to User and ReportPurchases
  - [X] Add computed properties
  - [X] **Test**: Unit test for BirthChart CRUD operations

- [X] **T1.2.3**: Implement ReportPurchase model
  - [X] Create `Models/SwiftData/ReportPurchase.swift`
  - [X] Add report content fields
  - [X] Add purchase info fields
  - [X] Add relationship to BirthChart
  - [X] Add computed properties
  - [X] **Test**: Unit test for ReportPurchase creation

- [X] **T1.2.4**: Setup ModelContainer
  - [X] Create `Core/Storage/ModelContainer+Shared.swift`
  - [X] Configure schema with all models
  - [X] Implement default user initialization
  - [X] Integrate into AstroSvitlaApp.swift
  - [X] **Test**: Integration test for container setup

### P1.3: Domain Models [P] (→ T1.2.4)

- [X] **T1.3.1**: Implement NatalChart domain model
  - [X] Create `Models/Domain/NatalChart.swift`
  - [X] Add Codable conformance
  - [X] Add all required fields
  - [X] **Test**: Unit test for JSON serialization

- [X] **T1.3.2**: Implement Planet domain model
  - [X] Create `Models/Domain/Planet.swift`
  - [X] Create PlanetType enum
  - [X] Add all required fields
  - [X] **Test**: Unit test for Planet initialization

- [X] **T1.3.3**: Implement House domain model
  - [X] Create `Models/Domain/House.swift`
  - [X] Add all required fields
  - [X] **Test**: Unit test for House initialization

- [X] **T1.3.4**: Implement Aspect domain model
  - [X] Create `Models/Domain/Aspect.swift`
  - [X] Create AspectType enum with angle calculations
  - [X] Add orb validation
  - [X] **Test**: Unit test for Aspect logic

- [X] **T1.3.5**: Implement ZodiacSign enum
  - [X] Create `Models/Domain/ZodiacSign.swift`
  - [X] Add Element and Modality enums
  - [X] Add computed properties (element, modality, degree range)
  - [X] **Test**: Unit test for zodiac calculations

- [X] **T1.3.6**: Implement ReportArea enum
  - [X] Create `Models/Domain/ReportArea.swift`
  - [X] Add display names, prices, icons
  - [X] Add StoreKit product ID mapping
  - [X] **Test**: Unit test for ReportArea properties

---

## Phase 2: Chart Calculation Engine (Week 2)

### P2.1: SwissEphemeris Wrapper (→ P1.3)

- [ ] **T2.1.1**: Create SwissEphemerisService
  - [ ] Create `Features/ChartCalculation/Services/SwissEphemerisService.swift`
  - [ ] Initialize ephemeris data path
  - [ ] Implement timezone conversion helpers
  - [ ] **Test**: Unit test for timezone conversions

- [ ] **T2.1.2**: Implement planet position calculations
  - [ ] Add method for calculating single planet position
  - [ ] Add method for calculating all planets
  - [ ] Handle coordinate conversions
  - [ ] **Test**: Unit test against known reference data

- [ ] **T2.1.3**: Implement house calculations
  - [ ] Add method for calculating house cusps (Placidus)
  - [ ] Determine zodiac sign for each house
  - [ ] **Test**: Unit test against known reference data

- [ ] **T2.1.4**: Implement aspect calculations
  - [ ] Add method for calculating aspects between planets
  - [ ] Implement orb tolerance checking
  - [ ] Filter to major aspects only (MVP)
  - [ ] **Test**: Unit test for aspect detection

- [ ] **T2.1.5**: Implement retrograde detection
  - [ ] Add method to check planet speed
  - [ ] Determine retrograde status
  - [ ] **Test**: Unit test for retrograde calculation

### P2.2: Chart Calculator (→ T2.1.5)

- [ ] **T2.2.1**: Create ChartCalculator service
  - [ ] Create `Features/ChartCalculation/Services/ChartCalculator.swift`
  - [ ] Implement calculate() method
  - [ ] Orchestrate SwissEphemeris calls
  - [ ] **Test**: Unit test for orchestration logic

- [ ] **T2.2.2**: Implement complete chart calculation
  - [ ] Calculate all 10 planets
  - [ ] Calculate 12 houses
  - [ ] Calculate major aspects
  - [ ] Determine zodiac signs
  - [ ] Identify retrogrades
  - [ ] **Test**: Integration test with complete flow

- [ ] **T2.2.3**: Add async/await support
  - [ ] Make calculate() async
  - [ ] Add error handling
  - [ ] Add timeout handling
  - [ ] **Test**: Test async behavior

- [ ] **T2.2.4**: Optimize performance
  - [ ] Add result caching if needed
  - [ ] Ensure <3 second calculation time
  - [ ] **Test**: Performance benchmark test

### P2.3: Chart Serialization (→ T2.2.4)

- [ ] **T2.3.1**: Implement NatalChart JSON encoding
  - [ ] Create `Models/Domain/NatalChart+JSON.swift`
  - [ ] Implement Codable conformance
  - [ ] Handle nested structures
  - [ ] **Test**: Round-trip serialization test

- [ ] **T2.3.2**: Implement deserialization helpers
  - [ ] Add safe decoding with error handling
  - [ ] Add validation on decode
  - [ ] **Test**: Test with corrupted data

---

## Phase 3: User Interface - Data Input (Week 3, Days 1-3)

### P3.1: Onboarding Flow (→ P1.3)

- [ ] **T3.1.1**: Create OnboardingView
  - [ ] Create `Features/Onboarding/Views/OnboardingView.swift`
  - [ ] Implement PageTabViewStyle
  - [ ] Add navigation dots
  - [ ] **Test**: Snapshot test for layout

- [ ] **T3.1.2**: Create OnboardingPageView component
  - [ ] Create page template with image + text
  - [ ] Implement Skip and Next buttons
  - [ ] **Test**: Snapshot test for each page

- [ ] **T3.1.3**: Add onboarding content
  - [ ] Page 1: "Discover Your Destiny"
  - [ ] Page 2: "Pay Only for What You Need"
  - [ ] Page 3: "Expert Knowledge + AI Power"
  - [ ] Add placeholder images to Assets
  - [ ] **Test**: Content rendering tests

- [ ] **T3.1.4**: Implement onboarding state
  - [ ] Create OnboardingViewModel
  - [ ] Save completion to UserDefaults
  - [ ] Add logic to show only once
  - [ ] **Test**: Unit test for state persistence

- [ ] **T3.1.5**: Add localization
  - [ ] Add English strings to `en.lproj/Localizable.strings`
  - [ ] Add Ukrainian strings to `uk.lproj/Localizable.strings`
  - [ ] **Test**: Localization tests

- [ ] **T3.1.6**: Accessibility implementation
  - [ ] Add VoiceOver labels
  - [ ] Test with VoiceOver
  - [ ] **Test**: Accessibility audit

### P3.2: Birth Data Input Form (→ T3.1.6)

- [ ] **T3.2.1**: Create ChartInputView
  - [ ] Create `Features/ChartInput/Views/ChartInputView.swift`
  - [ ] Add Form with DatePickers
  - [ ] Add location search field
  - [ ] Add "Calculate Chart" button
  - [ ] **Test**: Snapshot test

- [ ] **T3.2.2**: Create ChartInputViewModel
  - [ ] Create validation logic
  - [ ] Add published properties for form fields
  - [ ] Add computed isValid property
  - [ ] **Test**: Unit test for validation

- [ ] **T3.2.3**: Implement form validation
  - [ ] Validate date range (1900-2100)
  - [ ] Validate all fields filled
  - [ ] Show inline error messages
  - [ ] **Test**: UI test for validation

- [ ] **T3.2.4**: Add localization
  - [ ] Add form labels (English)
  - [ ] Add form labels (Ukrainian)
  - [ ] **Test**: Localization tests

- [ ] **T3.2.5**: Accessibility implementation
  - [ ] Add VoiceOver labels for form fields
  - [ ] Support Dynamic Type
  - [ ] **Test**: Accessibility audit

### P3.3: Location Search (→ T3.2.2)

- [ ] **T3.3.1**: Create LocationSearchView
  - [ ] Create `Features/ChartInput/Views/LocationSearchView.swift`
  - [ ] Add searchable text field
  - [ ] Add results list
  - [ ] **Test**: Snapshot test

- [ ] **T3.3.2**: Create LocationService
  - [ ] Create `Features/ChartInput/Services/LocationService.swift`
  - [ ] Implement CLGeocoder integration
  - [ ] Add debounced search (300ms)
  - [ ] Format results (City, Country)
  - [ ] **Test**: Integration test with CLGeocoder

- [ ] **T3.3.3**: Handle search errors
  - [ ] No internet connection error
  - [ ] No results found error
  - [ ] **Test**: Mock tests for error scenarios

- [ ] **T3.3.4**: Implement result selection
  - [ ] Extract coordinates on selection
  - [ ] Update form with location
  - [ ] **Test**: UI test for selection flow

---

## Phase 4: Chart Visualization (Week 3, Days 4-5)

### P4.1: Chart Rendering Engine (→ P2.3)

- [ ] **T4.1.1**: Create ChartView with Canvas
  - [ ] Create `Features/ChartVisualization/Views/ChartView.swift`
  - [ ] Setup Canvas drawing context
  - [ ] **Test**: Snapshot test for empty canvas

- [ ] **T4.1.2**: Implement ChartRenderer
  - [ ] Create `Features/ChartVisualization/Renderers/ChartRenderer.swift`
  - [ ] Add coordinate conversion methods
  - [ ] Add degree-to-canvas helpers
  - [ ] **Test**: Unit test for coordinate math

- [ ] **T4.1.3**: Draw zodiac wheel
  - [ ] Draw outer circle with 12 segments
  - [ ] Add zodiac sign glyphs/labels
  - [ ] **Test**: Snapshot test

- [ ] **T4.1.4**: Draw house lines
  - [ ] Draw house cusps
  - [ ] Draw inner house divisions
  - [ ] **Test**: Snapshot test

- [ ] **T4.1.5**: Draw planet positions
  - [ ] Add planet glyphs at correct degrees
  - [ ] Use SF Symbols or custom icons
  - [ ] Add ascendant marker
  - [ ] **Test**: Snapshot test for various charts

- [ ] **T4.1.6**: Support light/dark mode
  - [ ] Define color schemes
  - [ ] Apply adaptive colors
  - [ ] **Test**: Snapshot tests for both modes

- [ ] **T4.1.7**: Accessibility for chart
  - [ ] Add VoiceOver description of planetary positions
  - [ ] **Test**: VoiceOver audit

### P4.2: Chart Display Screen (→ T4.1.7)

- [ ] **T4.2.1**: Create ChartDisplayView
  - [ ] Create `Features/ChartVisualization/Views/ChartDisplayView.swift`
  - [ ] Add ChartView (300x300)
  - [ ] Add birth info display
  - [ ] Add "Select Life Area" button
  - [ ] **Test**: Snapshot test

- [ ] **T4.2.2**: Add navigation integration
  - [ ] Navigate from ChartInputView on successful calculation
  - [ ] Pass calculated chart data
  - [ ] **Test**: Navigation flow test

- [ ] **T4.2.3**: Add loading state
  - [ ] Show progress during calculation
  - [ ] **Test**: Loading state test

- [ ] **T4.2.4**: Add error state
  - [ ] Show error message if calculation fails
  - [ ] Add retry button
  - [ ] **Test**: Error handling test

---

## Phase 5: AI Report Generation (Week 4)

### P5.1: OpenAI Service (→ P1.1.6)

- [ ] **T5.1.1**: Create OpenAIService
  - [ ] Create `Core/Networking/OpenAIService.swift`
  - [ ] Implement authentication with API key from Config.swift
  - [ ] Add request/response models
  - [ ] **Test**: Mock test for API structure

- [ ] **T5.1.2**: Implement generateReport method
  - [ ] Create async method signature
  - [ ] Build URLRequest for OpenAI API
  - [ ] Parse JSON response
  - [ ] **Test**: Integration test with real API (use test key)

- [ ] **T5.1.3**: Build structured prompts
  - [ ] Create system message (astrologer persona)
  - [ ] Format chart data for prompt
  - [ ] Add life area focus
  - [ ] Add language instruction
  - [ ] **Test**: Prompt generation unit test

- [ ] **T5.1.4**: Implement error handling
  - [ ] Handle rate limits (429)
  - [ ] Handle network failures
  - [ ] Handle invalid responses
  - [ ] **Test**: Mock tests for all error scenarios

- [ ] **T5.1.5**: Implement retry logic
  - [ ] Add exponential backoff
  - [ ] Limit to 2 retries
  - [ ] **Test**: Retry logic test

- [ ] **T5.1.6**: Add request logging
  - [ ] Log requests in debug mode only
  - [ ] Track token usage
  - [ ] Estimate costs
  - [ ] **Test**: Logging test

### P5.2: Astrology Rules Engine [P] (→ P1.3)

- [ ] **T5.2.1**: Create AstrologyRule model
  - [ ] Create `Models/Domain/AstrologyRule.swift`
  - [ ] Add Codable conformance
  - [ ] **Test**: JSON parsing test

- [ ] **T5.2.2**: Create AstrologyRulesEngine
  - [ ] Create `Features/ChartCalculation/Services/AstrologyRulesEngine.swift`
  - [ ] Implement rule loading from JSON
  - [ ] **Test**: Rule loading test

- [ ] **T5.2.3**: Create sample rule JSON files
  - [ ] `Resources/AstrologyRules/finances/planets_in_houses.json`
  - [ ] `Resources/AstrologyRules/career/mc_analysis.json`
  - [ ] `Resources/AstrologyRules/relationships/venus_aspects.json`
  - [ ] `Resources/AstrologyRules/health/6th_house.json`
  - [ ] `Resources/AstrologyRules/general/dominant_planets.json`
  - [ ] Add 5-10 rules per file
  - [ ] **Test**: JSON validation test

- [ ] **T5.2.4**: Implement rule matching
  - [ ] Match rules by planet + house + sign
  - [ ] Score rules by relevance
  - [ ] Return top 10 matches
  - [ ] **Test**: Matching logic unit test

### P5.3: AI Report Generator (→ T5.1.6, T5.2.4)

- [ ] **T5.3.1**: Create AIReportGenerator
  - [ ] Create `Features/ReportGeneration/Services/AIReportGenerator.swift`
  - [ ] Orchestrate rules engine + OpenAI service
  - [ ] **Test**: Mock integration test

- [ ] **T5.3.2**: Implement prompt templates
  - [ ] Create template for finances
  - [ ] Create template for career
  - [ ] Create template for relationships
  - [ ] Create template for health
  - [ ] Create template for general
  - [ ] **Test**: Template rendering test

- [ ] **T5.3.3**: Implement report generation flow
  - [ ] Get relevant rules
  - [ ] Build comprehensive prompt
  - [ ] Call OpenAI API
  - [ ] Parse response
  - [ ] Return Report object
  - [ ] **Test**: End-to-end test with real API

- [ ] **T5.3.4**: Add response validation
  - [ ] Validate report length (400-500 words)
  - [ ] Validate language (en or uk)
  - [ ] Validate structure (3 sections)
  - [ ] **Test**: Validation tests

- [ ] **T5.3.5**: Add progress callbacks
  - [ ] Emit progress for UI loading states
  - [ ] **Test**: Progress callback test

- [ ] **T5.3.6**: Performance testing
  - [ ] Ensure <10 second generation
  - [ ] **Test**: Performance benchmark

---

## Phase 6: Life Area Selection & Purchase (Week 5)

### P6.1: Area Selection Screen (→ P4.2.4)

- [ ] **T6.1.1**: Create AreaSelectionView
  - [ ] Create `Features/AreaSelection/Views/AreaSelectionView.swift`
  - [ ] Display 5 area cards in grid/list
  - [ ] **Test**: Snapshot test

- [ ] **T6.1.2**: Create AreaCard component
  - [ ] Create `Features/AreaSelection/Views/AreaCard.swift`
  - [ ] Show icon, title, description, price
  - [ ] Add tap gesture
  - [ ] **Test**: Snapshot test

- [ ] **T6.1.3**: Create AreaSelectionViewModel
  - [ ] Fetch purchased reports for chart
  - [ ] Determine which areas are already purchased
  - [ ] Handle area selection
  - [ ] **Test**: Unit test for state management

- [ ] **T6.1.4**: Implement purchased state
  - [ ] Show "View Report" badge for purchased areas
  - [ ] Navigate to existing report instead of purchase
  - [ ] **Test**: Purchased state UI test

- [ ] **T6.1.5**: Add animations
  - [ ] Card press animation
  - [ ] Selection highlight
  - [ ] **Test**: Animation tests

- [ ] **T6.1.6**: Add localization
  - [ ] Localize area names and descriptions
  - [ ] **Test**: Localization tests

- [ ] **T6.1.7**: Accessibility
  - [ ] VoiceOver labels
  - [ ] **Test**: Accessibility audit

### P6.2: StoreKit Integration (→ T1.1.2)

- [ ] **T6.2.1**: Configure products in App Store Connect
  - [ ] Create 5 non-consumable IAP products
  - [ ] Set product IDs and prices
  - [ ] Configure for sandbox testing
  - [ ] **Manual verification**

- [ ] **T6.2.2**: Create StoreKitService
  - [ ] Create `Features/Purchase/Services/StoreKitService.swift`
  - [ ] Load products on app launch
  - [ ] Request product info from App Store
  - [ ] **Test**: Mock test for product loading

- [ ] **T6.2.3**: Implement purchase transaction handling
  - [ ] Handle purchase request
  - [ ] Verify transaction
  - [ ] Return transaction result
  - [ ] **Test**: Mock test for purchase flow

- [ ] **T6.2.4**: Implement restore purchases
  - [ ] Add restore purchases method
  - [ ] Verify restored transactions
  - [ ] **Test**: Restore flow test

- [ ] **T6.2.5**: Create PurchaseManager
  - [ ] Create `Features/Purchase/Services/PurchaseManager.swift`
  - [ ] Coordinate purchase → report generation → storage
  - [ ] Handle all purchase states
  - [ ] **Test**: Integration test for full flow

- [ ] **T6.2.6**: Sandbox testing
  - [ ] Test all 5 product purchases in sandbox
  - [ ] Test declined payments
  - [ ] Test restore purchases
  - [ ] **Manual verification**

### P6.3: Purchase Flow UI (→ T6.2.5)

- [ ] **T6.3.1**: Create PurchaseSheet
  - [ ] Create `Features/Purchase/Views/PurchaseSheet.swift`
  - [ ] Show area name and price
  - [ ] Add "Confirm Purchase" button
  - [ ] Show loading state
  - [ ] **Test**: Snapshot test

- [ ] **T6.3.2**: Create PurchaseViewModel
  - [ ] Initiate StoreKit purchase
  - [ ] Handle progress states
  - [ ] Handle errors
  - [ ] Trigger report generation on success
  - [ ] **Test**: Unit test for state machine

- [ ] **T6.3.3**: Add haptic feedback
  - [ ] Success haptic
  - [ ] Error haptic
  - [ ] **Test**: Haptic feedback test

- [ ] **T6.3.4**: Add error messages
  - [ ] Localize all error messages
  - [ ] **Test**: Error message display test

---

## Phase 7: Report Display & Export (Week 6)

### P7.1: Report Display Screen (→ T6.3.2)

- [ ] **T7.1.1**: Create ReportView
  - [ ] Create `Features/ReportGeneration/Views/ReportView.swift`
  - [ ] Add ScrollView with chart at top
  - [ ] Display report sections
  - [ ] Add action buttons
  - [ ] **Test**: Snapshot test

- [ ] **T7.1.2**: Implement report formatting
  - [ ] Bold "Key Influences" section
  - [ ] Good line spacing for analysis
  - [ ] Bulleted list for recommendations
  - [ ] **Test**: Formatting tests

- [ ] **T7.1.3**: Support Dynamic Type
  - [ ] Test all accessibility text sizes
  - [ ] **Test**: Dynamic Type tests

- [ ] **T7.1.4**: Support dark mode
  - [ ] Test dark mode colors
  - [ ] **Test**: Dark mode snapshot tests

- [ ] **T7.1.5**: Add scroll-to-top button
  - [ ] Show when scrolled down
  - [ ] **Test**: Interaction test

- [ ] **T7.1.6**: Accessibility
  - [ ] VoiceOver support
  - [ ] **Test**: VoiceOver audit

### P7.2: PDF Export [P] (→ T7.1.1)

- [ ] **T7.2.1**: Create PDFGenerator
  - [ ] Create `Features/ReportGeneration/Services/PDFGenerator.swift`
  - [ ] Render report text to PDF
  - [ ] Include chart image
  - [ ] Add footer with date
  - [ ] **Test**: PDF generation test

- [ ] **T7.2.2**: Integrate with UIActivityViewController
  - [ ] Add "Export PDF" button
  - [ ] Show share sheet
  - [ ] **Test**: Share flow test

- [ ] **T7.2.3**: Handle errors
  - [ ] Show error if PDF generation fails
  - [ ] **Test**: Error handling test

- [ ] **T7.2.4**: Add confirmation feedback
  - [ ] Show "Saved" message
  - [ ] **Test**: Feedback test

### P7.3: Report List Screen [P] (→ T1.2.3)

- [ ] **T7.3.1**: Create ReportListView
  - [ ] Create `Features/ReportGeneration/Views/ReportListView.swift`
  - [ ] Group reports by chart
  - [ ] Show chart name, birth date
  - [ ] List reports with icons and dates
  - [ ] **Test**: Snapshot test

- [ ] **T7.3.2**: Create ReportListViewModel
  - [ ] Fetch all reports from SwiftData
  - [ ] Group by chart
  - [ ] Sort by purchase date
  - [ ] **Test**: Unit test for grouping logic

- [ ] **T7.3.3**: Add navigation
  - [ ] Tap report to view full report
  - [ ] **Test**: Navigation test

- [ ] **T7.3.4**: Handle empty state
  - [ ] Show "No reports yet" message
  - [ ] **Test**: Empty state test

---

## Phase 8: Localization (Week 7)

### P8.1: English Localization

- [ ] **T8.1.1**: Create English strings file
  - [ ] Create `Resources/Localizations/en.lproj/Localizable.strings`
  - [ ] Add all UI labels, buttons, messages
  - [ ] Add error messages
  - [ ] Add onboarding content
  - [ ] Add life area names and descriptions
  - [ ] **Test**: String extraction test

- [ ] **T8.1.2**: Apply LocalizedStringKey in views
  - [ ] Update all Text() views
  - [ ] Update all button labels
  - [ ] **Test**: Localization loading test

- [ ] **T8.1.3**: Format dates and numbers
  - [ ] Use locale-specific formatters
  - [ ] **Test**: Formatting tests

- [ ] **T8.1.4**: Manual review
  - [ ] Test all screens in English
  - [ ] **Manual verification**

### P8.2: Ukrainian Localization (→ T8.1.4)

- [ ] **T8.2.1**: Create Ukrainian strings file
  - [ ] Create `Resources/Localizations/uk.lproj/Localizable.strings`
  - [ ] Translate all English strings
  - [ ] Use proper grammar and declensions
  - [ ] **Professional translation review required**

- [ ] **T8.2.2**: Test Ukrainian reports
  - [ ] Verify OpenAI generates Ukrainian correctly
  - [ ] **Test**: Ukrainian report generation test

- [ ] **T8.2.3**: Format dates and numbers for Ukrainian
  - [ ] Use Ukrainian locale formatters
  - [ ] **Test**: Ukrainian formatting tests

- [ ] **T8.2.4**: Manual review
  - [ ] Test all screens in Ukrainian
  - [ ] Check for text overflow issues
  - [ ] **Native speaker review required**

### P8.3: Language Detection (→ T8.2.4)

- [ ] **T8.3.1**: Implement language detection
  - [ ] Read Locale.current.language
  - [ ] Default to English if not supported
  - [ ] **Test**: Language detection test

- [ ] **T8.3.2**: Pass language to OpenAI
  - [ ] Include language in report generation request
  - [ ] **Test**: Language parameter test

- [ ] **T8.3.3**: Test language switching
  - [ ] Change device language and retest
  - [ ] **Manual verification**

---

## Phase 9: Testing & Quality Assurance (Week 8)

### P9.1: Unit Tests

- [ ] **T9.1.1**: Write ViewModel unit tests
  - [ ] ChartInputViewModel tests
  - [ ] AreaSelectionViewModel tests
  - [ ] ReportViewModel tests
  - [ ] PurchaseViewModel tests
  - [ ] **Target**: 80%+ coverage

- [ ] **T9.1.2**: Write Service unit tests
  - [ ] SwissEphemerisService tests
  - [ ] ChartCalculator tests
  - [ ] OpenAIService tests (mocked)
  - [ ] LocationService tests
  - [ ] StoreKitService tests (mocked)
  - [ ] **Target**: 85%+ coverage

- [ ] **T9.1.3**: Write Model unit tests
  - [ ] Domain model tests
  - [ ] SwiftData model tests
  - [ ] **Target**: 85%+ coverage

- [ ] **T9.1.4**: Create mock objects
  - [ ] Mock chart data
  - [ ] Mock OpenAI responses
  - [ ] Mock StoreKit products

### P9.2: Integration Tests (→ T9.1.4)

- [ ] **T9.2.1**: Test chart calculation → storage
  - [ ] End-to-end flow test

- [ ] **T9.2.2**: Test purchase → report → storage
  - [ ] End-to-end flow test

- [ ] **T9.2.3**: Test OpenAI API integration
  - [ ] Use test API key
  - [ ] Verify actual API calls work

- [ ] **T9.2.4**: Test StoreKit sandbox
  - [ ] Test all purchase flows in sandbox

- [ ] **T9.2.5**: Test location geocoding
  - [ ] Integration test with CLGeocoder

### P9.3: UI Tests (→ T9.2.5)

- [ ] **T9.3.1**: Onboarding flow UI test
- [ ] **T9.3.2**: Chart input and calculation UI test
- [ ] **T9.3.3**: Area selection and purchase UI test
- [ ] **T9.3.4**: Report viewing and export UI test
- [ ] **T9.3.5**: Navigation UI test
- [ ] **T9.3.6**: Error state UI tests

### P9.4: Accessibility Testing (→ T9.3.6)

- [ ] **T9.4.1**: VoiceOver complete flow test
  - [ ] Navigate entire app with VoiceOver
  - [ ] **Manual verification**

- [ ] **T9.4.2**: Dynamic Type testing
  - [ ] Test largest accessibility sizes
  - [ ] **Manual verification**

- [ ] **T9.4.3**: High contrast mode testing
  - [ ] Test in high contrast mode
  - [ ] **Manual verification**

- [ ] **T9.4.4**: Reduce Motion testing
  - [ ] Test with Reduce Motion enabled
  - [ ] **Manual verification**

- [ ] **T9.4.5**: Verify image alt text
  - [ ] All images have descriptions

- [ ] **T9.4.6**: Verify button labels
  - [ ] All buttons have clear labels

- [ ] **T9.4.7**: Color contrast audit
  - [ ] Use contrast checker tool
  - [ ] **Manual verification**

### P9.5: Performance Testing (→ T9.4.7)

- [ ] **T9.5.1**: Measure app launch time
  - [ ] **Target**: <2 seconds

- [ ] **T9.5.2**: Measure chart calculation time
  - [ ] **Target**: <3 seconds

- [ ] **T9.5.3**: Measure report generation time
  - [ ] **Target**: <10 seconds

- [ ] **T9.5.4**: Measure UI frame rate
  - [ ] **Target**: 60 FPS

- [ ] **T9.5.5**: Measure memory usage
  - [ ] Check for memory leaks

- [ ] **T9.5.6**: Measure battery drain
  - [ ] Typical 10-minute session

- [ ] **T9.5.7**: Test on iPhone SE (oldest device)
  - [ ] All performance targets must pass on SE

---

## Phase 10: App Store Preparation (Week 9)

### P10.1: App Store Assets [P]

- [ ] **T10.1.1**: Create app icon (1024x1024)
- [ ] **T10.1.2**: Create screenshots (6.7", 6.5", 5.5")
  - [ ] Screenshot 1: Onboarding
  - [ ] Screenshot 2: Input form
  - [ ] Screenshot 3: Chart visualization
  - [ ] Screenshot 4: Area selection
  - [ ] Screenshot 5: Report preview
  - [ ] Screenshot 6: Bilingual support
- [ ] **T10.1.3**: Write App Store description (English)
- [ ] **T10.1.4**: Write App Store description (Ukrainian)
- [ ] **T10.1.5**: Create promotional text
- [ ] **T10.1.6**: Choose ASO keywords
- [ ] **T10.1.7**: Create privacy policy document
- [ ] **T10.1.8**: Create terms of service document
- [ ] **T10.1.9**: Implement app rating prompt

### P10.2: Privacy & Compliance [P] (→ T10.1.7)

- [ ] **T10.2.1**: Fill out Privacy Nutrition Labels in App Store Connect
- [ ] **T10.2.2**: Implement ATT if needed
- [ ] **T10.2.3**: Add privacy policy URL
- [ ] **T10.2.4**: Review GDPR compliance

### P10.3: TestFlight Beta (→ T10.1.9, T10.2.4)

- [ ] **T10.3.1**: Upload build to App Store Connect
- [ ] **T10.3.2**: Configure TestFlight groups
- [ ] **T10.3.3**: Invite 5-10 internal testers
- [ ] **T10.3.4**: Collect feedback
  - [ ] Bugs and crashes
  - [ ] Report quality
  - [ ] UX issues
  - [ ] Performance
- [ ] **T10.3.5**: Iterate based on feedback
- [ ] **T10.3.6**: Second beta round if needed
- [ ] **Target**: >4.5 star rating, >99% crash-free

### P10.4: App Store Submission (→ T10.3.6)

- [ ] **T10.4.1**: Complete all App Store Connect fields
- [ ] **T10.4.2**: Set pricing and availability
- [ ] **T10.4.3**: Configure all 5 in-app purchases
- [ ] **T10.4.4**: Add age rating
- [ ] **T10.4.5**: Submit for review
- [ ] **T10.4.6**: Monitor review status
- [ ] **T10.4.7**: Respond to rejection feedback if needed
- [ ] **Goal**: App approved and live

---

## Phase 11: Post-Launch (Week 10+)

### P11.1: Monitoring

- [ ] **T11.1.1**: Monitor crash reports in Xcode Organizer
- [ ] **T11.1.2**: Track App Store reviews and ratings
- [ ] **T11.1.3**: Monitor StoreKit purchase analytics
- [ ] **T11.1.4**: Track OpenAI API usage and costs
- [ ] **T11.1.5**: Collect user feedback
- [ ] **T11.1.6**: Identify top bugs for hotfix

### P11.2: Iteration Planning

- [ ] **T11.2.1**: Analyze user feedback
- [ ] **T11.2.2**: Plan next features from "Out of Scope" list
  - [ ] Transits
  - [ ] Synastry
  - [ ] Progressions
  - [ ] Social features
  - [ ] Premium subscription
  - [ ] Cloud sync

---

## Summary

**Total Estimated Tasks**: 200+
**Timeline**: 10 weeks
**Critical Path**: Phase 0 → P1 → P2 → P3 → P4 → P5 → P6 → P7 → P8 → P9 → P10
**Parallel Opportunities**: Research tasks, localization, some UI components

**Key Milestones**:
- ✅ Week 1: Foundation complete (models, structure)
- ✅ Week 2: Chart calculation working
- ✅ Week 3: Basic UI complete
- ✅ Week 4: AI integration complete
- ✅ Week 5: Purchase flow complete
- ✅ Week 6: Reports complete
- ✅ Week 7: Localization complete
- ✅ Week 8: Testing complete
- ✅ Week 9: App Store ready
- ✅ Week 10: Launch!

**Next Step**: Begin Phase 0 research tasks once dependencies (OpenAI API key, expert rules content) are obtained.
