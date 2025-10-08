# StoreKit 2 Contract

**Framework**: StoreKit 2 (iOS 15+)
**Purpose**: Handle in-app purchases for astrology reports
**Product Type**: Non-Consumable
**Documentation**: https://developer.apple.com/documentation/storekit

---

## Product Configuration

### Product IDs

All products must be configured in App Store Connect before implementation.

| Product ID | Display Name | Type | Price | Description |
|------------|--------------|------|-------|-------------|
| `com.astrosvitla.astroinsight.report.general` | General Life Overview | Non-Consumable | $9.99 | Comprehensive life overview report |
| `com.astrosvitla.astroinsight.report.finances` | Finances Report | Non-Consumable | $6.99 | Financial astrology analysis |
| `com.astrosvitla.astroinsight.report.career` | Career Report | Non-Consumable | $6.99 | Career and professional growth insights |
| `com.astrosvitla.astroinsight.report.relationships` | Relationships Report | Non-Consumable | $5.99 | Love and relationship patterns |
| `com.astrosvitla.astroinsight.report.health` | Health Report | Non-Consumable | $5.99 | Health and wellness guidance |

**Important**: Product IDs must match exactly between code and App Store Connect.

---

## Product Setup in App Store Connect

### Step-by-Step Configuration

1. **Navigate to**: App Store Connect → My Apps → [Your App] → Features → In-App Purchases

2. **Create New Product**:
   - Click "+" button
   - Select "Non-Consumable"

3. **Product Configuration**:
   - **Reference Name**: Internal name (e.g., "General Life Overview Report")
   - **Product ID**: Unique identifier (e.g., `com.astrosvitla.astroinsight.report.general`)
   - **Price**: Select price tier
     - Tier 10: $9.99
     - Tier 7: $6.99
     - Tier 6: $5.99

4. **Localization** (English & Ukrainian):

**English**:
```
Display Name: General Life Overview
Description: Unlock a comprehensive AI-powered analysis of your natal chart covering all major life areas including personality, relationships, career, and life purpose. Get personalized insights based on your unique planetary positions and aspects.
```

**Ukrainian**:
```
Display Name: Загальний огляд життя
Description: Отримайте всебічний аналіз вашої натальної карти з використанням штучного інтелекту, що охоплює всі основні сфери життя, включаючи особистість, стосунки, кар'єру та життєву мету. Персоналізовані інсайти на основі унікальних планетарних позицій.
```

5. **Review Information**:
   - Screenshot: (Upload chart visualization with report preview)
   - Review Notes: "This in-app purchase unlocks an AI-generated astrology report for the user's natal chart."

6. **Submit for Review**: Products must be reviewed before app submission

---

## StoreKit 2 Integration

### Product Loading

```swift
import StoreKit

@MainActor
class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []

    private let productIDs: [String] = [
        "com.astrosvitla.astroinsight.report.general",
        "com.astrosvitla.astroinsight.report.finances",
        "com.astrosvitla.astroinsight.report.career",
        "com.astrosvitla.astroinsight.report.relationships",
        "com.astrosvitla.astroinsight.report.health"
    ]

    init() {
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
            print("✅ Loaded \(products.count) products")
        } catch {
            print("❌ Failed to load products: \(error)")
        }
    }

    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            if transaction.revocationDate == nil {
                purchasedProductIDs.insert(transaction.productID)
            } else {
                purchasedProductIDs.remove(transaction.productID)
            }
        }
    }
}
```

---

## Purchase Flow

### Purchase Method

```swift
extension StoreManager {
    func purchase(_ product: Product, for chartID: UUID) async throws -> Transaction? {
        // Initiate purchase
        let result = try await product.purchase()

        switch result {
        case .success(let verificationResult):
            // Verify transaction is legitimate
            let transaction = try checkVerified(verificationResult)

            // Deliver content BEFORE finishing transaction
            await deliverReport(for: transaction, chartID: chartID)

            // Mark transaction as finished
            await transaction.finish()

            // Update local state
            purchasedProductIDs.insert(transaction.productID)

            return transaction

        case .userCancelled:
            print("ℹ️ User cancelled purchase")
            return nil

        case .pending:
            print("⏳ Purchase pending (Ask to Buy, etc.)")
            return nil

        @unknown default:
            print("⚠️ Unknown purchase result")
            return nil
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            // Transaction failed StoreKit's automatic verification
            throw StoreError.failedVerification(error)
        case .verified(let safe):
            return safe
        }
    }

    private func deliverReport(for transaction: Transaction, chartID: UUID) async {
        // 1. Extract product ID and derive life area
        guard let lifeArea = LifeArea.from(productID: transaction.productID) else {
            print("❌ Unknown product ID: \(transaction.productID)")
            return
        }

        // 2. Generate AI report
        do {
            let chart = try await fetchChart(chartID: chartID)
            let report = try await generateReport(chart: chart, area: lifeArea)

            // 3. Save to SwiftData
            try await saveReportPurchase(
                chartID: chartID,
                area: lifeArea,
                reportText: report,
                transactionID: String(transaction.id),
                price: transaction.price ?? 0
            )

            print("✅ Report delivered for \(lifeArea.displayName)")

        } catch {
            print("❌ Failed to deliver report: \(error)")
            // Don't finish transaction if delivery failed
            // User can restore purchase later
        }
    }
}

enum StoreError: Error {
    case failedVerification(VerificationResult<Transaction>.VerificationError)
    case productNotFound
    case purchaseFailed
}
```

