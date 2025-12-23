# Data Model: In-App Purchase System

**Feature**: 008-implement-in-app
**Date**: 2025-12-23
**Framework**: SwiftData (iOS 17+)

## Overview

Data model for consumable in-app purchase credit system with local SwiftData persistence. Supports global credit pool, transaction history, and audit trail for purchase-to-report generation flow.

## Entity Diagram

```
┌─────────────────┐
│  PurchaseCredit │◄──────┐
│                 │       │
│ - id            │       │
│ - reportArea    │       │ Many-to-One
│ - purchaseDate  │       │
│ - consumed      │       │
│ - consumedDate  │       │
│ - transactionID │       │
│ - profileID?    │       │
└─────────────────┘       │
                          │
┌─────────────────────────┴────┐
│  PurchaseRecord               │
│                               │
│ - id                          │
│ - productID                   │
│ - transactionID (unique)      │
│ - purchaseDate                │
│ - priceUSD                    │
│ - localizedPrice              │
│ - currency                    │
│ - creditAmount                │
│ - restoredDate?               │
│ - credits: [PurchaseCredit]   │
└───────────────────────────────┘
         │
         │ One-to-One (optional)
         ▼
┌─────────────────┐
│  UserProfile    │  (Existing model)
│  (from spec-001)│
└─────────────────┘
```

## Models

### PurchaseCredit

Represents a single consumable credit for generating one report. Credits are tracked globally (not locked to specific profiles) but record which profile they were used for when consumed.

```swift
// File: AstroSvitla/Models/SwiftData/PurchaseCredit.swift

import Foundation
import SwiftData

@Model
final class PurchaseCredit {
    /// Unique identifier for this credit
    @Attribute(.unique)
    var id: UUID

    /// Report area this credit is valid for
    /// Maps to existing ReportArea enum: .personality, .career, .relationship, .wellness
    var reportArea: String

    /// When the credit was purchased (transaction completion date)
    var purchaseDate: Date

    /// Whether this credit has been consumed (used to generate a report)
    var consumed: Bool

    /// When the credit was consumed (nil if not yet consumed)
    var consumedDate: Date?

    /// StoreKit transaction ID for audit trail and duplicate prevention
    /// Format: "2000000123456789" (Apple's transaction ID)
    @Attribute(.unique)
    var transactionID: String

    /// Profile ID the credit was used for (nil if not yet consumed)
    /// Links to UserProfile.id when report generated
    var userProfileID: UUID?

    /// Back-reference to purchase record
    var purchaseRecord: PurchaseRecord?

    // MARK: - Initialization

    init(
        reportArea: String,
        transactionID: String,
        purchaseDate: Date = Date()
    ) {
        self.id = UUID()
        self.reportArea = reportArea
        self.purchaseDate = purchaseDate
        self.consumed = false
        self.consumedDate = nil
        self.transactionID = transactionID
        self.userProfileID = nil
    }

    // MARK: - Business Logic

    /// Mark credit as consumed for specific profile
    func consume(for profileID: UUID) {
        self.consumed = true
        self.consumedDate = Date()
        self.userProfileID = profileID
    }

    /// Check if credit is available for use
    var isAvailable: Bool {
        return !consumed
    }
}
```

**Validation Rules** (from spec FR-006, FR-007, FR-009):
- ✅ `transactionID` must be unique (prevent duplicate credit delivery)
- ✅ `consumed` = false → `consumedDate` must be nil
- ✅ `consumed` = true → `consumedDate` must be set, `userProfileID` must be set
- ✅ `reportArea` must be valid ReportArea enum value

### PurchaseRecord

Represents a completed StoreKit transaction. One transaction may create multiple credits (for future credit packs).

