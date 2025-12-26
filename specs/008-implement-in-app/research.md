# Research: In-App Purchase Implementation

**Feature**: 008-implement-in-app
**Date**: 2025-12-23
**Status**: Complete

## Overview

Research findings for implementing consumable in-app purchases using StoreKit 2 for the Zorya natal chart app. Focus on local-only architecture with SwiftData persistence and no server-side validation.

## Key Decisions

### Decision 1: Consumable Product Type

**Decision**: Use **Consumable** in-app purchases (not Non-Consumable)

**Rationale**:
- Spec requires "1 purchase = 1 report generation" with ability to buy same report type multiple times
- Global credit pool model where credits are consumed on use
- Enables recurring revenue as users purchase additional credits
- Aligns with "buy credits for different profiles" requirement

**Alternatives Considered**:
- **Non-Consumable**: Rejected - would allow unlimited report generation after single purchase per type
- **Hybrid Model** (Consumable + Non-Consumable unlocks): Rejected - adds complexity beyond MVP scope

**Implementation Note**: Existing codebase has StoreKit contract spec for Non-Consumable products at `/specs/001-astrosvitla-ios-native/contracts/storekit.md`. This will need to be updated or superseded by new contract.

### Decision 2: StoreKit 2 (Not StoreKit 1)

**Decision**: Use StoreKit 2 modern async/await APIs

**Rationale**:
- Native iOS 17+ support (matches constitution requirement)
- Automatic cryptographic transaction verification without server
- async/await integration with Swift concurrency
- Built-in transaction listener via `Transaction.updates`
- Simpler product loading via `Product.products(for:)`

**Alternatives Considered**:
- **StoreKit 1**: Rejected - deprecated APIs, requires manual receipt validation
- **Server-side Receipt Validation**: Rejected - spec explicitly requires no server backend

**Code Pattern**:
```swift
// StoreKit 2 purchase flow
let result = try await product.purchase()
switch result {
case .success(let verificationResult):
    let transaction = try checkVerified(verificationResult)
    // Deliver credits
    await transaction.finish()
}
```

### Decision 3: Local Credit Tracking with SwiftData

**Decision**: Track purchase credits in SwiftData models (not UserDefaults or property lists)

**Rationale**:
- Constitution mandates SwiftData for all persistence
- Enables relational data: credits → transactions → reports
- Supports querying credit history and audit trail
- Automatic iCloud sync if enabled (via SwiftData)
- Type-safe queries with `@Model` and `#Predicate`

**Alternatives Considered**:
- **UserDefaults**: Rejected - no relational data, no audit trail, difficult to query
- **Property List Files**: Rejected - manual serialization, no type safety
- **CoreData**: Rejected - constitution specifies SwiftData

**Data Model**:
```swift
@Model
final class PurchaseCredit {
    var id: UUID
    var reportType: ReportArea
    var purchaseDate: Date
    var consumed: Bool
    var consumedDate: Date?
    var transactionID: String  // StoreKit transaction ID
    var userProfileID: UUID?   // Profile credit was used for
}
```

### Decision 4: Global Credit Pool (Not Profile-Specific)

**Decision**: Credits exist in global pool, usable for any profile

**Rationale**:
- Clarified in spec session: "Global credit pool - credits can be used for any profile"
- Simpler UX: users don't need to decide which profile to buy for
- Fewer purchase flows: single purchase button works for all profiles
- Easier credit display: single "You have X credits" vs per-profile tracking

**Alternatives Considered**:
- **Profile-Specific Credits**: Rejected - added complexity, unclear UX, conflicts with spec clarification
- **User Chooses Profile at Purchase**: Rejected - adds extra step, violates 2-3 tap requirement

**Implementation**: Track which profile a credit was *used* for (generation history), but credit itself is not locked to profile until consumed.

### Decision 5: Product Configuration

**Decision**: Single product at $4.99 (no packs for MVP)

**Rationale**:
- Spec clarified: "All reports same price: $4.99"
- Simplicity for MVP launch before New Year
- Can add credit packs (5/$19.99, 10/$34.99) post-MVP
- Reduces App Store Connect configuration

