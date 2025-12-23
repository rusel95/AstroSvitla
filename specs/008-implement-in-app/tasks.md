# Implementation Tasks: In-App Purchase System

**Feature**: 008-implement-in-app | **Branch**: `008-implement-in-app` | **Date**: 2025-12-23

**Prerequisites**: Xcode 15.2+, iOS 17+ SDK, App Store Connect access

## Task Organization

Tasks are organized by user story priority (P1, P2, P3) to enable incremental delivery. Each phase delivers testable, production-ready functionality.

**Legend**:
- `[P]` - Can be executed in parallel with other `[P]` tasks
- `[TDD]` - Write test first, then implementation
- `→` - Depends on completion of previous task

---

## Phase 0: Setup & Prerequisites (⏱️ ~30 minutes)

Foundation tasks required before any user story implementation.

### TASK-001: App Store Connect Product Configuration
**User Story**: Foundation | **Priority**: P0 | **Type**: Setup

**Description**: Configure consumable in-app purchase product in App Store Connect.

**Steps**:
1. Navigate to App Store Connect → My Apps → AstroSvitla → Features → In-App Purchases
2. Click "+" to create new product
3. Configure:
   - Type: **Consumable**
   - Reference Name: `Single Report Credit`
   - Product ID: `com.astrosvitla.report.credit.single`
   - Price: Tier 5 ($4.99 USD, ₴199 UAH)
4. Add localizations:
   - English: "1 Report Credit" / "Purchase 1 credit to generate an AI-powered astrology report for any life area (Personality, Career, Relationships, or Wellness). Each credit allows one report generation for any profile."
   - Ukrainian: "1 кредит звіту" / "Придбайте 1 кредит для створення астрологічного звіту на базі штучного інтелекту для будь-якої сфери життя (Особистість, Кар'єра, Стосунки або Здоров'я). Кожен кредит дозволяє згенерувати один звіт для будь-якого профілю."
