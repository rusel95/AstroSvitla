//  PurchaseRecordTests.swift
//  AstroSvitlaTests
//
//  Created on 2025-12-23
//  Feature: 008-implement-in-app

import Testing
import SwiftData
@testable import AstroSvitla

@Suite("PurchaseRecord Model Tests")
struct PurchaseRecordTests {
    
    /// Test that a record can be created with all fields
    @Test("Record creation with all fields")
    func testRecordCreation() throws {
        let productID = "test.product"
        let transactionID = "TEST-RECORD-123"
        let priceUSD: Decimal = 4.99
        let localizedPrice = "$4.99"
        let currencyCode = "USD"
        let creditAmount = 1
        
        let record = PurchaseRecord(
            productID: productID,
            transactionID: transactionID,
            priceUSD: priceUSD,
            localizedPrice: localizedPrice,
            currencyCode: currencyCode,
            creditAmount: creditAmount
        )
        
        #expect(record.id != nil)
        #expect(record.productID == productID)
        #expect(record.transactionID == transactionID)
        #expect(record.priceUSD == priceUSD)
        #expect(record.localizedPrice == localizedPrice)
        #expect(record.currencyCode == currencyCode)
        #expect(record.creditAmount == creditAmount)
        #expect(record.purchaseDate != nil)
        #expect(record.restoredDate == nil)
        #expect(record.credits.isEmpty)
    }
    
    /// Test that a record can be marked as restored
    @Test("Mark record as restored sets restoredDate")
    func testMarkAsRestored() throws {
        let record = PurchaseRecord(
            productID: "test.product",
            transactionID: "TEST-RESTORE-456",
            priceUSD: 4.99,
            localizedPrice: "$4.99",
            currencyCode: "USD"
        )
        
        #expect(record.restoredDate == nil)
        #expect(record.isRestored == false)
        
        record.markAsRestored()
        
        #expect(record.restoredDate != nil)
        #expect(record.isRestored == true)
        
        // Test that calling again doesn't change the date
        let firstRestoredDate = record.restoredDate
        record.markAsRestored()
        #expect(record.restoredDate == firstRestoredDate)
    }
    
    /// Test that isRestored computed property works correctly
    @Test("isRestored property returns correct value")
    func testIsRestoredProperty() throws {
        let record = PurchaseRecord(
            productID: "test.product",
            transactionID: "TEST-PROP-789",
            priceUSD: 4.99,
            localizedPrice: "$4.99",
            currencyCode: "USD"
        )
        
        #expect(record.isRestored == false)
        
        record.markAsRestored()
        
        #expect(record.isRestored == true)
    }
    
    /// Test that availableCredits filters correctly
    @Test("availableCredits returns only unconsumed credits")
    func testAvailableCreditsFiltering() throws {
        let record = PurchaseRecord(
            productID: "test.product",
            transactionID: "TEST-FILTER-111",
            priceUSD: 4.99,
            localizedPrice: "$4.99",
            currencyCode: "USD",
            creditAmount: 3
        )
        
        // Create mock credits
        let credit1 = PurchaseCredit(reportArea: ReportArea.general.rawValue, transactionID: "TEST-C1")
        let credit2 = PurchaseCredit(reportArea: ReportArea.career.rawValue, transactionID: "TEST-C2")
        let credit3 = PurchaseCredit(reportArea: ReportArea.relationships.rawValue, transactionID: "TEST-C3")
        
        // Consume one credit
        credit2.consume(for: UUID())
        
        record.credits = [credit1, credit2, credit3]
        
        let available = record.availableCredits
        #expect(available.count == 2)
        #expect(available.contains { $0.reportArea == ReportArea.general.rawValue })
        #expect(available.contains { $0.reportArea == ReportArea.relationships.rawValue })
        #expect(!available.contains { $0.reportArea == ReportArea.career.rawValue })
    }
    
    /// Test that consumedCredits filters correctly
    @Test("consumedCredits returns only consumed credits")
    func testConsumedCreditsFiltering() throws {
        let record = PurchaseRecord(
            productID: "test.product",
            transactionID: "TEST-CONSUMED-222",
            priceUSD: 4.99,
            localizedPrice: "$4.99",
            currencyCode: "USD",
            creditAmount: 3
        )
        
        // Create mock credits
        let credit1 = PurchaseCredit(reportArea: ReportArea.general.rawValue, transactionID: "TEST-D1")
        let credit2 = PurchaseCredit(reportArea: ReportArea.career.rawValue, transactionID: "TEST-D2")
        let credit3 = PurchaseCredit(reportArea: ReportArea.health.rawValue, transactionID: "TEST-D3")
        
        // Consume two credits
        credit1.consume(for: UUID())
        credit3.consume(for: UUID())
        
        record.credits = [credit1, credit2, credit3]
        
        let consumed = record.consumedCredits
        #expect(consumed.count == 2)
        #expect(consumed.contains { $0.reportArea == ReportArea.general.rawValue })
        #expect(consumed.contains { $0.reportArea == ReportArea.health.rawValue })
        #expect(!consumed.contains { $0.reportArea == ReportArea.career.rawValue })
    }
}