**Alternatives Considered**:
- **Credit Packs**: Deferred to post-MVP - adds pricing complexity
- **Per-Report-Type Pricing**: Rejected - spec clarified uniform pricing

**Product ID**: `com.astrosvitla.report.credit.single`

### Decision 6: Purchase Verification Strategy

**Decision**: StoreKit 2 automatic verification only (no server validation)

**Rationale**:
- Spec explicitly requires "no server backend"
- StoreKit 2 provides cryptographic JWS signature verification
- Checks certificate chain, app bundle ID, transaction integrity
- Sufficient security for consumable purchases
- Apple's recommended approach for local-only apps

**Security Measures**:
```swift
func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified(_, let error):
        throw PurchaseError.failedVerification(error)
    case .verified(let safe):
        return safe  // Cryptographically verified transaction
    }
}
```

**Fraud Risk**: Low - consumables are small-value items, cryptographic verification prevents most attacks

### Decision 7: Restore Purchases Behavior

**Decision**: Restore only unfinished/interrupted transactions (not full history)

**Rationale**:
- **Consumables Cannot Be Fully Restored**: Once consumed, credits are gone (Apple limitation)
- Restore function recovers purchases that weren't delivered due to:
  - App crash during purchase
  - Network interruption
  - "Ask to Buy" pending approval
- Uses `Transaction.currentEntitlements` to find unfinished transactions
- Checks local database to prevent duplicate credit delivery

**User-Facing Explanation**: "Restore Purchases" button will say "Recover Interrupted Purchases" to set correct expectations

**Code Pattern**:
```swift
func restorePurchases() async {
    for await result in Transaction.currentEntitlements {
        guard case .verified(let transaction) = result else { continue }

        // Only restore if not already delivered
        if !isTransactionDelivered(transaction.id) {
            deliverCredits(for: transaction)
            await transaction.finish()
        }
    }
}
```

### Decision 8: Transaction Listener Setup

**Decision**: Start transaction listener at app launch in `AstroSvitlaApp.init()`

**Rationale**:
- Handles "Ask to Buy" approvals while app is running
- Catches interrupted purchases on app restart
- Required by StoreKit 2 best practices
- Runs as detached task to avoid blocking main actor

**Implementation**:
```swift
// In PurchaseManager
private func startTransactionListener() {
    transactionListener = Task.detached {
        for await verificationResult in Transaction.updates {
            await self.handleTransactionUpdate(verificationResult)
        }
    }
}
```

**Lifecycle**: Task cancelled in `deinit`, automatically restarts on next app launch

## Testing Strategy

### Sandbox Testing Requirements

1. **Create Sandbox Tester**:
   - App Store Connect → Users and Access → Sandbox Testers
   - Email: `test@astrosvitla.com`
   - Test consumable purchases without real charges

2. **Test Scenarios** (Critical Path):
   - ✅ Purchase single credit → verify balance +1
   - ✅ Generate report → verify balance -1
   - ✅ Purchase with 0 credits → show paywall
   - ✅ Cancel purchase → balance unchanged
   - ✅ Kill app during purchase → restart → restore → credits delivered

3. **StoreKit Configuration File**:
   - Create `StoreKitTestConfiguration.storekit` for local testing
   - Add product: `com.astrosvitla.report.credit.single` @ $4.99
   - Enables testing without App Store Connect

### Contract Tests

```swift
// Validate product configuration matches App Store Connect
func testProductConfiguration() async throws {
    let products = try await Product.products(for: ["com.astrosvitla.report.credit.single"])

    #expect(products.count == 1)
    #expect(products[0].id == "com.astrosvitla.report.credit.single")
    #expect(products[0].type == .consumable)
    #expect(products[0].price == Decimal(4.99))  // US pricing
}
```

## Architecture Recommendations

### Service Layer Pattern

Follow existing `UserProfileService.swift` pattern:

