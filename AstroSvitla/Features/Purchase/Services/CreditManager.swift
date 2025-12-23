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

@MainActor
@Observable
final class CreditManager {
    
    // MARK: - Dependencies
    
    private let context: ModelContext
    
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
    
    func consumeCredit(for reportArea: String, profileID: UUID) throws -> PurchaseCredit {
        // Find first available credit for this report area
        let descriptor = FetchDescriptor<PurchaseCredit>(
            predicate: #Predicate { !$0.consumed && $0.reportArea == reportArea },
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
    
    // MARK: - Localized Display
    
    func availableCreditsText() -> String {
        let count = getAvailableCreditCount()
        if count == 0 {
            return String(localized: "purchase.credits.none")
        } else {
            return String(format: String(localized: "purchase.credits.available"), count)
        }
    }
    
    func reportStatusText(hasCredit: Bool) -> String {
        if hasCredit {
            return String(localized: "purchase.report.available")
        } else {
            return String(localized: "purchase.report.locked")
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
