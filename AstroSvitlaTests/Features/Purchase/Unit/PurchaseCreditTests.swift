//  PurchaseCreditTests.swift
//  AstroSvitlaTests
//
//  Created on 2025-12-23
//  Feature: 008-implement-in-app

import Testing
import SwiftData
@testable import AstroSvitla

@Suite("PurchaseCredit Model Tests")
struct PurchaseCreditTests {
    
    /// Test that a credit can be created with required fields
    @Test("Credit creation with required fields")
    func testCreditCreation() throws {
        let transactionID = "TEST-12345"
        let reportArea = PurchaseCredit.universalReportArea
        
        let credit = PurchaseCredit(
            reportArea: reportArea,
            transactionID: transactionID
        )
        
        #expect(credit.id != nil)
        #expect(credit.reportArea == reportArea)
        #expect(credit.transactionID == transactionID)
        #expect(credit.consumed == false)
        #expect(credit.consumedDate == nil)
        #expect(credit.userProfileID == nil)
        #expect(credit.purchaseDate != nil)
    }
    
    /// Test that a credit can be marked as consumed
    @Test("Credit consumption marks credit as consumed")
    func testCreditConsumption() throws {
        let credit = PurchaseCredit(
            reportArea: ReportArea.career.rawValue,
            transactionID: "TEST-67890"
        )
        let profileID = UUID()
        
        credit.consume(for: profileID)
        let firstConsumedDate = credit.consumedDate
        credit.consume(for: UUID())
        
        #expect(credit.consumed == true)
        #expect(credit.consumedDate != nil)
        #expect(credit.consumedDate == firstConsumedDate)
        #expect(credit.userProfileID == profileID)
    }
    
    /// Test that isAvailable property returns correct value
    @Test("Available credit returns true when not consumed")
    func testAvailableCredit() throws {
        let credit = PurchaseCredit(
            reportArea: ReportArea.relationships.rawValue,
            transactionID: "TEST-111"
        )
        
        #expect(credit.isAvailable == true)
        
        credit.consume(for: UUID())
        
        #expect(credit.isAvailable == false)
    }
    
    /// Test that transaction ID values are assigned as expected
    @Test("Transaction ID assignment")
    func testTransactionIDAssignment() throws {
        // Note: uniqueness is enforced at the SwiftData layer and should be
        // validated in integration tests with a ModelContext.
        
        let transactionID = "TEST-UNIQUE-123"
        let credit1 = PurchaseCredit(
            reportArea: ReportArea.health.rawValue,
            transactionID: transactionID
        )
        let credit2 = PurchaseCredit(
            reportArea: ReportArea.general.rawValue,
            transactionID: transactionID
        )
        
        #expect(credit1.transactionID == transactionID)
        #expect(credit2.transactionID == transactionID)
    }
}
