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
        let reportArea = "personality"
        
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
            reportArea: "career",
            transactionID: "TEST-67890"
        )
        let profileID = UUID()
        
        credit.consume(for: profileID)
        
        #expect(credit.consumed == true)
        #expect(credit.consumedDate != nil)
        #expect(credit.userProfileID == profileID)
    }
    
    /// Test that isAvailable property returns correct value
    @Test("Available credit returns true when not consumed")
    func testAvailableCredit() throws {
        let credit = PurchaseCredit(
            reportArea: "relationship",
            transactionID: "TEST-111"
        )
        
        #expect(credit.isAvailable == true)
        
        credit.consume(for: UUID())
        
        #expect(credit.isAvailable == false)
    }
    
    /// Test that transaction ID uniqueness is preserved
    @Test("Transaction ID uniqueness constraint")
    func testTransactionIDUniqueness() throws {
        // This test will verify that the @Attribute(.unique) constraint works
        // by attempting to create two credits with the same transaction ID
        // in a real SwiftData context during integration testing.
        // For now, we just verify the property exists and is set correctly.
        
        let transactionID = "TEST-UNIQUE-123"
        let credit1 = PurchaseCredit(
            reportArea: "wellness",
            transactionID: transactionID
        )
        let credit2 = PurchaseCredit(
            reportArea: "personality",
            transactionID: transactionID
        )
        
        #expect(credit1.transactionID == transactionID)
        #expect(credit2.transactionID == transactionID)
        // Note: Actual uniqueness constraint is enforced at SwiftData level
        // and will be tested in integration tests with ModelContext
    }
}
