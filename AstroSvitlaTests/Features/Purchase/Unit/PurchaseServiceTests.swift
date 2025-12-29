//  RevenueCatPurchaseServiceTests.swift
//  AstroSvitlaTests
//
//  Created on 2025-12-23
//  Feature: 008-implement-in-app

import Testing
import SwiftData
@testable import AstroSvitla

@Suite("RevenueCatPurchaseService Tests")
struct RevenueCatPurchaseServiceTests {
    
    @Test("Initial state is not ready and cannot purchase")
    func testInitialState() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PurchaseCredit.self, PurchaseRecord.self,
            configurations: config
        )
        let context = container.mainContext
        
        let service = RevenueCatPurchaseService(context: context)

        #expect(service.isReady == false)
        #expect(service.canPurchase() == false)
    }
    
    @Test("Price helpers return localized fallback when no offerings")
    func testPriceFallback() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PurchaseCredit.self, PurchaseRecord.self,
            configurations: config
        )
        let context = container.mainContext
        let service = RevenueCatPurchaseService(context: context)

        let fallback = String(localized: "purchase.price.unavailable", defaultValue: "Payment Unavailable")
        #expect(service.getProductPrice() == fallback)
        #expect(RevenueCatPurchaseService.displayPrice(from: nil) == fallback)
        #expect(RevenueCatPurchaseService.displayPrice(from: service) == fallback)
    }
}