```swift
// File: AstroSvitla/Models/SwiftData/PurchaseRecord.swift

import Foundation
import SwiftData

@Model
final class PurchaseRecord {
    /// Unique identifier for this purchase record
    @Attribute(.unique)
    var id: UUID

    /// StoreKit product identifier
    /// e.g., "com.astrosvitla.report.credit.single"
    var productID: String

    /// StoreKit transaction ID (unique across all Apple purchases)
    @Attribute(.unique)
    var transactionID: String

    /// When the purchase was completed
    var purchaseDate: Date

    /// Price in USD (for analytics/reporting)
    var priceUSD: Decimal

    /// Localized price string shown to user
    /// e.g., "$4.99", "₴199", "€4.99"
    var localizedPrice: String

    /// Currency code
    /// e.g., "USD", "UAH", "EUR"
    var currencyCode: String

    /// Number of credits delivered from this purchase
    /// MVP: Always 1 (single credit purchases)
    /// Future: 5 or 10 for credit packs
    var creditAmount: Int

    /// Date purchase was restored (nil if original purchase)
    var restoredDate: Date?

    /// Credits created from this purchase
    @Relationship(deleteRule: .cascade, inverse: \PurchaseCredit.purchaseRecord)
    var credits: [PurchaseCredit] = []

    // MARK: - Initialization

    init(
        productID: String,
        transactionID: String,
        priceUSD: Decimal,
        localizedPrice: String,
        currencyCode: String,
        creditAmount: Int = 1,
        purchaseDate: Date = Date()
    ) {
        self.id = UUID()
        self.productID = productID
        self.transactionID = transactionID
        self.purchaseDate = purchaseDate
        self.priceUSD = priceUSD
        self.localizedPrice = localizedPrice
        self.currencyCode = currencyCode
        self.creditAmount = creditAmount
        self.restoredDate = nil
    }

    // MARK: - Business Logic

    /// Mark record as restored (recovered from interrupted transaction)
    func markAsRestored() {
        if restoredDate == nil {
            restoredDate = Date()
        }
    }

    /// Check if purchase was restored vs original purchase
    var isRestored: Bool {
        return restoredDate != nil
    }

    /// Get unconsumed credits from this purchase
    var availableCredits: [PurchaseCredit] {
        return credits.filter { !$0.consumed }
    }

    /// Get consumed credits from this purchase
    var consumedCredits: [PurchaseCredit] {
        return credits.filter { $0.consumed }
    }
}
```

