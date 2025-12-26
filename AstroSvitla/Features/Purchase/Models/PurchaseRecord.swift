//  PurchaseRecord.swift
//  AstroSvitla
//
//  Created on 2025-12-23
//  Feature: 008-implement-in-app
//
//  Represents a completed StoreKit transaction.
//  One transaction may create multiple credits (for future credit packs).

import Foundation
import SwiftData

@Model
final class PurchaseRecord {
    /// Unique identifier for this purchase record
    @Attribute(.unique)
    var id: UUID
    
    /// StoreKit product identifier (captured from the RevenueCat product)
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
