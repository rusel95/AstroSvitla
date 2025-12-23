//  PurchaseCredit.swift
//  AstroSvitla
//
//  Created on 2025-12-23
//  Feature: 008-implement-in-app
//
//  Represents a single consumable credit for generating one report.
//  Credits are tracked globally (not locked to specific profiles) but record
//  which profile they were used for when consumed.

import Foundation
import SwiftData

@Model
final class PurchaseCredit {
    /// Unique identifier for this credit
    @Attribute(.unique)
    var id: UUID
    
    /// Report area this credit is valid for
    /// Maps to ReportArea enum: .personality, .career, .relationship, .wellness
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