5. Upload paywall screenshot (create placeholder in design tool)
6. Save product (don't submit for review yet)

**Acceptance Criteria**:
- ✅ Product ID `com.astrosvitla.report.credit.single` exists in App Store Connect
- ✅ Product type is Consumable
- ✅ Price is Tier 5
- ✅ English and Ukrainian localizations added
- ✅ Product status is "Ready to Submit"

**Reference**: [contracts/storekit-products.md](contracts/storekit-products.md#app-store-connect-configuration)

---

### TASK-002: [P] Create Sandbox Tester Account
**User Story**: Foundation | **Priority**: P0 | **Type**: Setup

**Description**: Create sandbox tester account for testing purchases without real charges.

**Steps**:
1. App Store Connect → Users and Access → Sandbox Testers
2. Click "+" to add new tester
3. Configure:
   - Email: `test+astrosvitla@[your-domain].com` (use real email you control)
   - Password: [Generate strong password, save in 1Password/Keychain]
   - First Name: Test
   - Last Name: Astro
   - Country: Ukraine
4. Save tester credentials securely

**Acceptance Criteria**:
- ✅ Sandbox tester account created
- ✅ Country set to Ukraine
- ✅ Credentials saved securely

**Reference**: [quickstart.md](quickstart.md#2-create-sandbox-tester)

---

### TASK-003: [P] Create Local StoreKit Configuration File
**User Story**: Foundation | **Priority**: P0 | **Type**: Setup

**Description**: Create local StoreKit configuration for testing without App Store Connect.

**Steps**:
1. Create file: `AstroSvitlaTests/Fixtures/StoreKitTestConfiguration.storekit`
2. Copy content from [contracts/storekit-products.md#local-testing](contracts/storekit-products.md#local-testing-storekit-configuration-file)
3. Update `internalID` with random number (e.g., `6736471234`)
4. In Xcode: Product → Scheme → Edit Scheme → Run → Options
5. StoreKit Configuration: Select `StoreKitTestConfiguration.storekit`
6. Apply and close

**Acceptance Criteria**:
- ✅ `StoreKitTestConfiguration.storekit` file exists
- ✅ File contains product `com.astrosvitla.report.credit.single`
- ✅ Xcode scheme configured to use local StoreKit config
- ✅ Run app in simulator → products load successfully

**Reference**: [quickstart.md](quickstart.md#3-local-storekit-configuration)

---

## Phase 1: Data Models & Schema (⏱️ ~45 minutes)

Foundation layer - SwiftData models for credit tracking and purchase records.

### TASK-004: [TDD] Write PurchaseCredit Model Tests
**User Story**: Foundation | **Priority**: P1 | **Type**: Test | **Depends on**: None

**Description**: Write tests for PurchaseCredit SwiftData model before implementation.

**Steps**:
1. Create file: `AstroSvitlaTests/Features/Purchase/Unit/PurchaseCreditTests.swift`
2. Copy test structure from [quickstart.md#test-first-credit-model-tests](quickstart.md#test-first-credit-model-tests)
3. Implement tests:
   - `testCreditCreation()` - Verify credit can be created with required fields
   - `testCreditConsumption()` - Verify credit can be marked as consumed
   - `testAvailableCredit()` - Verify `isAvailable` property logic
   - `testTransactionIDUniqueness()` - Verify transaction ID uniqueness constraint
4. Run tests: `⌘U` - **Expected: All tests fail** (model not yet implemented)

**Acceptance Criteria**:
- ✅ 4 test methods written
- ✅ All tests fail with "Type 'PurchaseCredit' not found" error
- ✅ Tests cover creation, consumption, availability check

**Reference**: [quickstart.md](quickstart.md#test-first-credit-model-tests)

---

### TASK-005: Implement PurchaseCredit SwiftData Model
**User Story**: Foundation | **Priority**: P1 | **Type**: Implementation | **Depends on**: TASK-004

**Description**: Implement PurchaseCredit model to make tests pass.

**Steps**:
1. Create file: `AstroSvitla/Models/SwiftData/PurchaseCredit.swift`
2. Copy model implementation from [data-model.md#purchasecredit](data-model.md#purchasecredit)
3. Ensure all properties match test expectations:
   - `@Attribute(.unique) var id: UUID`
   - `var reportArea: String`
   - `var purchaseDate: Date`
   - `var consumed: Bool`
   - `var consumedDate: Date?`
   - `@Attribute(.unique) var transactionID: String`
   - `var userProfileID: UUID?`
   - `var purchaseRecord: PurchaseRecord?`
4. Implement `consume(for:)` method
5. Implement `isAvailable` computed property
6. Run tests: `⌘U` - **Expected: All tests pass**

**Acceptance Criteria**:
- ✅ All 4 tests from TASK-004 pass
- ✅ Model compiles without errors
- ✅ Model uses `@Model` macro for SwiftData

**Reference**: [data-model.md](data-model.md#purchasecredit)

---

### TASK-006: [TDD] Write PurchaseRecord Model Tests
**User Story**: Foundation | **Priority**: P1 | **Type**: Test | **Depends on**: TASK-005

**Description**: Write tests for PurchaseRecord SwiftData model.

**Steps**:
1. Create file: `AstroSvitlaTests/Features/Purchase/Unit/PurchaseRecordTests.swift`
2. Implement tests:
   - `testRecordCreation()` - Verify record creation with all fields
   - `testMarkAsRestored()` - Verify restoration date tracking
   - `testIsRestoredProperty()` - Verify `isRestored` computed property
   - `testAvailableCreditsFiltering()` - Verify `availableCredits` filters correctly
   - `testConsumedCreditsFiltering()` - Verify `consumedCredits` filters correctly
3. Run tests: `⌘U` - **Expected: All tests fail**

**Acceptance Criteria**:
- ✅ 5 test methods written
- ✅ All tests fail (model not yet implemented)
- ✅ Tests use `PurchaseCredit` fixtures

**Reference**: [data-model.md](data-model.md#purchaserecord)

---

### TASK-007: Implement PurchaseRecord SwiftData Model
**User Story**: Foundation | **Priority**: P1 | **Type**: Implementation | **Depends on**: TASK-006

**Description**: Implement PurchaseRecord model with relationship to PurchaseCredit.

**Steps**:
1. Create file: `AstroSvitla/Models/SwiftData/PurchaseRecord.swift`
2. Copy model implementation from [data-model.md#purchaserecord](data-model.md#purchaserecord)
3. Implement relationship with cascade delete:
   ```swift
   @Relationship(deleteRule: .cascade, inverse: \PurchaseCredit.purchaseRecord)
   var credits: [PurchaseCredit] = []
   ```
4. Implement `markAsRestored()` method
5. Implement computed properties: `isRestored`, `availableCredits`, `consumedCredits`
6. Run tests: `⌘U` - **Expected: All tests pass**

**Acceptance Criteria**:
- ✅ All 5 tests from TASK-006 pass
- ✅ Relationship to PurchaseCredit defined with cascade delete
- ✅ Model compiles without errors

**Reference**: [data-model.md](data-model.md#purchaserecord)

---

### TASK-008: Register Models in SwiftData Schema
**User Story**: Foundation | **Priority**: P1 | **Type**: Implementation | **Depends on**: TASK-007

**Description**: Register new models in app's SwiftData container schema.

**Steps**:
1. Open `AstroSvitla/App/AstroSvitlaApp.swift` (or wherever `ModelContainer` is configured)
2. Find schema registration (likely in `@main struct AstroSvitlaApp` or ModelContainer extension)
3. Add `PurchaseCredit.self` and `PurchaseRecord.self` to schema:
   ```swift
   let schema = Schema([
       User.self,
       UserProfile.self,
       BirthChart.self,
       ReportPurchase.self,
       PurchaseCredit.self,      // ADD
       PurchaseRecord.self       // ADD
   ])
   ```
4. Build project: `⌘B` - **Expected: No errors**
5. Run app in simulator and check SwiftData container initializes

**Acceptance Criteria**:
- ✅ Models registered in schema
- ✅ App builds successfully
- ✅ App launches without crashes
- ✅ SwiftData container initializes with new models

**Reference**: [quickstart.md](quickstart.md#implement-swiftdata-models)

---

### TASK-009: Create Test Fixtures for Purchase Models
**User Story**: Foundation | **Priority**: P1 | **Type**: Test Infrastructure | **Depends on**: TASK-008

**Description**: Create fixture helpers for creating test data.

**Steps**:
1. Create file: `AstroSvitlaTests/Fixtures/PurchaseFixtures.swift`
2. Copy fixture implementations from [data-model.md#testing-data](data-model.md#testing-data)
3. Implement:
   - `PurchaseRecord.fixture()` - Creates test purchase record
   - `PurchaseCredit.fixture()` - Creates test credit
4. Add convenience parameters for customization (transaction ID, report area, consumed state)
5. Use fixtures in existing tests to reduce boilerplate

**Acceptance Criteria**:
- ✅ Fixture methods implemented
- ✅ Existing tests refactored to use fixtures
- ✅ All tests still pass

**Reference**: [data-model.md](data-model.md#fixture-data-for-tests)

---

## Phase 2: StoreKit Integration & Purchase Service (⏱️ ~90 minutes)

Core purchase functionality - StoreKit 2 integration with local verification.

### TASK-010: [TDD] Write StoreKit Product Contract Tests
**User Story**: Foundation | **Priority**: P1 | **Type**: Contract Test | **Depends on**: TASK-003

**Description**: Write contract tests to validate StoreKit product configuration.

**Steps**:
1. Create file: `AstroSvitlaTests/Features/Purchase/Contract/StoreKitProductContractTests.swift`
2. Copy test structure from [contracts/storekit-products.md#contract-tests](contracts/storekit-products.md#contract-tests)
3. Implement tests:
   - `testSingleCreditProductExists()` - Product loads from StoreKit
   - `testProductIsConsumable()` - Product type is consumable
   - `testProductPricing()` - Valid price > 0
   - `testProductDisplayName()` - Localized display name present
   - `testProductDescription()` - Localized description present
4. Run tests: `⌘U` - **Expected: Tests pass** (using local StoreKit config from TASK-003)

**Acceptance Criteria**:
- ✅ 5 contract tests written
- ✅ All tests pass against local StoreKit configuration
- ✅ Tests verify product ID, type, pricing, localization

**Reference**: [contracts/storekit-products.md](contracts/storekit-products.md#contract-tests)

---

### TASK-011: [TDD] Write PurchaseService Tests
**User Story**: US-1 | **Priority**: P1 | **Type**: Unit Test | **Depends on**: TASK-009

**Description**: Write tests for PurchaseService before implementation.

**Steps**:
1. Create file: `AstroSvitlaTests/Features/Purchase/Unit/PurchaseServiceTests.swift`
2. Set up test with in-memory ModelContext
3. Implement tests:
   - `testLoadProducts()` - Products load successfully
   - `testPurchaseCreatesCredit()` - Purchase creates PurchaseRecord and PurchaseCredit
   - `testDuplicateTransactionPrevention()` - Same transaction ID doesn't create duplicate credits
   - `testTransactionVerification()` - Only verified transactions deliver credits
   - `testTransactionFinished()` - Successful purchase calls `transaction.finish()`
4. Run tests: `⌘U` - **Expected: All tests fail** (service not implemented)

**Acceptance Criteria**:
- ✅ 5 unit tests written
- ✅ Tests use in-memory ModelContext for isolation
- ✅ All tests fail with "Type 'PurchaseService' not found"

**Reference**: [quickstart.md](quickstart.md#test-purchase-flow)

---

### TASK-012: Implement PurchaseService Core Methods
**User Story**: US-1 | **Priority**: P1 | **Type**: Implementation | **Depends on**: TASK-011

**Description**: Implement PurchaseService with StoreKit 2 purchase flow.

**Steps**:
1. Create file: `AstroSvitla/Features/Purchase/Services/PurchaseService.swift`
2. Copy service structure from [research.md#service-layer-pattern](research.md#service-layer-pattern)
3. Implement:
   - `@MainActor class PurchaseService: ObservableObject`
   - `@Published private(set) var products: [Product] = []`
   - `@Published private(set) var isPurchasing = false`
   - `@Published var purchaseError: PurchaseError?`
   - `init(context: ModelContext)`
   - `func loadProducts() async`
   - `func purchase(_ product: Product) async throws -> Transaction?`
   - Helper: `func checkVerified<T>(_ result: VerificationResult<T>) throws -> T`
   - Helper: `func deliverCredits(for transaction: Transaction, product: Product) throws`
4. Run tests: `⌘U` - **Expected: All tests pass**

**Acceptance Criteria**:
- ✅ All 5 tests from TASK-011 pass
- ✅ Service compiles without errors
- ✅ Purchase flow uses async/await StoreKit 2 APIs
- ✅ Credits delivered atomically with transaction verification

**Reference**: [quickstart.md](quickstart.md#implement-purchaseservice), [research.md](research.md#decision-2-storekit-2-not-storekit-1)

---

### TASK-013: Implement Transaction Listener
**User Story**: US-1, US-3 | **Priority**: P1 | **Type**: Implementation | **Depends on**: TASK-012

**Description**: Add transaction listener to handle interrupted purchases and background approvals.

**Steps**:
1. In `PurchaseService.swift`, add:
   - `private var transactionListener: Task<Void, Error>?`
   - `private func startTransactionListener()`
   - Call `startTransactionListener()` in `init()`
   - Cancel task in `deinit`
2. Copy implementation from [research.md#decision-8-transaction-listener-setup](research.md#decision-8-transaction-listener-setup)
3. Listener should:
   - Iterate `Transaction.updates`
   - Verify transactions with `checkVerified()`
   - Deliver credits if not already delivered
   - Finish transactions
4. Add logging for debugging

**Acceptance Criteria**:
- ✅ Transaction listener starts on service init
- ✅ Listener handles `Transaction.updates` stream
- ✅ Listener delivers credits for unfinished transactions
- ✅ Listener cancelled in deinit

**Reference**: [research.md](research.md#decision-8-transaction-listener-setup)

---

### TASK-014: [TDD] Write CreditManager Tests
**User Story**: US-1, US-2 | **Priority**: P1 | **Type**: Unit Test | **Depends on**: TASK-009

**Description**: Write tests for credit allocation and consumption logic.

**Steps**:
1. Create file: `AstroSvitlaTests/Features/Purchase/Unit/CreditManagerTests.swift`
2. Implement tests:
   - `testGetAvailableCredits()` - Returns only unconsumed credits
   - `testGetAvailableCreditCount()` - Returns correct count
   - `testConsumeCredit()` - Marks credit as consumed and links to profile
   - `testConsumeCreditInsufficientCredits()` - Throws error when no credits available
   - `testGetCreditHistory()` - Returns credits for specific profile
3. Run tests: `⌘U` - **Expected: All tests fail**

**Acceptance Criteria**:
- ✅ 5 unit tests written
- ✅ Tests use fixtures and in-memory context
- ✅ All tests fail (CreditManager not implemented)

**Reference**: [data-model.md](data-model.md#queries)

---

### TASK-015: Implement CreditManager Service
**User Story**: US-1, US-2 | **Priority**: P1 | **Type**: Implementation | **Depends on**: TASK-014

**Description**: Implement service for credit allocation, consumption, and querying.

**Steps**:
1. Create file: `AstroSvitla/Features/Purchase/Services/CreditManager.swift`
2. Copy structure from [research.md#service-layer-pattern](research.md#service-layer-pattern)
3. Implement methods:
   - `func getAvailableCredits() -> [PurchaseCredit]`
   - `func getAvailableCreditCount() -> Int`
   - `func hasAvailableCredits() -> Bool`
   - `func consumeCredit(for reportArea: ReportArea, profileID: UUID) throws -> PurchaseCredit`
   - `func getCreditHistory(for profileID: UUID) -> [PurchaseCredit]`
4. Use SwiftData queries from [data-model.md#queries](data-model.md#queries)
5. Run tests: `⌘U` - **Expected: All tests pass**

**Acceptance Criteria**:
- ✅ All 5 tests from TASK-014 pass
- ✅ Service uses SwiftData `FetchDescriptor` with predicates
- ✅ Credit consumption is atomic (save after marking consumed)
- ✅ Throws error when insufficient credits

**Reference**: [data-model.md](data-model.md#queries)

---

### TASK-016: Define PurchaseError Enum
**User Story**: US-1 | **Priority**: P1 | **Type**: Implementation | **Depends on**: None

**Description**: Create error types for purchase flow with localized messages.

**Steps**:
1. Create file: `AstroSvitla/Features/Purchase/Models/PurchaseError.swift`
2. Copy error enum from [research.md#error-handling](research.md#error-handling)
3. Implement:
   ```swift
   enum PurchaseError: LocalizedError {
       case networkError
       case userCancelled
       case failedVerification(VerificationResult<Transaction>.VerificationError)
       case insufficientCredits
       case productNotFound
       case productLoadFailed(Error)

       var errorDescription: String? { ... }
   }
   ```
4. Add Ukrainian localization strings
5. Build: `⌘B` - **Expected: No errors**

**Acceptance Criteria**:
- ✅ All error cases defined
- ✅ Each case has localized error description
- ✅ Ukrainian translations added to `Localizable.strings`

**Reference**: [research.md](research.md#error-handling)

---

## Phase 3: User Story 4 - Browse Reports UI (⏱️ ~45 minutes)

**Priority: P1** - Must implement before US-1 (users need to see reports to purchase)

### TASK-017: Add Ukrainian Localization Strings
**User Story**: US-4 | **Priority**: P1 | **Type**: Localization | **Depends on**: None

**Description**: Add all purchase-related Ukrainian localization strings.

**Steps**:
1. Open `AstroSvitla/Resources/uk.lproj/Localizable.strings`
2. Add strings from [research.md#localization](research.md#localization):
   - `purchase.paywall.title`
   - `purchase.paywall.description`
   - `purchase.button.buy`
   - `purchase.credits.available`
   - `purchase.error.network`
   - `purchase.error.insufficient`
   - `purchase.restore.title`
   - `purchase.report.locked`
   - `purchase.report.available`
3. Add English equivalents in `en.lproj/Localizable.strings`
4. Build: `⌘B` - **Expected: No errors**

**Acceptance Criteria**:
- ✅ All strings added to Ukrainian localization
- ✅ English fallbacks added
- ✅ No compilation errors

**Reference**: [quickstart.md](quickstart.md#phase-5-localization-15-minutes)

---

### TASK-018: Update Report List to Show Locked/Unlocked State
**User Story**: US-4 | **Priority**: P1 | **Type**: UI Implementation | **Depends on**: TASK-017

**Description**: Modify existing report list to show which reports are locked (no credits) vs unlocked (credits available).

**Steps**:
1. Find existing report list view (likely `ReportListView.swift` or similar)
2. Inject `CreditManager` via environment object:
   ```swift
   @EnvironmentObject var creditManager: CreditManager
   ```
3. For each report area, check if credits available:
   ```swift
   let hasCredit = creditManager.hasAvailableCredits()
   ```
4. Show lock icon or "Locked" badge when `hasCredit == false`
5. Show unlock icon or "Available" badge when `hasCredit == true`
6. Update report row UI to visually distinguish locked vs unlocked
7. Test in simulator with 0 credits → All reports show locked

**Acceptance Criteria**:
- ✅ Report list displays locked/unlocked state per report
- ✅ Visual distinction clear (lock icon, badge, opacity, etc.)
- ✅ State updates reactively when credits change
- ✅ Localized strings used for "Locked" / "Available"

**Reference**: FR-014, [research.md](research.md#integration-points)

---

### TASK-019: [UI Test] Verify Report Browse Experience
**User Story**: US-4 | **Priority**: P1 | **Type**: UI Test | **Depends on**: TASK-018

**Description**: Write UI test to verify browsing reports without purchase.

**Steps**:
1. Create file: `AstroSvitlaUITests/Features/Purchase/ReportBrowseUITests.swift`
2. Implement test:
   - Launch app
   - Navigate to reports screen
   - Verify 4 report types displayed
   - Verify all reports show "Locked" state (no credits initially)
   - Tap on locked report
   - Verify paywall does NOT open yet (implement in next phase)
3. Run UI test: `⌘U`

**Acceptance Criteria**:
- ✅ UI test passes
- ✅ All 4 report types visible
- ✅ Locked state displayed for all reports when no credits

**Reference**: US-4 Acceptance Scenarios

---

## Phase 4: User Story 1 - Single Report Purchase (⏱️ ~90 minutes)

**Priority: P1** - Core monetization flow

### TASK-020: [TDD] Write PaywallViewModel Tests
**User Story**: US-1 | **Priority**: P1 | **Type**: Unit Test | **Depends on**: TASK-015

**Description**: Write tests for paywall presentation and purchase logic.

**Steps**:
1. Create file: `AstroSvitlaTests/Features/Purchase/Unit/PaywallViewModelTests.swift`
2. Implement tests:
   - `testProductLoadsOnInit()` - Product loads when view model initialized
   - `testPurchaseUpdatesIsPurchasing()` - `isPurchasing` toggles during purchase
   - `testSuccessfulPurchase()` - Purchase completes and dismisses paywall
   - `testPurchaseCancellation()` - User cancellation doesn't throw error
   - `testPurchaseError()` - Network error sets error state
3. Run tests: `⌘U` - **Expected: All tests fail**

**Acceptance Criteria**:
- ✅ 5 unit tests written
- ✅ Tests use mock PurchaseService
- ✅ All tests fail (ViewModel not implemented)

**Reference**: [research.md](research.md#mvvm-integration)

---

### TASK-021: Implement PaywallViewModel
**User Story**: US-1 | **Priority**: P1 | **Type**: Implementation | **Depends on**: TASK-020

**Description**: Implement view model for paywall presentation logic.

**Steps**:
1. Create file: `AstroSvitla/Features/Purchase/ViewModels/PaywallViewModel.swift`
2. Copy structure from [research.md#mvvm-integration](research.md#mvvm-integration)
3. Implement:
   ```swift
   @Observable
   @MainActor
   class PaywallViewModel {
       var product: Product?
       var isPurchasing = false
       var error: PurchaseError?
       var purchaseCompleted = false

       private let purchaseService: PurchaseService

       func loadProduct() async
       func purchase() async
   }
   ```
4. Run tests: `⌘U` - **Expected: All tests pass**

**Acceptance Criteria**:
- ✅ All 5 tests from TASK-020 pass
- ✅ ViewModel uses `@Observable` macro
- ✅ Purchase method handles success, cancellation, and errors

**Reference**: [research.md](research.md#mvvm-integration)

---

### TASK-022: Implement PaywallView UI
**User Story**: US-1 | **Priority**: P1 | **Type**: UI Implementation | **Depends on**: TASK-021

**Description**: Create paywall SwiftUI view with product information and purchase button.

**Steps**:
1. Create file: `AstroSvitla/Features/Purchase/Views/PaywallView.swift`
2. Copy structure from [quickstart.md#paywallview](quickstart.md#paywallview)
3. Implement UI:
   - Header: Localized title "Отримати звіт"
   - Description: AI-powered analysis explanation
   - Product display: Name, description, price
   - Purchase button: "Purchase for [displayPrice]"
   - Cancel button
   - Loading indicator when `isPurchasing`
   - Error alert when `error != nil`
4. Use `@State var viewModel: PaywallViewModel`
5. Test in preview with mock data

**Acceptance Criteria**:
- ✅ Paywall displays product information
- ✅ Purchase button initiates purchase
- ✅ Loading state shows activity indicator
- ✅ Error state shows alert
- ✅ Cancel button dismisses sheet
- ✅ Ukrainian localization displays correctly

**Reference**: [quickstart.md](quickstart.md#paywallview)

---

### TASK-023: Show Paywall When Locked Report Tapped
**User Story**: US-1 | **Priority**: P1 | **Type**: Integration | **Depends on**: TASK-022

**Description**: Update report list to show paywall sheet when user taps locked report.

**Steps**:
1. In report list view, add:
   ```swift
   @State private var showPaywall = false
   @State private var selectedReportArea: ReportArea?
   ```
2. On report tap:
   - If `creditManager.hasAvailableCredits()` → Navigate to generation
   - Else → Set `showPaywall = true`
3. Present paywall as sheet:
   ```swift
   .sheet(isPresented: $showPaywall) {
       PaywallView(reportArea: selectedReportArea)
           .environmentObject(purchaseService)
   }
   ```
4. Test in simulator:
   - Tap locked report → Paywall opens
   - Tap cancel → Paywall closes

**Acceptance Criteria**:
- ✅ Tapping locked report opens paywall
- ✅ Paywall displays correct product
- ✅ Cancel closes paywall
- ✅ 2-3 tap requirement met (FR-004)

**Reference**: US-1 Acceptance Scenario 1

---

### TASK-024: Integrate Purchase with Report Generation
**User Story**: US-1 | **Priority**: P1 | **Type**: Integration | **Depends on**: TASK-023

**Description**: After successful purchase, automatically navigate to report generation.

**Steps**:
1. In `PaywallViewModel`, add:
   ```swift
   var onPurchaseComplete: ((ReportArea) -> Void)?
   ```
2. After purchase succeeds, call `onPurchaseComplete?(reportArea)`
3. In report list, pass closure:
   ```swift
   PaywallView(reportArea: area) {
       navigateToReportGeneration(area: $0)
   }
   ```
4. Find existing report generation view and navigate to it
5. Test flow: Tap locked report → Purchase → Generate report

**Acceptance Criteria**:
- ✅ Successful purchase navigates to generation screen
- ✅ Report generation screen receives report area
- ✅ User can generate report immediately (FR-009)
- ✅ Flow completes in <5 seconds (SC-007)

**Reference**: US-1 Acceptance Scenario 3

---

### TASK-025: Consume Credit on Report Generation
**User Story**: US-1 | **Priority**: P1 | **Type**: Integration | **Depends on**: TASK-024

**Description**: Modify report generation to consume credit before generating report.

**Steps**:
1. Find existing report generation logic (likely in ViewModel or Service)
2. Inject `CreditManager` via environment or initializer
3. Before generating report:
   ```swift
   // Check credits
   guard creditManager.hasAvailableCredits() else {
       throw ReportError.insufficientCredits
   }

   // Generate report
   let report = try await aiService.generateReport(...)

   // Consume credit AFTER successful generation
   try creditManager.consumeCredit(for: area, profileID: profile.id)

   // Save report (already implemented)
   ```
4. Test: Purchase → Generate → Verify credit consumed

**Acceptance Criteria**:
- ✅ Credit checked before generation
- ✅ Credit consumed after successful generation
- ✅ Error shown if insufficient credits
- ✅ Credit NOT consumed if generation fails

**Reference**: US-1 Acceptance Scenario 4, [research.md](research.md#integration-points)

---

### TASK-026: [Integration Test] End-to-End Purchase Flow
**User Story**: US-1 | **Priority**: P1 | **Type**: Integration Test | **Depends on**: TASK-025

**Description**: Write integration test for complete purchase-to-report flow.

**Steps**:
1. Create file: `AstroSvitlaTests/Features/Purchase/Integration/PurchaseToReportFlowTests.swift`
2. Copy test structure from [quickstart.md#integration-test](quickstart.md#integration-test)
3. Implement test:
   - Load products
   - Purchase product
   - Verify PurchaseRecord created
   - Verify PurchaseCredit created (available)
   - Consume credit for report
   - Verify credit marked as consumed
   - Verify credit count = 0
4. Run test: `⌘U`

**Acceptance Criteria**:
- ✅ Integration test passes
- ✅ Test covers purchase → credit allocation → consumption
- ✅ Transaction integrity verified (SC-004)

**Reference**: [quickstart.md](quickstart.md#integration-test)

---

### TASK-027: Manual Testing - US-1 Complete Flow
**User Story**: US-1 | **Priority**: P1 | **Type**: Manual Test | **Depends on**: TASK-026

**Description**: Manually test complete flow on device with sandbox account.

**Steps**:
1. Build and run app on physical device (not simulator for sandbox testing)
2. Sign out of production App Store (Settings → App Store → Sign Out)
3. Navigate to reports screen
4. Tap locked report → Verify paywall opens
5. Tap "Purchase" → Sign in with sandbox tester when prompted
6. Complete purchase with Face ID/password
7. Verify:
   - Purchase completes successfully
   - Paywall dismisses
   - Report generation screen opens
   - Report generates successfully
   - Generated report appears in history
   - Credit consumed (report now locked again)
8. Document any issues

**Acceptance Criteria**:
- ✅ Complete flow works end-to-end on device
- ✅ Purchase completes in sandbox
- ✅ Credit delivered and consumed correctly
- ✅ Report generated successfully
- ✅ All US-1 acceptance scenarios pass

**Reference**: [quickstart.md](quickstart.md#manual-testing-with-sandbox)

---

## Phase 5: User Story 2 - Repeat Purchases (⏱️ ~30 minutes)

**Priority: P2** - Enables recurring revenue

### TASK-028: Verify Repeat Purchase Flow Works
**User Story**: US-2 | **Priority**: P2 | **Type**: Manual Test | **Depends on**: TASK-027

**Description**: Test that users can purchase same report type multiple times.

**Steps**:
1. Continue from TASK-027 state (1 report already generated)
2. Navigate back to reports list
3. Verify report shows "Locked" state again (credit consumed)
4. Tap same report type
5. Purchase again with sandbox account
6. Verify new credit delivered
7. Generate report for different profile
8. Verify credit consumed
9. Check purchase history shows 2 transactions

**Acceptance Criteria**:
- ✅ User can purchase same report type multiple times
- ✅ Each purchase creates new credit
- ✅ Credits consumed independently per generation
- ✅ Purchase history shows all transactions

**Reference**: US-2 Acceptance Scenarios

---

### TASK-029: Test Multi-Profile Report Generation
**User Story**: US-2 | **Priority**: P2 | **Type**: Manual Test | **Depends on**: TASK-028

**Description**: Verify credits work across different user profiles.

**Steps**:
1. Create second user profile in app
2. Purchase credit while on first profile
3. Switch to second profile
4. Verify credit still available (global pool)
5. Generate report for second profile
6. Verify credit consumed
7. Check credit history shows correct profile ID

**Acceptance Criteria**:
- ✅ Credits available across all profiles (global pool)
- ✅ Credit consumption tracks which profile used it
- ✅ Report history shows correct profile association

**Reference**: US-2 Acceptance Scenario 4

---

## Phase 6: User Story 3 - Restore Purchases (⏱️ ~60 minutes)

**Priority: P3** - Required for platform compliance

### TASK-030: [TDD] Write Restore Purchases Tests
**User Story**: US-3 | **Priority**: P3 | **Type**: Unit Test | **Depends on**: TASK-015

**Description**: Write tests for restore purchases functionality.

**Steps**:
1. Add to `AstroSvitlaTests/Features/Purchase/Unit/PurchaseServiceTests.swift`
2. Implement tests:
   - `testRestorePurchasesDeliversUnfinishedCredits()` - Unfinished transactions deliver credits
   - `testRestorePurchasesSkipsDuplicates()` - Already delivered credits not duplicated
   - `testRestorePurchasesMarksAsRestored()` - PurchaseRecord.restoredDate set
3. Run tests: `⌘U` - **Expected: Tests fail** (restore not implemented)

**Acceptance Criteria**:
- ✅ 3 tests written for restore functionality
- ✅ Tests verify credit delivery and duplicate prevention
- ✅ All tests fail (feature not implemented)

**Reference**: [research.md](research.md#decision-7-restore-purchases-behavior)

---

### TASK-031: Implement Restore Purchases Method
**User Story**: US-3 | **Priority**: P3 | **Type**: Implementation | **Depends on**: TASK-030

**Description**: Implement restore purchases in PurchaseService.

**Steps**:
1. In `PurchaseService.swift`, add:
   ```swift
   @MainActor
   func restorePurchases() async throws {
       for await result in Transaction.currentEntitlements {
           guard case .verified(let transaction) = result else { continue }

           // Check if already delivered
           if !isTransactionDelivered(transaction.id) {
               deliverCredits(for: transaction)

               // Mark as restored
               if let record = findPurchaseRecord(transactionID: transaction.id) {
                   record.markAsRestored()
                   try context.save()
               }
           }

           await transaction.finish()
       }
   }
   ```
2. Add helper: `func isTransactionDelivered(_ transactionID: UInt64) -> Bool`
3. Add helper: `func findPurchaseRecord(transactionID: UInt64) -> PurchaseRecord?`
4. Run tests: `⌘U` - **Expected: All tests pass**

**Acceptance Criteria**:
- ✅ All 3 tests from TASK-030 pass
- ✅ Restore delivers unfinished credits
- ✅ Restore skips already delivered credits
- ✅ Restored purchases marked in PurchaseRecord

**Reference**: [research.md](research.md#decision-7-restore-purchases-behavior)

---

### TASK-032: Add Restore Purchases Button to UI
**User Story**: US-3 | **Priority**: P3 | **Type**: UI Implementation | **Depends on**: TASK-031

**Description**: Add restore purchases button to settings or paywall.

**Steps**:
1. Decide placement: Settings screen or Paywall footer
2. Add button:
   ```swift
   Button("Restore Purchases") {
       Task {
           isRestoring = true
           try await purchaseService.restorePurchases()
           isRestoring = false
           showSuccessAlert = true
       }
   }
   .disabled(isRestoring)
   ```
3. Add loading indicator during restore
4. Show success/failure alert after completion
5. Use localized string `"purchase.restore.title"`

**Acceptance Criteria**:
- ✅ Restore button visible in appropriate location
- ✅ Button shows loading state during restore
- ✅ Success/failure feedback shown to user
- ✅ Ukrainian localization used

**Reference**: US-3 Acceptance Scenario 1

---

### TASK-033: Manual Testing - Restore Purchases
**User Story**: US-3 | **Priority**: P3 | **Type**: Manual Test | **Depends on**: TASK-032

**Description**: Test restore purchases on device.

**Steps**:
1. On device, make purchase with sandbox account
2. Before generating report, delete app
3. Reinstall app from Xcode
4. Tap "Restore Purchases" button
5. Verify:
   - Restore completes successfully
   - Credit appears in available balance
   - Can generate report with restored credit
6. Test consumable behavior:
   - Generate report (consume credit)
   - Delete and reinstall app
   - Tap "Restore Purchases"
   - Verify: Credit does NOT restore (expected for consumables)

**Acceptance Criteria**:
- ✅ Unfinished purchases restore successfully
- ✅ Consumed credits do NOT restore (expected)
- ✅ Restore completes in <10 seconds (SC-003)
- ✅ User feedback clear about consumable behavior

**Reference**: US-3 Acceptance Scenarios

---

## Phase 7: Integration & Polish (⏱️ ~45 minutes)

### TASK-034: Inject PurchaseService into App Environment
**User Story**: Foundation | **Priority**: P1 | **Type**: Integration | **Depends on**: TASK-012

**Description**: Initialize PurchaseService at app launch and inject via environment.

**Steps**:
1. Open `AstroSvitla/App/AstroSvitlaApp.swift`
2. Add:
   ```swift
   @StateObject private var purchaseService: PurchaseService

   init() {
       // ... existing setup ...

       let context = sharedModelContainer.mainContext
       let service = PurchaseService(context: context)
       _purchaseService = StateObject(wrappedValue: service)
   }
   ```
3. Inject into environment:
   ```swift
   WindowGroup {
       ContentView()
           .environmentObject(purchaseService)
   }
   ```
4. Build and run: Verify service initializes and products load

**Acceptance Criteria**:
- ✅ PurchaseService initialized on app launch
- ✅ Transaction listener starts automatically
- ✅ Products load successfully
- ✅ Service available via environment object throughout app

**Reference**: [research.md](research.md#app-launch-integration)

---

### TASK-035: Inject CreditManager into App Environment
**User Story**: Foundation | **Priority**: P1 | **Type**: Integration | **Depends on**: TASK-015

**Description**: Initialize CreditManager and inject via environment.

**Steps**:
1. In `AstroSvitlaApp.swift`, add:
   ```swift
   @StateObject private var creditManager: CreditManager

   init() {
       // ... existing setup ...
       let creditMgr = CreditManager(context: context)
       _creditManager = StateObject(wrappedValue: creditMgr)
   }
   ```
2. Inject into environment:
   ```swift
   WindowGroup {
       ContentView()
           .environmentObject(purchaseService)
           .environmentObject(creditManager)
   }
   ```
3. Build and run

**Acceptance Criteria**:
- ✅ CreditManager initialized on app launch
- ✅ Manager available via environment object
- ✅ Credit balance queries work correctly

---

### TASK-036: Add Purchase Logging to Sentry
**User Story**: Foundation | **Priority**: P2 | **Type**: Observability | **Depends on**: TASK-034

**Description**: Add Sentry breadcrumbs for purchase events to aid debugging.

**Steps**:
1. In `PurchaseService.purchase()`, add breadcrumb after successful purchase:
   ```swift
   SentrySDK.addBreadcrumb(Breadcrumb(
       level: .info,
       category: "purchase",
       message: "Credit purchased",
       data: ["productId": product.id, "price": product.price]
   ))
   ```
2. Add breadcrumbs for:
   - Product load success/failure
   - Purchase initiated
   - Purchase completed
   - Purchase failed
   - Restore purchases completed
3. Add Sentry tags: `service: "purchase"`

**Acceptance Criteria**:
- ✅ Breadcrumbs logged for all purchase events
- ✅ Failed purchases logged with error context
- ✅ No sensitive data (transaction IDs OK, no user info)

**Reference**: Similar to existing Sentry integration in codebase

---

### TASK-037: Test Coverage Report
**User Story**: Foundation | **Priority**: P1 | **Type**: Quality | **Depends on**: TASK-026

**Description**: Verify test coverage meets constitution requirement (≥80%).

**Steps**:
1. Enable code coverage in Xcode: Product → Scheme → Edit Scheme → Test → Options → Code Coverage
2. Run all tests: `⌘U`
3. View coverage report: Show Report Navigator → Coverage tab
4. Verify coverage:
   - Overall: ≥80%
   - Critical paths (PurchaseService, CreditManager): 100%
   - UI layer: ≥60% acceptable
5. Add tests for uncovered code paths if needed

**Acceptance Criteria**:
- ✅ Test coverage ≥80% overall
- ✅ PurchaseService coverage 100%
- ✅ CreditManager coverage 100%
- ✅ Critical purchase path coverage 100%

**Reference**: Constitution Section III - Test-First Reliability

---

### TASK-038: Performance Testing - Purchase Flow
**User Story**: US-1 | **Priority**: P1 | **Type**: Performance | **Depends on**: TASK-027

**Description**: Measure and verify purchase flow meets performance targets.

**Steps**:
1. Add performance measurement in manual test:
   ```swift
   let start = Date()
   // ... complete purchase flow ...
   let duration = Date().timeIntervalSince(start)
   print("Purchase flow completed in \(duration)s")
   ```
2. Measure:
   - Tap locked report → Paywall opens: <100ms
   - Tap purchase → Transaction completes: <5s (depends on network)
   - Credit delivered → Report generation ready: <1s
3. Test on device with good network connection
4. Document results

**Acceptance Criteria**:
- ✅ Paywall opens in <100ms (FR-004)
- ✅ Purchase completes in <5s (SC-007)
- ✅ Total flow (tap to ready): <10s
- ✅ Performance targets met or documented exceptions

**Reference**: SC-007, FR-004, [plan.md](plan.md#performance-goals)

---

### TASK-039: Final Manual Test - All User Stories
**User Story**: All | **Priority**: P1 | **Type**: Acceptance Test | **Depends on**: TASK-038

**Description**: Complete end-to-end acceptance testing for all user stories.

**Steps**:
1. Test US-1 (Single Purchase):
   - Verify all 5 acceptance scenarios from spec
2. Test US-2 (Repeat Purchase):
   - Verify all 4 acceptance scenarios from spec
3. Test US-3 (Restore):
   - Verify all 4 acceptance scenarios from spec
4. Test US-4 (Browse):
   - Verify all 2 acceptance scenarios from spec
5. Test Edge Cases:
   - Purchase cancellation
   - Network failure during purchase
   - App killed during purchase → Restart → Restore
   - Rapid repeated purchases
6. Document any failures or issues

**Acceptance Criteria**:
- ✅ All US-1 scenarios pass (5/5)
- ✅ All US-2 scenarios pass (4/4)
- ✅ All US-3 scenarios pass (4/4)
- ✅ All US-4 scenarios pass (2/2)
- ✅ Critical edge cases handled gracefully
- ✅ Success criteria met (SC-001 through SC-009)

**Reference**: [spec.md](spec.md#user-scenarios--testing)

---

### TASK-040: Update Documentation
**User Story**: Foundation | **Priority**: P2 | **Type**: Documentation | **Depends on**: TASK-039

**Description**: Update project documentation with implementation details.

**Steps**:
1. Update `CLAUDE.md` with purchase system info (if not auto-updated)
2. Create `AstroSvitla/Features/Purchase/README.md` with:
   - Overview of purchase system
   - How to test with sandbox
   - How to configure products
   - Troubleshooting common issues
3. Update main project README if needed
4. Document any deviations from plan

**Acceptance Criteria**:
- ✅ Purchase system documented
- ✅ Testing instructions clear
- ✅ Troubleshooting guide complete

---

## Phase 8: Submission Preparation (⏱️ ~15 minutes)

### TASK-041: Prepare App Store Screenshots
**User Story**: Foundation | **Priority**: P2 | **Type**: App Store | **Depends on**: TASK-039

**Description**: Create screenshots showing purchase flow for App Store review.

**Steps**:
1. Take screenshots on iPhone:
   - Paywall view with product and price
   - Purchase completion confirmation
   - Report generation after purchase
   - Reports list with locked/unlocked states
2. Add Ukrainian localization to screenshots
3. Upload to App Store Connect product configuration (TASK-001)

**Acceptance Criteria**:
- ✅ 4+ screenshots captured
- ✅ Screenshots show purchase flow clearly
- ✅ Ukrainian text visible in screenshots

---

### TASK-042: Update App Store Product Metadata
**User Story**: Foundation | **Priority**: P2 | **Type**: App Store | **Depends on**: TASK-041

**Description**: Finalize product configuration in App Store Connect.

**Steps**:
1. Review product configuration from TASK-001
2. Upload final screenshots
3. Verify localizations (English + Ukrainian)
4. Set "Cleared for Sale" to Yes
5. Save (ready to submit with app version)

**Acceptance Criteria**:
- ✅ Product metadata complete
- ✅ Screenshots uploaded
- ✅ Product ready for review

---

## Task Summary

**Total Estimated Time**: ~7-8 hours

**Phase Breakdown**:
- Phase 0 (Setup): 30 min
- Phase 1 (Data Models): 45 min
- Phase 2 (StoreKit): 90 min
- Phase 3 (Browse UI): 45 min
- Phase 4 (Purchase Flow): 90 min
- Phase 5 (Repeat Purchase): 30 min
- Phase 6 (Restore): 60 min
- Phase 7 (Integration): 45 min
- Phase 8 (Submission): 15 min

**Task Count**: 42 tasks

**User Story Coverage**:
- US-1 (P1): Tasks 20-27 (Core purchase flow)
- US-2 (P2): Tasks 28-29 (Repeat purchases)
- US-3 (P3): Tasks 30-33 (Restore)
- US-4 (P1): Tasks 17-19 (Browse reports)
- Foundation: Tasks 1-16, 34-42

**Test Coverage**:
- Contract Tests: 1 suite (TASK-010)
- Unit Tests: 4 suites (TASK-004, 006, 011, 014, 020, 030)
- Integration Tests: 1 suite (TASK-026)
- UI Tests: 1 suite (TASK-019)
- Manual Tests: 4 sessions (TASK-027, 028, 029, 033, 039)

**Parallel Execution Opportunities**:
- TASK-002 and TASK-003 can run in parallel with TASK-001
- TASK-004 and TASK-006 can run in parallel
- TASK-017 can run in parallel with data model tasks
- All test writing tasks can start while previous implementation is in progress (TDD)

## Dependencies Graph

```
TASK-001 (App Store Config)
  └─→ TASK-010 (Contract Tests)

TASK-002 (Sandbox Tester) [P]
TASK-003 (StoreKit Config) [P]

TASK-004 (Credit Model Tests)
  └─→ TASK-005 (Implement Credit Model)
      └─→ TASK-006 (Record Model Tests)
          └─→ TASK-007 (Implement Record Model)
              └─→ TASK-008 (Register Schema)
                  └─→ TASK-009 (Fixtures)

TASK-009
  ├─→ TASK-011 (Purchase Service Tests)
  │   └─→ TASK-012 (Implement Purchase Service)
  │       └─→ TASK-013 (Transaction Listener)
  │
  └─→ TASK-014 (Credit Manager Tests)
      └─→ TASK-015 (Implement Credit Manager)

TASK-016 (Error Enum) [P]
TASK-017 (Localization) [P]

TASK-015
  └─→ TASK-018 (Update Report List)
      └─→ TASK-019 (UI Test - Browse)
      └─→ TASK-020 (Paywall ViewModel Tests)
          └─→ TASK-021 (Implement Paywall ViewModel)
              └─→ TASK-022 (Paywall View)
                  └─→ TASK-023 (Show Paywall on Tap)
                      └─→ TASK-024 (Navigate to Generation)
                          └─→ TASK-025 (Consume Credit)
                              └─→ TASK-026 (Integration Test)
                                  └─→ TASK-027 (Manual Test US-1)

TASK-027
  └─→ TASK-028 (Manual Test US-2)
      └─→ TASK-029 (Manual Test Multi-Profile)

TASK-015
  └─→ TASK-030 (Restore Tests)
      └─→ TASK-031 (Implement Restore)
          └─→ TASK-032 (Restore Button UI)
              └─→ TASK-033 (Manual Test Restore)

TASK-012
  └─→ TASK-034 (Inject Purchase Service)

TASK-015
  └─→ TASK-035 (Inject Credit Manager)

TASK-034
  └─→ TASK-036 (Sentry Logging)

TASK-026
  └─→ TASK-037 (Coverage Report)
      └─→ TASK-038 (Performance Test)
          └─→ TASK-039 (Final Acceptance Test)
              └─→ TASK-040 (Documentation)
                  └─→ TASK-041 (Screenshots)
                      └─→ TASK-042 (App Store Metadata)
```

## Next Steps

After completing all tasks:

1. **Code Review**: Review implementation against spec and plan
2. **Final Testing**: Complete acceptance testing on physical device
3. **Submit for Review**: Include in-app purchase in app version submission
4. **Monitor**: Watch for user feedback and purchase metrics post-launch

## References

- [Specification](spec.md) - User stories and requirements
- [Implementation Plan](plan.md) - Architecture and decisions
- [Data Model](data-model.md) - SwiftData schema
- [StoreKit Contract](contracts/storekit-products.md) - Product configuration
- [Quickstart Guide](quickstart.md) - Step-by-step implementation guide
- [Research](research.md) - Technical decisions and patterns