**Validation Rules** (from spec FR-010, FR-012, FR-014):
- ✅ `transactionID` must be unique (Apple's transaction IDs are globally unique)
- ✅ `creditAmount` must match number of `PurchaseCredit` records created
- ✅ `credits` array must not be empty after delivery
- ✅ All `credits[].transactionID` must match `transactionID`

## Relationships

### PurchaseRecord ↔ PurchaseCredit (One-to-Many)

```swift
// In PurchaseRecord
@Relationship(deleteRule: .cascade, inverse: \PurchaseCredit.purchaseRecord)
var credits: [PurchaseCredit] = []

// In PurchaseCredit
var purchaseRecord: PurchaseRecord?
```

**Rules**:
- ✅ One `PurchaseRecord` creates one or more `PurchaseCredit` instances
- ✅ Deleting `PurchaseRecord` cascades to delete all associated `PurchaseCredit` instances
- ✅ Each `PurchaseCredit.transactionID` matches `PurchaseRecord.transactionID`

### PurchaseCredit → UserProfile (Many-to-One, Optional)

```swift
// In PurchaseCredit
var userProfileID: UUID?  // Optional: nil until consumed

// Query to find profile
func getUserProfile(context: ModelContext) -> UserProfile? {
    guard let profileID = userProfileID else { return nil }

    let descriptor = FetchDescriptor<UserProfile>(
        predicate: #Predicate { $0.id == profileID }
    )
    return try? context.fetch(descriptor).first
}
```

**Rules**:
- ✅ Credit is NOT locked to profile until consumed (global pool per spec clarification)
- ✅ `userProfileID` is nil for available credits
- ✅ `userProfileID` is set when credit consumed (records which profile generated report)

## Queries

### Get Available Credits

```swift
// Get all unconsumed credits
func getAvailableCredits(context: ModelContext) -> [PurchaseCredit] {
    let descriptor = FetchDescriptor<PurchaseCredit>(
        predicate: #Predicate { !$0.consumed },
        sortBy: [SortDescriptor(\.purchaseDate, order: .forward)]
    )
    return (try? context.fetch(descriptor)) ?? []
}

// Count available credits
func getAvailableCreditCount(context: ModelContext) -> Int {
    let descriptor = FetchDescriptor<PurchaseCredit>(
        predicate: #Predicate { !$0.consumed }
    )
    return (try? context.fetchCount(descriptor)) ?? 0
}

// Get available credits for specific report area
func getAvailableCredits(for reportArea: ReportArea, context: ModelContext) -> [PurchaseCredit] {
    let areaString = reportArea.rawValue
    let descriptor = FetchDescriptor<PurchaseCredit>(
        predicate: #Predicate { !$0.consumed && $0.reportArea == areaString },
        sortBy: [SortDescriptor(\.purchaseDate, order: .forward)]
    )
    return (try? context.fetch(descriptor)) ?? []
}
```

### Get Purchase History

```swift
// All purchases, newest first
func getPurchaseHistory(context: ModelContext) -> [PurchaseRecord] {
    let descriptor = FetchDescriptor<PurchaseRecord>(
        sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)]
    )
    return (try? context.fetch(descriptor)) ?? []
}

// Purchases within date range
func getPurchases(from startDate: Date, to endDate: Date, context: ModelContext) -> [PurchaseRecord] {
    let descriptor = FetchDescriptor<PurchaseRecord>(
        predicate: #Predicate {
            $0.purchaseDate >= startDate && $0.purchaseDate <= endDate
        },
        sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)]
    )
    return (try? context.fetch(descriptor)) ?? []
}
```

### Check for Duplicate Transaction

```swift
// Prevent duplicate credit delivery
func isTransactionProcessed(_ transactionID: String, context: ModelContext) -> Bool {
    let descriptor = FetchDescriptor<PurchaseRecord>(
        predicate: #Predicate { $0.transactionID == transactionID }
    )
    return (try? context.fetchCount(descriptor)) ?? 0 > 0
}
```

### Get Consumption History

```swift
// All consumed credits for a profile
func getConsumedCredits(for profileID: UUID, context: ModelContext) -> [PurchaseCredit] {
    let descriptor = FetchDescriptor<PurchaseCredit>(
        predicate: #Predicate { $0.consumed && $0.userProfileID == profileID },
        sortBy: [SortDescriptor(\.consumedDate, order: .reverse)]
    )
    return (try? context.fetch(descriptor)) ?? []
}

// Total credits purchased and consumed
struct CreditStats {
    let totalPurchased: Int
    let totalConsumed: Int
    let available: Int
}

func getCreditStats(context: ModelContext) -> CreditStats {
    let allCredits = (try? context.fetch(FetchDescriptor<PurchaseCredit>())) ?? []

    return CreditStats(
        totalPurchased: allCredits.count,
        totalConsumed: allCredits.filter { $0.consumed }.count,
        available: allCredits.filter { !$0.consumed }.count
    )
}
```

## Migration Strategy

### No Existing Data Migration Required

This is a new feature - no existing purchase data to migrate.

### Schema Registration

Update `ModelContainer` configuration:

```swift
// File: AstroSvitla/Core/Storage/ModelContainer+Shared.swift

extension ModelContainer {
    static func astroSvitlaShared() throws -> ModelContainer {
        let schema = Schema([
            User.self,
            UserProfile.self,
            BirthChart.self,
            ReportPurchase.self,      // Existing
            PurchaseCredit.self,      // NEW
            PurchaseRecord.self       // NEW
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        return try ModelContainer(for: schema, configurations: [config])
    }
}
```

## Data Integrity Rules

### Transaction Atomicity

```swift
// Deliver credits atomically: both PurchaseRecord and PurchaseCredit must be saved together
func deliverCredits(
    for transaction: Transaction,
    product: Product,
    context: ModelContext
) throws {
    // Check for duplicate
    guard !isTransactionProcessed(String(transaction.id), context: context) else {
        print("⚠️ Transaction already processed: \(transaction.id)")
        return
    }

    // Create purchase record
    let record = PurchaseRecord(
        productID: transaction.productID,
        transactionID: String(transaction.id),
        priceUSD: product.price as Decimal,
        localizedPrice: product.displayPrice,
        currencyCode: product.priceFormatStyle.currencyCode.identifier,
        creditAmount: 1,  // MVP: always 1
        purchaseDate: transaction.purchaseDate
    )
    context.insert(record)

    // Create credit
    let credit = PurchaseCredit(
        reportArea: ReportArea.allCases.randomElement()!.rawValue,  // TODO: Get from purchase context
        transactionID: String(transaction.id),
        purchaseDate: transaction.purchaseDate
    )
    credit.purchaseRecord = record
    context.insert(credit)

    // Atomic save
    try context.save()

    print("✅ Delivered \(record.creditAmount) credit(s) for transaction \(transaction.id)")
}
```

### Credit Consumption Atomicity

```swift
// Consume credit and link to report generation atomically
func consumeCredit(
    for reportArea: ReportArea,
    profileID: UUID,
    context: ModelContext
) throws -> PurchaseCredit {
    // Find available credit
    guard let credit = getAvailableCredits(for: reportArea, context: context).first else {
        throw CreditError.insufficientCredits
    }

    // Mark as consumed
    credit.consume(for: profileID)

    // Save atomically
    try context.save()

    return credit
}
```

## Testing Data

### Fixture Data for Tests

```swift
// File: AstroSvitlaTests/Fixtures/PurchaseFixtures.swift

extension PurchaseRecord {
    static func fixture(
        transactionID: String = "TEST-\(UUID().uuidString)",
        productID: String = "com.astrosvitla.report.credit.single",
        creditAmount: Int = 1
    ) -> PurchaseRecord {
        return PurchaseRecord(
            productID: productID,
            transactionID: transactionID,
            priceUSD: 4.99,
            localizedPrice: "$4.99",
            currencyCode: "USD",
            creditAmount: creditAmount,
            purchaseDate: Date()
        )
    }
}

extension PurchaseCredit {
    static func fixture(
        reportArea: ReportArea = .personality,
        consumed: Bool = false,
        transactionID: String = "TEST-\(UUID().uuidString)"
    ) -> PurchaseCredit {
        let credit = PurchaseCredit(
            reportArea: reportArea.rawValue,
            transactionID: transactionID
        )

        if consumed {
            credit.consume(for: UUID())
        }

        return credit
    }
}
```

## Performance Considerations

### Indexing

SwiftData automatically indexes:
- ✅ `@Attribute(.unique)` fields: `id`, `transactionID`
- ✅ Relationship inverse: `PurchaseCredit.purchaseRecord`

### Query Optimization

```swift
// ❌ Bad: Fetch all then filter in memory
let allCredits = try context.fetch(FetchDescriptor<PurchaseCredit>())
let available = allCredits.filter { !$0.consumed }

// ✅ Good: Filter in database with predicate
let descriptor = FetchDescriptor<PurchaseCredit>(
    predicate: #Predicate { !$0.consumed }
)
let available = try context.fetch(descriptor)
```

### Batch Operations

```swift
// For analytics: Batch fetch all records
let descriptor = FetchDescriptor<PurchaseRecord>(
    sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)]
)
descriptor.fetchLimit = 100  // Limit to recent 100 purchases
let recentPurchases = try context.fetch(descriptor)
```

## Schema Version

**Version**: 1.0.0 (Initial schema)

**Backward Compatibility**: N/A (new feature)

**Future Changes**:
- Add `creditPackSize` enum to support 1/5/10 credit packs
- Add `promotionalDiscount` field for discount tracking
- Add `subscriptionPeriod` for future subscription model

## References

- Spec: [spec.md](spec.md) - FR-006, FR-007, FR-008, FR-009, FR-012, FR-014
- Research: [research.md](research.md) - Decision 3: SwiftData Model Design
- Constitution: SwiftData mandated for all persistence
