//  StoreKitProductContractTests.swift
//  AstroSvitlaTests
//
//  Created on 2025-12-23
//  Feature: 008-implement-in-app
//
//  Contract tests to validate StoreKit product configuration

import Testing
import StoreKit
@testable import AstroSvitla

@Suite("StoreKit Product Contract Tests")
struct StoreKitProductContractTests {
    
    @Test("Single credit product exists in App Store")
    func testSingleCreditProductExists() async throws {
        let products = try await Product.products(
            for: ["com.astrosvitla.report.credit.single"]
        )
        
        #expect(products.count == 1, "Expected exactly 1 product")
        
        let product = products[0]
        #expect(product.id == "com.astrosvitla.report.credit.single")
    }
    
    @Test("Single credit product is consumable type")
    func testProductIsConsumable() async throws {
        let products = try await Product.products(
            for: ["com.astrosvitla.report.credit.single"]
        )
        
        let product = products[0]
        #expect(product.type == .consumable, "Product must be consumable type")
    }
    
    @Test("Product has valid pricing information")
    func testProductPricing() async throws {
        let products = try await Product.products(
            for: ["com.astrosvitla.report.credit.single"]
        )
        
        let product = products[0]
        
        // Price should be greater than 0
        #expect(product.price > 0, "Product must have valid price")
        
        // Display price should not be empty
        #expect(!product.displayPrice.isEmpty, "Product must have display price")
        
        // Should have currency code
        #expect(
            !product.priceFormatStyle.currencyCode.identifier.isEmpty,
            "Product must have currency code"
        )
    }
    
    @Test("Product has localized display name")
    func testProductDisplayName() async throws {
        let products = try await Product.products(
            for: ["com.astrosvitla.report.credit.single"]
        )
        
        let product = products[0]
        
        #expect(!product.displayName.isEmpty, "Product must have display name")
        #expect(
            product.displayName.contains("Credit") || product.displayName.contains("кредит"),
            "Display name should mention 'Credit' or Ukrainian equivalent"
        )
    }
    
    @Test("Product has localized description")
    func testProductDescription() async throws {
        let products = try await Product.products(
            for: ["com.astrosvitla.report.credit.single"]
        )
        
        let product = products[0]
        
        #expect(!product.description.isEmpty, "Product must have description")
    }
    
    @Test("Product IDs match enum definition")
    func testProductIDsMatchEnum() {
        let enumProductIDs = Set(PurchaseProduct.allCases.map { $0.rawValue })
        let expectedIDs = Set(["com.astrosvitla.report.credit.single"])
        
        #expect(enumProductIDs == expectedIDs, "Enum product IDs must match contract definition")
    }
    
    @Test("Credit amount mapping is correct")
    func testCreditAmountMapping() {
        let product = PurchaseProduct.singleCredit
        #expect(product.creditAmount == 1, "Single credit product must provide 1 credit")
    }
}
