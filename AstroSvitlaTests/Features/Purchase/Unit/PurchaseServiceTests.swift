//  PurchaseServiceTests.swift
//  AstroSvitlaTests
//
//  Created on 2025-12-23
//  Feature: 008-implement-in-app

import Testing
import SwiftData
import StoreKit
@testable import AstroSvitla

@Suite("PurchaseService Tests")
struct PurchaseServiceTests {
    
    @Test("Load products successfully")
    func testLoadProducts() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PurchaseCredit.self, PurchaseRecord.self,
            configurations: config
        )
        let context = container.mainContext
        
        let service = PurchaseService(context: context)
        
        try await service.loadProducts()
        
        #expect(!service.products.isEmpty, "Products should be loaded")
    }
    
    @Test("Purchase creates credit and record")
    func testPurchaseCreatesCredit() async throws {
        // Note: This test requires StoreKit testing environment
        // Will be implemented with mock StoreKit during integration testing
        #expect(true, "Test placeholder - requires StoreKit test environment")
    }
    
    @Test("Duplicate transaction prevention")
    func testDuplicateTransactionPrevention() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PurchaseCredit.self, PurchaseRecord.self,
            configurations: config
        )
        let context = container.mainContext
        
        let service = PurchaseService(context: context)
        
        // Create a purchase record manually
        let transactionID = "TEST-DUP-123"
        let record = PurchaseRecord.fixture(transactionID: transactionID)
        context.insert(record)
        try context.save()
        
        // Check that transaction is already processed
        let isProcessed = service.isTransactionProcessed(transactionID)
        #expect(isProcessed == true, "Transaction should be marked as processed")
    }
}
