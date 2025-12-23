//  CreditManagerTests.swift
//  AstroSvitlaTests
//
//  Created on 2025-12-23
//  Feature: 008-implement-in-app

import Testing
import SwiftData
@testable import AstroSvitla

@Suite("CreditManager Tests")
struct CreditManagerTests {
    
    @Test("Get available credits returns only unconsumed credits")
    func testGetAvailableCredits() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PurchaseCredit.self, PurchaseRecord.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Create test credits
        let credit1 = PurchaseCredit.fixture(consumed: false)
        let credit2 = PurchaseCredit.fixture(consumed: true)
        let credit3 = PurchaseCredit.fixture(consumed: false)
        
        context.insert(credit1)
        context.insert(credit2)
        context.insert(credit3)
        try context.save()
        
        let manager = CreditManager(context: context)
        let available = manager.getAvailableCredits()
        
        #expect(available.count == 2, "Should return 2 available credits")
        #expect(available.allSatisfy { !$0.consumed }, "All returned credits should be unconsumed")
    }
    
    @Test("Get available credit count returns correct count")
    func testGetAvailableCreditCount() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PurchaseCredit.self, PurchaseRecord.self,
            configurations: config
        )
        let context = container.mainContext
        
        // Create 3 available, 2 consumed
        for _ in 0..<3 {
            context.insert(PurchaseCredit.fixture(consumed: false))
        }
        for _ in 0..<2 {
            context.insert(PurchaseCredit.fixture(consumed: true))
        }
        try context.save()
        
        let manager = CreditManager(context: context)
        let count = manager.getAvailableCreditCount()
        
        #expect(count == 3, "Should return 3 available credits")
    }
    
    @Test("Consume credit marks credit as consumed and links to profile")
    func testConsumeCredit() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PurchaseCredit.self, PurchaseRecord.self,
            configurations: config
        )
        let context = container.mainContext
        
        let credit = PurchaseCredit.fixture(reportArea: "career", consumed: false)
        context.insert(credit)
        try context.save()
        
        let manager = CreditManager(context: context)
        let profileID = UUID()
        
        let consumedCredit = try manager.consumeCredit(for: "career", profileID: profileID)
        
        #expect(consumedCredit.consumed == true)
        #expect(consumedCredit.userProfileID == profileID)
        #expect(consumedCredit.consumedDate != nil)
    }
    
    @Test("Consume credit throws error when insufficient credits")
    func testConsumeCreditInsufficientCredits() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PurchaseCredit.self, PurchaseRecord.self,
            configurations: config
        )
        let context = container.mainContext
        
        let manager = CreditManager(context: context)
        let profileID = UUID()
        
        #expect(throws: CreditError.self) {
            try manager.consumeCredit(for: "personality", profileID: profileID)
        }
    }
    
    @Test("Get credit history returns credits for specific profile")
    func testGetCreditHistory() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PurchaseCredit.self, PurchaseRecord.self,
            configurations: config
        )
        let context = container.mainContext
        
        let profileID1 = UUID()
        let profileID2 = UUID()
        
        let credit1 = PurchaseCredit.fixture(consumed: true, userProfileID: profileID1)
        let credit2 = PurchaseCredit.fixture(consumed: true, userProfileID: profileID2)
        let credit3 = PurchaseCredit.fixture(consumed: true, userProfileID: profileID1)
        
        context.insert(credit1)
        context.insert(credit2)
        context.insert(credit3)
        try context.save()
        
        let manager = CreditManager(context: context)
        let history = manager.getCreditHistory(for: profileID1)
        
        #expect(history.count == 2, "Should return 2 credits for profile 1")
        #expect(history.allSatisfy { $0.userProfileID == profileID1 })
    }
}