```swift
@MainActor
class PurchaseService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func loadProducts() async throws -> [Product]
    func purchase(_ product: Product, for userID: UUID) async throws -> Transaction?
    func restorePurchases(for userID: UUID) async throws
}

@MainActor
class CreditManager {
    private let context: ModelContext

    func getAvailableCredits(for userID: UUID) -> Int
    func consumeCredit(for reportArea: ReportArea, userID: UUID, profileID: UUID) throws
    func getCreditHistory(for userID: UUID) -> [PurchaseCredit]
}
```

### MVVM Integration

```swift
@Observable
class PaywallViewModel {
    var product: Product?
    var isPurchasing = false
    var error: PurchaseError?
    var availableCredits: Int = 0

    func purchase() async {
        // Purchase flow
    }
}

struct PaywallView: View {
    @State private var viewModel: PaywallViewModel
    @EnvironmentObject var repositoryContext: RepositoryContext

    var body: some View {
        VStack {
            Text("Available Credits: \(viewModel.availableCredits)")
            Button("Purchase Credit - \(product.displayPrice)") {
                Task { await viewModel.purchase() }
            }
        }
    }
}
```

### Error Handling

```swift
enum PurchaseError: LocalizedError {
    case networkError
    case userCancelled
    case failedVerification
    case insufficientCredits
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .networkError:
            return NSLocalizedString(
                "purchase.error.network",
                tableName: "Localizable",
                value: "Помилка мережі. Перевірте з'єднання.",
                comment: "Network error during purchase"
            )
        // ... other cases
        }
    }
}
```

## Integration Points

### 1. Report Generation Flow

**Before**:
```swift
func generateReport(area: ReportArea) async {
    let report = await aiService.generateReport(area: area)
    saveReport(report)
}
```

**After** (with credit check):
```swift
func generateReport(area: ReportArea, profileID: UUID) async throws {
    // Check credits
    guard creditManager.hasAvailableCredits(for: userID) else {
        throw ReportError.insufficientCredits  // Show paywall
    }

    // Generate report
    let report = await aiService.generateReport(area: area)

    // Consume credit
    try creditManager.consumeCredit(for: area, userID: userID, profileID: profileID)

    // Save report
    saveReport(report)
}
```

### 2. App Launch Integration

Add to `AstroSvitlaApp.swift`:

```swift
@StateObject private var purchaseManager: PurchaseManager

init() {
    // ... existing setup ...

    let purchaseMgr = PurchaseManager(context: sharedModelContainer.mainContext)
    _purchaseManager = StateObject(wrappedValue: purchaseMgr)
}

var body: some Scene {
    WindowGroup {
        ContentView()
            .environmentObject(purchaseManager)  // Inject
    }
}
```

### 3. Report List UI

Show credit balance and "Purchase" button:

```swift
struct ReportListView: View {
    @EnvironmentObject var creditManager: CreditManager

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Available Credits")
                    Spacer()
                    Text("\(creditManager.availableCredits)")
                        .bold()
                }
            }

            ForEach(reportAreas) { area in
                Button {
                    if creditManager.availableCredits > 0 {
                        generateReport(area)
                    } else {
                        showPaywall = true
                    }
                } label: {
                    ReportAreaRow(area: area, locked: creditManager.availableCredits == 0)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}
```

## Performance Considerations

### Credit Balance Caching

```swift
// Cache credit balance to avoid repeated database queries
@MainActor
class CreditManager: ObservableObject {
    @Published private(set) var availableCredits: Int = 0

    func refreshBalance(for userID: UUID) async {
        let credits = await fetchCreditBalance(userID)
        availableCredits = credits
    }
}
```

### Transaction Processing

- **Asynchronous**: All StoreKit 2 calls use async/await
- **Main Actor**: UI updates happen on `@MainActor`
- **Background Processing**: Transaction listener runs on detached task
- **Performance Target**: <5 seconds from purchase to credit delivery (per spec SC-007)

## Localization

### Ukrainian Strings (MVP Priority)

