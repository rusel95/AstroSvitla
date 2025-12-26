# StoreKit Product Contract

**Feature**: 008-implement-in-app
**Date**: 2025-12-23
**Platform**: iOS App Store
**Product Type**: Consumable

## Overview

This contract defines the StoreKit 2 product configuration for consumable in-app purchases in the AstroSvitla app. Products must be configured identically in App Store Connect and local testing environments.

**Important**: This supersedes the Non-Consumable products defined in `/specs/001-astrosvitla-ios-native/contracts/storekit.md`. The purchase model has changed from permanent unlocks to consumable credits.

## Product Definitions

### MVP Product (Single Credit)

**Product Identifier**: `com.astrosvitla.report.credit.single`

```json
{
  "productID": "com.astrosvitla.report.credit.single",
  "type": "Consumable",
  "referenceName": "Single Report Credit",
  "price": {
    "tier": 5,
    "usd": 4.99,
    "uah": 199,
    "eur": 4.99,
    "gbp": 4.99
  },
  "creditAmount": 1,
  "localizations": {
    "en-US": {
      "displayName": "1 Report Credit",
      "description": "Purchase 1 credit to generate an AI-powered astrology report for any life area (Personality, Career, Relationships, or Wellness). Each credit allows one report generation for any profile."
    },
    "uk": {
      "displayName": "1 кредит звіту",
      "description": "Придбайте 1 кредит для створення астрологічного звіту на базі штучного інтелекту для будь-якої сфери життя (Особистість, Кар'єра, Стосунки або Здоров'я). Кожен кредит дозволяє згенерувати один звіт для будь-якого профілю."
    }
  },
  "reviewNotes": "Consumable credit used to generate one AI-powered astrology report. Credits are not profile-specific and can be used for any user profile in the app."
}
```

### App Store Connect Configuration

| Field | Value |
|-------|-------|
| Reference Name | Single Report Credit |
| Product ID | `com.astrosvitla.report.credit.single` |
| Type | **Consumable** |
| Price Tier | 5 ($4.99 USD) |
| Cleared for Sale | Yes |
| Review Screenshot | Screenshot showing paywall with purchase button and credit balance |

### Pricing Table

| Region | Currency | Price | App Store Price Tier |
|--------|----------|-------|----------------------|
| United States | USD | $4.99 | 5 |
| Ukraine | UAH | ₴199 | 5 |
| European Union | EUR | €4.99 | 5 |
| United Kingdom | GBP | £4.99 | 5 |
| Canada | CAD | $6.99 | 5 |
| Australia | AUD | $7.99 | 5 |

*Note: Apple automatically converts prices based on price tier. Exact amounts may vary due to exchange rates and local tax requirements.*

## Product Properties

### Consumable Behavior

```swift
// Product configuration in code
enum PurchaseProduct: String, CaseIterable {
    case singleCredit = "com.astrosvitla.report.credit.single"

    var type: Product.ProductType {
        return .consumable
    }

    var creditAmount: Int {
        switch self {
        case .singleCredit:
            return 1
        }
    }

    var displayName: String {
        switch self {
        case .singleCredit:
            return String(localized: "purchase.product.single_credit.name", defaultValue: "1 Report Credit")
        }
    }

    var description: String {
        switch self {
        case .singleCredit:
            return String(localized: "purchase.product.single_credit.description")
        }
    }
}
```

### Product Loading

```swift
// Load products from App Store
func loadProducts() async throws -> [Product] {
    let productIDs = PurchaseProduct.allCases.map { $0.rawValue }

    let products = try await Product.products(for: productIDs)

    // Validate product configuration
    for product in products {
        guard product.type == .consumable else {
            throw ProductError.incorrectProductType(product.id)
        }
    }

    return products
}
```

## Contract Tests

### Product Configuration Validation

