//  PurchaseFixtures.swift
//  AstroSvitlaTests
//
//  Created on 2025-12-23
//  Feature: 008-implement-in-app
//
//  Fixture helpers for creating test purchase data

import Foundation
@testable import AstroSvitla

extension PurchaseRecord {
    /// Create a fixture PurchaseRecord for testing
    static func fixture(
        transactionID: String = "TEST-\(UUID().uuidString)",
        productID: String = "com.astrosvitla.report.credit.single",
        priceUSD: Decimal = 4.99,
        localizedPrice: String = "$4.99",
        currencyCode: String = "USD",
        creditAmount: Int = 1,
        purchaseDate: Date = Date()
    ) -> PurchaseRecord {
        return PurchaseRecord(
            productID: productID,
            transactionID: transactionID,
            priceUSD: priceUSD,
            localizedPrice: localizedPrice,
            currencyCode: currencyCode,
            creditAmount: creditAmount,
            purchaseDate: purchaseDate
        )
    }
}

extension PurchaseCredit {
    /// Create a fixture PurchaseCredit for testing
    static func fixture(
        reportArea: String = "personality",
        consumed: Bool = false,
        transactionID: String = "TEST-\(UUID().uuidString)",
        purchaseDate: Date = Date(),
        userProfileID: UUID? = nil
    ) -> PurchaseCredit {
        let credit = PurchaseCredit(
            reportArea: reportArea,
            transactionID: transactionID,
            purchaseDate: purchaseDate
        )
        
        if consumed {
            let profileID = userProfileID ?? UUID()
            credit.consume(for: profileID)
        }
        
        return credit
    }
}