```swift
// Localizable.strings (uk)
"purchase.credit.single" = "1 кредит звіту";
"purchase.button.buy" = "Купити за %@";
"purchase.credits.available" = "Доступно кредитів";
"purchase.error.network" = "Помилка мережі. Перевірте з'єднання.";
"purchase.error.insufficient" = "Недостатньо кредитів";
"purchase.restore.title" = "Відновити покупки";
"purchase.paywall.title" = "Отримати звіт";
"purchase.paywall.description" = "Придбайте кредит для створення персоналізованого астрологічного звіту на базі штучного інтелекту.";
```

## App Store Connect Setup

### Product Configuration Steps

1. **Navigate**: My Apps → AstroSvitla → Features → In-App Purchases
2. **Create Product**:
   - Reference Name: `Single Report Credit`
   - Product ID: `com.astrosvitla.report.credit.single`
   - Type: **Consumable**
   - Price: Tier 5 ($4.99 US, ₴199 UAH)
3. **Localizations**:
   - English: "1 Report Credit" / "Generate an AI-powered astrology report"
   - Ukrainian: "1 кредит звіту" / "Створіть астрологічний звіт на базі ШІ"
4. **Review Screenshot**: Upload paywall UI showing purchase flow
5. **Submit for Review**: Include in app version submission

### Pricing Localization

StoreKit automatically handles currency conversion based on App Store price tiers:

| Region | Tier 5 Price |
|--------|--------------|
| US | $4.99 |
| Ukraine | ₴199 |
| EU | €4.99 |
| UK | £4.99 |

## Risk Mitigation

### Duplicate Credit Delivery Prevention

```swift
// Check if transaction already processed
private func isTransactionDelivered(_ transactionID: String) async -> Bool {
    let descriptor = FetchDescriptor<PurchaseCredit>(
        predicate: #Predicate { $0.transactionID == transactionID }
    )
    return (try? context.fetch(descriptor).first) != nil
}

// Only deliver if not found
if !await isTransactionDelivered(transaction.id) {
    deliverCredits(for: transaction)
}
```

### Transaction Integrity

- **StoreKit 2 Verification**: Cryptographic JWS signature validation
- **Local Audit Trail**: Every credit allocation/consumption logged
- **Idempotent Delivery**: Safe to call `deliverCredits()` multiple times

### Edge Cases

1. **App Killed During Purchase**: Transaction listener recovers on next launch
2. **Network Failure**: StoreKit retries, transaction eventually delivers
3. **Ask to Buy Pending**: Transaction listener handles approval asynchronously
4. **Multiple Devices**: SwiftData sync + `Transaction.currentEntitlements` prevents loss

## Future Enhancements (Post-MVP)

### Credit Packs

Add discounted multi-credit products:

```swift
enum PurchaseProduct: String {
    case single = "com.astrosvitla.report.credit.single"    // 1 credit @ $4.99
    case pack5 = "com.astrosvitla.report.credit.pack5"      // 5 credits @ $19.99 (20% off)
    case pack10 = "com.astrosvitla.report.credit.pack10"    // 10 credits @ $34.99 (30% off)
}
```

### Analytics Integration

Track purchase funnel:

```swift
// Sentry breadcrumb
SentrySDK.addBreadcrumb(Breadcrumb(
    level: .info,
    category: "purchase",
    message: "Credit purchased: \(productId)",
    data: ["credits": creditAmount, "price": product.price]
))
```

### Subscription Alternative

Consider monthly unlimited plan:

```swift
case monthlyUnlimited = "com.astrosvitla.subscription.monthly"  // Auto-renewable
```

## References

- [StoreKit 2 Documentation](https://developer.apple.com/documentation/storekit)
- [Implementing In-App Purchases](https://developer.apple.com/documentation/storekit/in-app_purchase)
- [Testing In-App Purchases with Sandbox](https://developer.apple.com/documentation/appstoreconnectapi/sandbox)
- [SwiftData Persistence](https://developer.apple.com/documentation/swiftdata)
- [Existing Contract Spec](/Users/Ruslan_Popesku/Desktop/AstroSvitla/specs/001-astrosvitla-ios-native/contracts/storekit.md)

## Research Status

**Complete** - All technical unknowns resolved. Ready for Phase 1 (Data Model & Contracts).