```swift
// File: AstroSvitlaTests/Features/Purchase/Contract/StoreKitProductContractTests.swift

import Testing
import StoreKit
@testable import AstroSvitla

@Suite("StoreKit Product Contract Tests")
struct StoreKitProductContractTests {

    @Test("Single credit product exists in App Store")
    func testSingleCreditProductExists() async throws {
        let products = try await Product.products(
            for: ["com.astrosvitla.report.credit.single"]
        )

        #expect(products.count == 1, "Expected exactly 1 product")

        let product = products[0]
        #expect(product.id == "com.astrosvitla.report.credit.single")
    }

    @Test("Single credit product is consumable type")
    func testProductIsConsumable() async throws {
        let products = try await Product.products(
            for: ["com.astrosvitla.report.credit.single"]
        )

        let product = products[0]
        #expect(product.type == .consumable, "Product must be consumable type")
    }

    @Test("Product has valid pricing information")
    func testProductPricing() async throws {
        let products = try await Product.products(
            for: ["com.astrosvitla.report.credit.single"]
        )

        let product = products[0]

        // Price should be greater than 0
        #expect(product.price > 0, "Product must have valid price")

        // Display price should not be empty
        #expect(!product.displayPrice.isEmpty, "Product must have display price")

        // Should have currency code
        #expect(
            !product.priceFormatStyle.currencyCode.identifier.isEmpty,
            "Product must have currency code"
        )
    }

    @Test("Product has localized display name")
    func testProductDisplayName() async throws {
        let products = try await Product.products(
            for: ["com.astrosvitla.report.credit.single"]
        )

        let product = products[0]

        #expect(!product.displayName.isEmpty, "Product must have display name")
        #expect(product.displayName.contains("Credit") || product.displayName.contains("кредит"),
                "Display name should mention 'Credit' or Ukrainian equivalent")
    }

    @Test("Product has localized description")
    func testProductDescription() async throws {
        let products = try await Product.products(
            for: ["com.astrosvitla.report.credit.single"]
        )

        let product = products[0]

        #expect(!product.description.isEmpty, "Product must have description")
    }

    @Test("Product IDs match enum definition")
    func testProductIDsMatchEnum() {
        let enumProductIDs = Set(PurchaseProduct.allCases.map { $0.rawValue })
        let expectedIDs = Set(["com.astrosvitla.report.credit.single"])

        #expect(enumProductIDs == expectedIDs, "Enum product IDs must match contract definition")
    }

    @Test("Credit amount mapping is correct")
    func testCreditAmountMapping() {
        let product = PurchaseProduct.singleCredit
        #expect(product.creditAmount == 1, "Single credit product must provide 1 credit")
    }
}
```

### Expected Test Results

| Test | Expected Result | Validates |
|------|-----------------|-----------|
| `testSingleCreditProductExists` | ✅ Pass | Product ID registered in App Store Connect |
| `testProductIsConsumable` | ✅ Pass | Product type configured as Consumable |
| `testProductPricing` | ✅ Pass | Valid price and currency information |
| `testProductDisplayName` | ✅ Pass | Localized display name present |
| `testProductDescription` | ✅ Pass | Localized description present |
| `testProductIDsMatchEnum` | ✅ Pass | Code enum matches contract |
| `testCreditAmountMapping` | ✅ Pass | Credit amount logic correct |

## Testing Environment

### Local Testing (StoreKit Configuration File)

Create file: `AstroSvitlaTests/Fixtures/StoreKitTestConfiguration.storekit`

```json
{
  "identifier" : "storekit",
  "nonRenewingSubscriptions" : [],
  "products" : [
    {
      "displayPrice" : "4.99",
      "familyShareable" : false,
      "internalID" : "6736471234",
      "localizations" : [
        {
          "description" : "Purchase 1 credit to generate an AI-powered astrology report.",
          "displayName" : "1 Report Credit",
          "locale" : "en_US"
        },
        {
          "description" : "Придбайте 1 кредит для створення астрологічного звіту на базі ШІ.",
          "displayName" : "1 кредит звіту",
          "locale" : "uk"
        }
      ],
      "productID" : "com.astrosvitla.report.credit.single",
      "referenceName" : "Single Report Credit",
      "type" : "Consumable"
    }
  ],
  "settings" : {
    "  _applicationInternalID" : "6736461234",
    "_developerTeamID" : "XXXXXXXXXX",
    "_lastSynchronizedDate" : 756432000.0
  },
  "subscriptionGroups" : [],
  "version" : {
    "major" : 3,
    "minor" : 0
  }
}
```

**Usage in Xcode**:
1. Product → Scheme → Edit Scheme
2. Run → Options → StoreKit Configuration
3. Select `StoreKitTestConfiguration.storekit`

### Sandbox Testing

1. **Create Sandbox Tester**:
   - App Store Connect → Users and Access → Sandbox Testers
   - Email: `test@astrosvitla.com`
   - Country: Ukraine
   - App Store: Ukraine

2. **Test Device Setup**:
   ```
   1. Settings → App Store → Sign Out (production account)
   2. Run app from Xcode
   3. Trigger purchase → Sign in with sandbox tester when prompted
   4. Complete test purchase
   ```

3. **Clear Purchase History** (for repeat testing):
   - App Store Connect → Sandbox Testers → Select Tester → Manage → Clear Purchase History

## Purchase Flow Contract

### Successful Purchase

```
User → Tap "Purchase" Button
    ↓
App → StoreKit.Product.purchase()
    ↓
StoreKit → Show Apple Payment Sheet
    ↓
User → Confirm Purchase (Face ID/Touch ID/Password)
    ↓
StoreKit → Transaction.Verification.valid
    ↓
App → Deliver Credits (PurchaseRecord + PurchaseCredit)
    ↓
App → Transaction.finish()
    ↓
User → See Updated Credit Balance (+1)
```

### Failed/Cancelled Purchase

```
User → Tap "Purchase" Button
    ↓
App → StoreKit.Product.purchase()
    ↓
StoreKit → Show Apple Payment Sheet
    ↓
User → Cancel or Payment Declines
    ↓
StoreKit → Result.userCancelled or Result.pending
    ↓
App → No credits delivered
    ↓
App → Show appropriate message to user
```