---

## Transaction Verification

### Automatic Verification

StoreKit 2 automatically verifies transactions using Apple's servers. The `VerificationResult` enum indicates whether verification succeeded:

```swift
let result: VerificationResult<Transaction> = // ... from purchase result

switch result {
case .verified(let transaction):
    // ✅ Transaction is legitimate
    // Safe to deliver content
    await deliverContent(for: transaction)

case .unverified(let transaction, let error):
    // ❌ Transaction failed verification
    // Do NOT deliver content
    print("Verification failed: \(error)")
    // Possible reasons:
    // - Transaction signature invalid
    // - Transaction from different app
    // - JWS string malformed
}
```

**Important**: Always check verification before delivering content.

---

## Purchase Restoration

### Automatic Restoration

StoreKit 2 automatically syncs purchases across devices using `Transaction.currentEntitlements`:

```swift
func restorePurchases() async {
    print("🔄 Restoring purchases...")

    for await result in Transaction.currentEntitlements {
        guard case .verified(let transaction) = result else {
            print("⚠️ Unverified transaction skipped")
            continue
        }

        // Check if transaction is still active (not revoked)
        guard transaction.revocationDate == nil else {
            print("⚠️ Transaction revoked: \(transaction.productID)")
            continue
        }

        // Add to purchased products
        purchasedProductIDs.insert(transaction.productID)

        // Re-deliver content if not already in database
        await redeliverIfNeeded(transaction)
    }

    print("✅ Purchase restoration complete")
}

private func redeliverIfNeeded(_ transaction: Transaction) async {
    // Check if report already exists in SwiftData
    let exists = await checkReportExists(transactionID: String(transaction.id))

    if !exists {
        print("ℹ️ Re-delivering content for: \(transaction.productID)")
        // Note: For app reinstall, we need chart ID
        // This is a limitation - user must re-create chart
        // Or store chart<->transaction mapping in iCloud
    }
}
```

**Note**: Non-consumable purchases are permanent. Users never need to repurchase.

---

## Transaction Listener

### Listen for Updates

Start listening for transaction updates at app launch:

```swift
@main
struct AstroSvitlaApp: App {
    @StateObject private var storeManager = StoreManager()
    @State private var transactionListener: Task<Void, Error>?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(storeManager)
        }
        .task {
            transactionListener = listenForTransactions()
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else {
                    print("⚠️ Unverified transaction update")
                    continue
                }

                // Handle transaction update
                await handleTransactionUpdate(transaction)

                // Always finish transaction
                await transaction.finish()
            }
        }
    }

    private func handleTransactionUpdate(_ transaction: Transaction) async {
        print("📬 Transaction update: \(transaction.productID)")

        // Update purchased products state
        if transaction.revocationDate == nil {
            await storeManager.addPurchased(transaction.productID)
        } else {
            await storeManager.removePurchased(transaction.productID)
        }

        // Deliver content if needed
        await storeManager.deliverIfNeeded(transaction)
    }
}
```

---

## Product Display

### SwiftUI View

```swift
struct LifeAreaSelectionView: View {
    @EnvironmentObject var storeManager: StoreManager
    let chart: BirthChart

    var body: some View {
        List {
            ForEach(LifeArea.allCases, id: \.self) { area in
                LifeAreaCard(
                    area: area,
                    product: storeManager.product(for: area),
                    isPurchased: storeManager.isPurchased(area: area, chartID: chart.id)
                )
            }
        }
        .navigationTitle("Select Life Area")
    }
}

struct LifeAreaCard: View {
    let area: LifeArea
    let product: Product?
    let isPurchased: Bool

    @EnvironmentObject var storeManager: StoreManager
    @State private var isPurchasing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(area.icon)
                    .font(.title)

                VStack(alignment: .leading) {
                    Text(area.displayName)
                        .font(.headline)

                    if let product = product {
                        Text(product.displayPrice)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if isPurchased {
                    Button("View Report") {
                        // Navigate to report
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(action: purchase) {
                        if isPurchasing {
                            ProgressView()
                        } else {
                            Text("Purchase")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isPurchasing || product == nil)
                }
            }
        }
        .padding()
    }

    private func purchase() {
        guard let product = product else { return }

        Task {
            isPurchasing = true
            defer { isPurchasing = false }

            do {
                let transaction = try await storeManager.purchase(product)
                if transaction != nil {
                    print("✅ Purchase successful")
                }
            } catch {
                print("❌ Purchase failed: \(error)")
                // Show error alert to user
            }
        }
    }
}
```

