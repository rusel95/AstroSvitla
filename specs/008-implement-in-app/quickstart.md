# Quick Start: In-App Purchase Implementation

**Feature**: 008-implement-in-app
**Branch**: `008-implement-in-app`
**Prerequisites**: Xcode 15.2+, iOS 17+ SDK, App Store Connect access

## Implementation Overview

This guide walks through implementing consumable in-app purchases for the AstroSvitla app using StoreKit 2, SwiftData, and SwiftUI. Follow steps sequentially using TDD approach per constitution.

## Phase 0: Setup (15 minutes)

### 1. App Store Connect Configuration

1. Navigate to [App Store Connect](https://appstoreconnect.apple.com)
2. My Apps → AstroSvitla → Features → In-App Purchases
3. Click "+" to create new product
4. Configure:
   - Type: **Consumable**
   - Reference Name: `Single Report Credit`
   - Product ID: `com.astrosvitla.report.credit.single`
   - Price: Tier 5 ($4.99)
5. Add localizations (English + Ukrainian - copy from [contract](contracts/storekit-products.md#product-definitions))
6. Upload screenshot (paywall UI)
7. Save (don't submit for review yet - will submit with app)

###2. Create Sandbox Tester

1. App Store Connect → Users and Access → Sandbox Testers
2. Add new tester:
   - Email: `test@astrosvitla.com`
   - Password: [Generate strong password, save in 1Password]
   - Country: Ukraine
3. Save credentials

### 3. Local StoreKit Configuration

Create `AstroSvitlaTests/Fixtures/StoreKitTestConfiguration.storekit`:

```json
{
  "identifier": "storekit",
  "products": [
    {
      "displayPrice": "4.99",
      "familyShareable": false,
      "internalID": "6736471234",
      "localizations": [
        {
          "description": "Purchase 1 credit to generate an AI-powered astrology report.",
          "displayName": "1 Report Credit",
          "locale": "en_US"
        }
      ],
      "productID": "com.astrosvitla.report.credit.single",
      "referenceName": "Single Report Credit",
      "type": "Consumable"
    }
  ],
  "version": { "major": 3, "minor": 0 }
}
```

Enable in Xcode:
- Product → Scheme → Edit Scheme → Run → Options
- StoreKit Configuration: Select `StoreKitTestConfiguration.storekit`

## Phase 1: Data Models (TDD - 30 minutes)

### Test First: Credit Model Tests

```swift
// File: AstroSvitlaTests/Features/Purchase/Unit/PurchaseCreditTests.swift

import Testing
import SwiftData
@testable import AstroSvitla

@Suite("PurchaseCredit Model Tests")
struct PurchaseCreditTests {
    @Test("Credit can be created with required fields")
    func testCreditCreation() {
        let credit = PurchaseCredit(
            reportArea: ReportArea.personality.rawValue,
            transactionID: "TEST-123"
        )

        #expect(credit.id != nil)
        #expect(credit.reportArea == "personality")
        #expect(credit.transactionID == "TEST-123")
        #expect(credit.consumed == false)
        #expect(credit.consumedDate == nil)
    }

    @Test("Credit can be marked as consumed")
    func testCreditConsumption() {
        let credit = PurchaseCredit(
            reportArea: "career",
            transactionID: "TEST-456"
        )
        let profileID = UUID()

        credit.consume(for: profileID)

        #expect(credit.consumed == true)
        #expect(credit.consumedDate != nil)
        #expect(credit.userProfileID == profileID)
    }

    @Test("Available credit returns true when not consumed")
    func testAvailableCredit() {
        let credit = PurchaseCredit(
            reportArea: "wellness",
            transactionID: "TEST-789"
        )

        #expect(credit.isAvailable == true)

        credit.consume(for: UUID())

        #expect(credit.isAvailable == false)
    }
}
```

Run tests: `⌘U` - **They should fail** (models don't exist yet).

### Implement: SwiftData Models

Create models from [data-model.md](data-model.md):

1. `AstroSvitla/Models/SwiftData/PurchaseCredit.swift` (copy from data-model.md)
2. `AstroSvitla/Models/SwiftData/PurchaseRecord.swift` (copy from data-model.md)

Update schema registration:

```swift
// AstroSvitla/App/AstroSvitlaApp.swift or ModelContainer extension

let schema = Schema([
    User.self,
    UserProfile.self,
    BirthChart.self,
    ReportPurchase.self,
    PurchaseCredit.self,      // ADD
    PurchaseRecord.self       // ADD
])
```

Run tests: `⌘U` - **They should pass**.

## Phase 2: Purchase Service (TDD - 1 hour)

### Test First: Product Loading

```swift
// AstroSvitlaTests/Features/Purchase/Contract/StoreKitProductContractTests.swift

@Test("Single credit product loads from StoreKit")
func testProductLoading() async throws {
    let service = PurchaseService(context: testContext)

    let products = try await service.loadProducts()

    #expect(products.count >= 1)
    let singleCredit = products.first {
        $0.id == "com.astrosvitla.report.credit.single"
    }
    #expect(singleCredit != nil)
    #expect(singleCredit?.type == .consumable)
}
```

### Implement: PurchaseService

```swift
// AstroSvitla/Features/Purchase/Services/PurchaseService.swift

import Foundation
import StoreKit
import SwiftData

@MainActor
final class PurchaseService: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isPurchasing = false
    @Published var purchaseError: PurchaseError?

    private let context: ModelContext
    private var transactionListener: Task<Void, Error>?

    init(context: ModelContext) {
        self.context = context

        Task {
            await loadProducts()
        }

        startTransactionListener()
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        do {
            let productIDs = ["com.astrosvitla.report.credit.single"]
            products = try await Product.products(for: productIDs)
        } catch {
            purchaseError = .productLoadFailed(error)
        }
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        // Implementation from research.md
        // ...
    }

    private func startTransactionListener() {
        // Implementation from research.md
        // ...
    }
}
```

Full implementation in [research.md](research.md#3-purchase-verification-storekit-2---no-server).

### Test: Purchase Flow

```swift
@Test("Purchase creates credit record")
func testPurchaseCreatesCredit() async throws {
    let service = PurchaseService(context: testContext)
    let product = MockProduct(id: "com.astrosvitla.report.credit.single")

    let transaction = try await service.purchase(product)

    // Verify credit created
    let credits = try testContext.fetch(FetchDescriptor<PurchaseCredit>())
    #expect(credits.count == 1)
    #expect(credits[0].transactionID == String(transaction.id))
}
```

## Phase 3: UI Implementation (1 hour)

### PaywallView

```swift
// AstroSvitla/Features/Purchase/Views/PaywallView.swift

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var purchaseService: PurchaseService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("purchase.paywall.title", tableName: "Localizable")
                .font(.largeTitle)
                .bold()

            Text("purchase.paywall.description", tableName: "Localizable")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Product
            if let product = purchaseService.products.first {
                ProductView(product: product) {
                    Task {
                        if let _ = try await purchaseService.purchase(product) {
                            dismiss()
                        }
                    }
                }
            }

            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

struct ProductView: View {
    let product: Product
    let onPurchase: () -> Void

    var body: some View {
        VStack {
            Text(product.displayName)
                .font(.headline)

            Text(product.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Purchase for \(product.displayPrice)") {
                onPurchase()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}
```

### Credit Balance Display

```swift
// AstroSvitla/Features/Purchase/Views/CreditBalanceView.swift

import SwiftUI
import SwiftData

struct CreditBalanceView: View {
    @Query(filter: #Predicate<PurchaseCredit> { !$0.consumed })
    private var availableCredits: [PurchaseCredit]

    var body: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)

            Text("Available Credits: \(availableCredits.count)")
                .font(.headline)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(8)
    }
}
```

### Integration: Report Generation

Update report generation to check credits:

```swift
// AstroSvitla/Features/ReportGeneration/ViewModels/ReportGenerationViewModel.swift

func generateReport(area: ReportArea, profile: UserProfile) async throws {
    // Check credits
    let creditService = CreditManager(context: context)
    guard creditService.hasAvailableCredits() else {
        throw ReportError.insufficientCredits  // Show paywall
    }

    // Generate report
    let report = try await aiService.generateReport(area: area, chart: profile.chart)

    // Consume credit
    try creditService.consumeCredit(for: area, profileID: profile.id)

    // Save report
    saveReport(report)
}
```

## Phase 4: Testing (30 minutes)

### Unit Tests Checklist

```
□ PurchaseCredit model creation
□ PurchaseCredit consumption
□ PurchaseRecord model creation
□ Product loading from StoreKit
□ Purchase flow success
□ Purchase flow cancellation
□ Credit consumption
□ Duplicate transaction prevention
```

Run: `⌘U` - All tests should pass.

### Integration Test

```swift
@Test("End-to-end purchase to report generation")
func testPurchaseToReportFlow() async throws {
    // Purchase credit
    let service = PurchaseService(context: testContext)
    let product = try await service.loadProducts().first!
    let transaction = try await service.purchase(product)

    // Verify credit available
    let credits = try testContext.fetch(FetchDescriptor<PurchaseCredit>())
    #expect(credits.count == 1)
    #expect(!credits[0].consumed)

    // Generate report
    let creditManager = CreditManager(context: testContext)
    let credit = try creditManager.consumeCredit(for: .personality, profileID: UUID())

    // Verify credit consumed
    #expect(credit.consumed == true)
    #expect(credits.filter { !$0.consumed }.count == 0)
}
```

### Manual Testing with Sandbox

1. Run app on device from Xcode
2. Navigate to report generation
3. Tap locked report → Paywall appears
4. Tap "Purchase" → Apple payment sheet appears
5. Sign in with sandbox tester when prompted
6. Complete purchase (Face ID/password)
7. **Expected**: Credit balance increases, report generates immediately

**Debug Checklist**:
- ✅ Product loads (`print` in `loadProducts`)
- ✅ Transaction listener starts (`print` in `startTransactionListener`)
- ✅ Purchase completes (`print` transaction ID)
- ✅ Credit delivered (`print` credit count)
- ✅ Transaction finished (`print` after `transaction.finish()`)

## Phase 5: Localization (15 minutes)

Add Ukrainian strings:

```swift
// AstroSvitla/Resources/uk.lproj/Localizable.strings

"purchase.paywall.title" = "Отримати звіт";
"purchase.paywall.description" = "Придбайте кредит для створення персоналізованого астрологічного звіту на базі штучного інтелекту.";
"purchase.button.buy" = "Купити за %@";
"purchase.credits.available" = "Доступно кредитів: %d";
"purchase.error.network" = "Помилка мережі. Перевірте з'єднання.";
"purchase.error.insufficient" = "Недостатньо кредитів для створення звіту";
"purchase.restore.title" = "Відновити покупки";
```

## Common Issues & Solutions

### Issue: Products Not Loading

**Symptom**: `products` array is empty

**Solutions**:
1. Check product ID spelling: `com.astrosvitla.report.credit.single`
2. Verify product is "Cleared for Sale" in App Store Connect
3. Check StoreKit configuration file is selected in scheme
4. Wait 1-2 minutes after creating product in App Store Connect

### Issue: Purchase Fails with `.networkError`

**Symptom**: Purchase always fails

**Solutions**:
1. Check device internet connection
2. Sign out of production App Store account in Settings
3. Ensure sandbox tester is signed in
4. Check App Store Connect sandbox tester status

### Issue: Credits Not Delivered

**Symptom**: Purchase succeeds but credit count doesn't increase

**Solutions**:
1. Check `deliverCredits` is called before `transaction.finish()`
2. Verify `context.save()` is called after inserting models
3. Check for duplicate transaction ID (prevents re-delivery)
4. Add `print` statements in credit delivery flow

### Issue: Restore Purchases Does Nothing

**Symptom**: "Restore Purchases" button has no effect

**Symptom**: This is **expected behavior** for consumed credits

**Explanation**: Consumable purchases can only restore **unfinished transactions**, not consumed credits. If user purchased and consumed credit, restore won't bring it back.

## Performance Targets

Per spec requirements:

- **Purchase Flow**: 2-3 taps from paywall to confirmation (FR-004)
- **Report Generation**: <5 seconds after purchase (SC-007)
- **UI Responsiveness**: <100ms for all purchase UI interactions

Measure with:
```swift
let start = Date()
// ... purchase operation ...
let duration = Date().timeIntervalSince(start)
print("Purchase completed in \(duration)s")
```

## Next Steps

After completing implementation:

1. ✅ All unit tests pass
2. ✅ Integration tests pass
3. ✅ Manual sandbox testing successful
4. ✅ Ukrainian localization verified
5. ✅ Performance targets met
6. → Generate `tasks.md` with `/speckit.tasks`
7. → Begin implementation with `/speckit.implement`

## References

- [Full Spec](spec.md) - Complete requirements
- [Research](research.md) - Technical decisions and code examples
- [Data Model](data-model.md) - SwiftData schema details
- [StoreKit Contract](contracts/storekit-products.md) - Product configuration
- [StoreKit 2 Docs](https://developer.apple.com/documentation/storekit)

## Support

Questions or issues? Check:
1. [research.md](research.md) for implementation patterns
2. [contracts/storekit-products.md](contracts/storekit-products.md) for product config
3. Existing `PurchaseConfirmationView.swift` for UI patterns
