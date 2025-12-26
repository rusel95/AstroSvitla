//  CreditManager.swift
//  AstroSvitla
//
//  Created on 2025-12-23
//  Feature: 008-implement-in-app
//
//  Service for managing credit allocation, consumption, and querying

import Foundation
import SwiftData
import Observation
import Sentry

@MainActor
@Observable
final class CreditManager {
    
    // MARK: - Dependencies
    
    private let context: ModelContext

    private enum Constants {
        static let universalReportArea = "universal"
    }
    
    // MARK: - Initialization
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // MARK: - Credit Queries
    
    func getAvailableCredits() -> [PurchaseCredit] {
        let descriptor = FetchDescriptor<PurchaseCredit>(
            predicate: #Predicate { !$0.consumed },
            sortBy: [SortDescriptor(\.purchaseDate, order: .forward)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func getAvailableCreditCount() -> Int {
        let descriptor = FetchDescriptor<PurchaseCredit>(
            predicate: #Predicate { !$0.consumed }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }
    
    func hasAvailableCredits() -> Bool {
        return getAvailableCreditCount() > 0
    }
    
    // MARK: - Credit Consumption
    
    /// Consumes a credit for generating a report
    /// 
    /// **Note on credit types**: Currently, all credits are stored as "universal" credits,
    /// meaning they can be used for any report area (personality, career, relationship, wellness).
    /// The `reportArea` parameter is accepted for API compatibility but is not currently used
    /// for filtering credits. This design allows flexibility for future area-specific pricing
    /// while maintaining a simple credit system for now.
    ///
    /// - Parameters:
    ///   - reportArea: The report area identifier (currently not used for filtering, reserved for future use)
    ///   - profileID: The profile ID that will consume this credit
    /// - Returns: The consumed credit
    /// - Throws: `CreditError.insufficientCredits` if no credits are available
    func consumeCredit(for reportArea: String, profileID: UUID) throws -> PurchaseCredit {
        // Find first available universal credit
        // Note: We currently use "universal" credits for all report types
        // The reportArea parameter is reserved for future area-specific credit support
        let universalArea = Constants.universalReportArea
        let descriptor = FetchDescriptor<PurchaseCredit>(
            predicate: #Predicate { !$0.consumed && $0.reportArea == universalArea },
            sortBy: [SortDescriptor(\.purchaseDate, order: .forward)]
        )
        
        guard let credit = try context.fetch(descriptor).first else {
            throw CreditError.insufficientCredits
        }
        
        // Mark as consumed
        credit.consume(for: profileID)
        
        // Save atomically
        try context.save()
        
        return credit
    }
    
    // MARK: - Credit History
    
    func getCreditHistory(for profileID: UUID) -> [PurchaseCredit] {
        let descriptor = FetchDescriptor<PurchaseCredit>(
            predicate: #Predicate { $0.consumed && $0.userProfileID == profileID },
            sortBy: [SortDescriptor(\.consumedDate, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func getAllCredits() -> [PurchaseCredit] {
        let descriptor = FetchDescriptor<PurchaseCredit>(
            sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    // MARK: - Trial Credit
    
    /// Transaction ID used for trial credits
    static let trialTransactionID = "trial-first-report-free"
    
    /// Check if user has ever had any credits (trial or purchased)
    func hasEverHadCredits() -> Bool {
        let descriptor = FetchDescriptor<PurchaseCredit>()
        return (try? context.fetchCount(descriptor)) ?? 0 > 0
    }
    
    /// Check if user has a trial credit specifically
    func hasTrialCredit() -> Bool {
        let trialID = Self.trialTransactionID
        let descriptor = FetchDescriptor<PurchaseCredit>(
            predicate: #Predicate { $0.transactionID == trialID && !$0.consumed }
        )
        return (try? context.fetchCount(descriptor)) ?? 0 > 0
    }
    
    /// Check if user has used their trial credit
    func hasUsedTrialCredit() -> Bool {
        let trialID = Self.trialTransactionID
        let descriptor = FetchDescriptor<PurchaseCredit>(
            predicate: #Predicate { $0.transactionID == trialID && $0.consumed }
        )
        return (try? context.fetchCount(descriptor)) ?? 0 > 0
    }
    
    /// Grant a free trial credit if user hasn't received one yet
    /// Returns true if trial was granted, false if already granted
    @discardableResult
    func grantTrialCreditIfNeeded() -> Bool {
        // Check if user already has any credits (trial or purchased)
        guard !hasEverHadCredits() else {
            #if DEBUG
            print("📦 [CreditManager] User already has credits, skipping trial")
            #endif
            return false
        }
        
        // Create trial credit
        let trialCredit = PurchaseCredit(
            reportArea: Constants.universalReportArea,
            transactionID: Self.trialTransactionID,
            purchaseDate: Date()
        )
        
        context.insert(trialCredit)
        
        do {
            try context.save()
            #if DEBUG
            print("🎁 [CreditManager] Trial credit granted successfully!")
            #endif
            
            // Log to Sentry for analytics
            let breadcrumb = Breadcrumb()
            breadcrumb.level = .info
            breadcrumb.category = "credit"
            breadcrumb.message = "Trial credit granted"
            SentrySDK.addBreadcrumb(breadcrumb)
            
            return true
        } catch {
            #if DEBUG
            print("❌ [CreditManager] Failed to grant trial credit: \(error)")
            #endif
            
            // Log error to Sentry
            SentrySDK.capture(error: error) { scope in
                scope.setLevel(.error)
                scope.setTag(value: "trial_credit", key: "operation")
                scope.setContext(value: ["action": "grantTrialCredit"], key: "credit_manager")
            }
            
            return false
        }
    }
    
    // MARK: - Localized Display
    
    func availableCreditsText() -> String {
        let count = getAvailableCreditCount()
        if count == 0 {
            return String(localized: "purchase.credits.none", defaultValue: "No credits")
        } else {
            return String(format: String(localized: "purchase.credits.available", defaultValue: "%d credits available"), count)
        }
    }
    
    func reportStatusText(hasCredit: Bool) -> String {
        if hasCredit {
            return String(localized: "purchase.report.available", defaultValue: "Report available")
        } else {
            return String(localized: "purchase.report.locked", defaultValue: "Unlock report")
        }
    }
    
    /// Get display text for the price/action button
    func priceDisplayText(purchaseService: RevenueCatPurchaseService) -> String {
        if hasTrialCredit() {
            return String(localized: "purchase.price.free", defaultValue: "FREE")
        } else {
            return purchaseService.getProductPrice()
        }
    }
}

// MARK: - Credit Error

enum CreditError: LocalizedError {
    case insufficientCredits
    
    var errorDescription: String? {
        switch self {
        case .insufficientCredits:
            return String(localized: "purchase.error.insufficient", defaultValue: "You don't have enough credits. Please purchase more to continue.")
        }
    }
}