## Verification Contract

### StoreKit 2 Automatic Verification

```swift
// Purchase verification flow
let result = try await product.purchase()

switch result {
case .success(let verificationResult):
    // Verify transaction cryptographically
    let transaction = try checkVerified(verificationResult)

    // Transaction properties validated by Apple:
    // ✅ JWS signature valid
    // ✅ Certificate chain trusted
    // ✅ Bundle ID matches app
    // ✅ Product ID matches purchase
    // ✅ Transaction not revoked

    // Deliver credits
    deliverCredits(for: transaction)

    // Mark as finished
    await transaction.finish()

case .userCancelled, .pending:
    // Handle non-purchase states
    break

@unknown default:
    break
}
```

### Transaction Properties Contract

| Property | Type | Description | Contract |
|----------|------|-------------|----------|
| `id` | UInt64 | Unique Apple transaction ID | Globally unique, never reused |
| `productID` | String | Product identifier | Must match `com.astrosvitla.report.credit.single` |
| `purchaseDate` | Date | When purchase completed | UTC timezone, accurate to second |
| `originalPurchaseDate` | Date | First purchase date | For consumables, same as purchaseDate |
| `appBundleID` | String | App bundle identifier | Must match app's bundle ID |
| `productType` | ProductType | Type of product | Must be `.consumable` |

## Restore Purchases Contract

### Consumable Restore Behavior

**Important**: Consumables **cannot be fully restored** like non-consumables. Restore only recovers **interrupted transactions**.

```swift
// Restore contract
func restorePurchases() async {
    // Iterate through unfinished transactions
    for await result in Transaction.currentEntitlements {
        guard case .verified(let transaction) = result else { continue }

        // Check if transaction already processed
        if !isTransactionDelivered(transaction.id) {
            // Deliver credits for interrupted purchase
            deliverCredits(for: transaction)

            // Mark as finished
            await transaction.finish()
        }
    }
}
```

**Scenarios**:
- ✅ **App crashed during purchase** → Credits delivered on restore
- ✅ **"Ask to Buy" approved while app closed** → Credits delivered on restore
- ✅ **Network interruption during delivery** → Credits delivered on restore
- ❌ **User consumed credits and reinstalled app** → Credits NOT restored (expected behavior)

## Error Contract

### Purchase Errors

| Error | StoreKit Code | User Message (English) | User Message (Ukrainian) |
|-------|---------------|------------------------|--------------------------|
| User Cancelled | `.userCancelled` | No message (silent) | No message (silent) |
| Network Error | `.networkError` | "Network error. Check your connection." | "Помилка мережі. Перевірте з'єднання." |
| System Error | `.systemError` | "Purchase failed. Please try again." | "Покупка не вдалася. Спробуйте ще раз." |
| Not Available | `.notAvailableInStorefront` | "This product is not available in your region." | "Цей продукт недоступний у вашому регіоні." |
| Failed Verification | Custom | "Purchase verification failed." | "Перевірка покупки не вдалася." |

### Verification Errors

```swift
enum VerificationError {
    case invalidSignature      // JWS signature doesn't match
    case revokedCertificate   // Certificate was revoked by Apple
    case unknownError         // Other verification failure
}
```

## Future Products (Post-MVP)

### Credit Packs (Planned)

```json
{
  "productID": "com.astrosvitla.report.credit.pack5",
  "type": "Consumable",
  "referenceName": "5 Report Credits Pack",
  "price": {
    "tier": 20,
    "usd": 19.99
  },
  "creditAmount": 5,
  "discount": "20% vs individual purchases"
}
```

```json
{
  "productID": "com.astrosvitla.report.credit.pack10",
  "type": "Consumable",
  "referenceName": "10 Report Credits Pack",
  "price": {
    "tier": 35,
    "usd": 34.99
  },
  "creditAmount": 10,
  "discount": "30% vs individual purchases"
}
```

## Compliance

### App Store Review Guidelines

- ✅ **3.1.1 In-App Purchase**: All digital content purchases use StoreKit
- ✅ **3.1.3(a) Reader Apps**: N/A (not a reader app)
- ✅ **3.1.5(a) Cryptocurrencies**: N/A (no cryptocurrency)
- ✅ **5.1.1 Privacy**: No personal data collected during purchase
- ✅ **5.1.2 Data Use**: Purchase data stored locally only

### Privacy Labels (App Store Connect)

| Data Type | Collection | Linking | Tracking | Purpose |
|-----------|------------|---------|----------|---------|
| Purchase History | Yes | Yes (linked to app account) | No | App functionality |

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-12-23 | Initial contract: Single consumable credit @ $4.99 |

## References

- [StoreKit 2 Documentation](https://developer.apple.com/documentation/storekit)
- [In-App Purchase Guidelines](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase)
- Spec: [spec.md](../spec.md) - FR-003, FR-008, FR-010
- Research: [research.md](../research.md) - Product Configuration