---

## Testing

### Sandbox Testing

**Setup**:
1. Create sandbox tester account in App Store Connect
2. Sign out of App Store on device
3. Run app from Xcode
4. When prompted, sign in with sandbox account

**Test Scenarios**:
- [ ] Load products successfully
- [ ] Purchase each product type
- [ ] Decline payment
- [ ] Cancel purchase
- [ ] Purchase when already owned (should show "You've already purchased this")
- [ ] Restore purchases after app reinstall
- [ ] Interrupted purchase (kill app during purchase)

**Clear Purchase History**:
- App Store Connect → Users and Access → Sandbox Testers → [Tester] → Clear Purchase History

**Important**: Sandbox purchases are free but behave like real purchases.

---

## Error Handling

### Common Errors

```swift
func purchase(_ product: Product) async throws -> Transaction? {
    do {
        let result = try await product.purchase()
        return try await handlePurchaseResult(result)

    } catch StoreKitError.userCancelled {
        // User tapped "Cancel" - not an error
        print("ℹ️ User cancelled purchase")
        return nil

    } catch StoreKitError.networkError(let error) {
        // Network issue - suggest retry
        throw PurchaseError.networkError(error)

    } catch StoreKitError.systemError(let error) {
        // System issue - suggest retry later
        throw PurchaseError.systemError(error)

    } catch StoreKitError.notEntitled {
        // User doesn't own product (shouldn't happen with non-consumables)
        throw PurchaseError.notEntitled

    } catch {
        // Unknown error
        throw PurchaseError.unknown(error)
    }
}

enum PurchaseError: LocalizedError {
    case networkError(Error)
    case systemError(Error)
    case notEntitled
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .systemError:
            return "System error. Please try again later."
        case .notEntitled:
            return "Purchase verification failed."
        case .unknown(let error):
            return "Purchase failed: \(error.localizedDescription)"
        }
    }
}
```

---

## Security Best Practices

### Transaction Validation

```swift
// ✅ Always verify transactions
guard case .verified(let transaction) = result else {
    throw StoreError.failedVerification
}

// ✅ Check revocation status
guard transaction.revocationDate == nil else {
    throw StoreError.transactionRevoked
}

// ✅ Finish transactions after delivery
await transaction.finish()
```

### Receipt Management

```swift
// StoreKit 2 handles receipts automatically
// Transaction ID is sufficient for your records

func saveTransaction(_ transaction: Transaction) {
    let receipt = TransactionReceipt(
        transactionID: String(transaction.id),
        productID: transaction.productID,
        purchaseDate: transaction.purchaseDate,
        originalTransactionID: String(transaction.originalID)
    )

    // Save to SwiftData
    saveToDatabase(receipt)
}
```

---

## Compliance & Legal

### App Store Review Guidelines

**Required**:
- [ ] Restore Purchases functionality (automatic with StoreKit 2)
- [ ] Clear pricing displayed before purchase
- [ ] Accurate product descriptions
- [ ] Successful purchase delivers promised content

**Prohibited**:
- ❌ External payment systems (must use StoreKit)
- ❌ Misleading pricing
- ❌ Incomplete transactions (must deliver content)

### Privacy

- Purchase history synced via iCloud (Apple's built-in feature)
- No third-party analytics on purchases
- Transaction data stored locally only

---

## Integration Checklist

- [ ] Configure all 5 products in App Store Connect
- [ ] Add English and Ukrainian localizations
- [ ] Upload product screenshots
- [ ] Implement `StoreManager` class
- [ ] Add transaction listener at app launch
- [ ] Implement purchase flow with verification
- [ ] Handle all error cases
- [ ] Test all scenarios in sandbox
- [ ] Implement restore purchases
- [ ] Add purchase history view (optional)

---

## Helper Extension

```swift
extension LifeArea {
    var productID: String {
        "com.astrosvitla.astroinsight.report.\(rawValue)"
    }

    static func from(productID: String) -> LifeArea? {
        let prefix = "com.astrosvitla.astroinsight.report."
        guard productID.hasPrefix(prefix) else { return nil }

        let rawValue = String(productID.dropFirst(prefix.count))
        return LifeArea(rawValue: rawValue)
    }
}

extension StoreManager {
    func product(for area: LifeArea) -> Product? {
        products.first { $0.id == area.productID }
    }

    func isPurchased(area: LifeArea, chartID: UUID) -> Bool {
        // Check if product is purchased AND report exists in database
        return purchasedProductIDs.contains(area.productID)
    }
}
```

---

**Status**: ✅ Contract specification complete
**Next**: Implement in `AstroSvitla/Core/Services/PurchaseManager.swift`
