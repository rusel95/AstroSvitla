//  PurchaseService.swift
//  AstroSvitla
//
//  Created on 2025-12-23
//  Feature: 008-implement-in-app
//
//  Service for handling StoreKit 2 purchases and transaction management

import Foundation
import StoreKit
import SwiftData
import Observation
import Sentry

@MainActor
@Observable
final class PurchaseService {
    
    // MARK: - Published Properties
    
    private(set) var products: [Product] = []
    private(set) var isPurchasing = false
    var purchaseError: PurchaseError?
    
    /// Indicates if IAP system is available and working
    /// If false, users can still generate reports (graceful degradation)
    private(set) var isIAPAvailable = true
    
    // MARK: - Dependencies
    
    private let context: ModelContext
    private var transactionListenerTask: Task<Void, Error>?
    
    // MARK: - Initialization
    
    init(context: ModelContext) {
        self.context = context
        startTransactionListener()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async throws {
        let productIDs = PurchaseProduct.allCases.map { $0.rawValue }
        
        let breadcrumb = Breadcrumb()
        breadcrumb.level = .info
        breadcrumb.category = "purchase"
        breadcrumb.message = "Loading products"
        breadcrumb.data = ["productCount": productIDs.count]
        SentrySDK.addBreadcrumb(breadcrumb)
        
        do {
            let loadedProducts = try await Product.products(for: productIDs)
            
            // Validate product types
            for product in loadedProducts {
                guard product.type == .consumable else {
                    let errorBreadcrumb = Breadcrumb()
                    errorBreadcrumb.level = .error
                    errorBreadcrumb.category = "purchase"
                    errorBreadcrumb.message = "Invalid product type"
                    errorBreadcrumb.data = ["productId": product.id, "type": "\(product.type)"]
                    SentrySDK.addBreadcrumb(errorBreadcrumb)
                    
                    // Log to Sentry but don't block users
                    SentrySDK.capture(message: "Invalid StoreKit product type") { scope in
                        scope.setContext(value: [
                            "productId": product.id,
                            "expectedType": "consumable",
                            "actualType": "\(product.type)"
                        ], key: "product")
                    }
                    
                    isIAPAvailable = false
                    throw PurchaseError.productNotFound
                }
            }
            
            self.products = loadedProducts
            isIAPAvailable = true
            
            let successBreadcrumb = Breadcrumb()
            successBreadcrumb.level = .info
            successBreadcrumb.category = "purchase"
            successBreadcrumb.message = "Products loaded successfully"
            successBreadcrumb.data = ["count": loadedProducts.count]
            SentrySDK.addBreadcrumb(successBreadcrumb)
        } catch {
            let failBreadcrumb = Breadcrumb()
            failBreadcrumb.level = .error
            failBreadcrumb.category = "purchase"
            failBreadcrumb.message = "Product load failed - IAP unavailable, allowing report generation"
            failBreadcrumb.data = ["error": error.localizedDescription]
            SentrySDK.addBreadcrumb(failBreadcrumb)
            
            // Log to Sentry as error (not crash)
            SentrySDK.capture(error: error) { scope in
                scope.setLevel(.error)
                scope.setContext(value: [
                    "action": "loadProducts",
                    "productIds": productIDs,
                    "gracefulDegradation": true
                ], key: "iap")
            }
            
            // Mark IAP as unavailable but don't block users
            isIAPAvailable = false
            self.products = []
            
            // Don't throw - allow app to continue without IAP
            #if DEBUG
            print("⚠️ [PurchaseService] IAP unavailable, users can still generate reports")
            #endif
        }
    }
    
    // MARK: - Product Price Helpers
    
    /// Get localized price from StoreKit product, or fallback message
    func getProductPrice() -> String {
        guard isIAPAvailable, let product = products.first else {
            return String(localized: "purchase.price.unavailable", defaultValue: "Payment Unavailable")
        }
        return product.displayPrice
    }
    
    /// Check if IAP system is working
    func canPurchase() -> Bool {
        return isIAPAvailable && !products.isEmpty
    }
    
    // MARK: - Purchase Flow
    
    func purchase(_ product: Product) async throws -> Transaction? {
        isPurchasing = true
        purchaseError = nil
        
        let breadcrumb = Breadcrumb()
        breadcrumb.level = .info
        breadcrumb.category = "purchase"
        breadcrumb.message = "Purchase initiated"
        breadcrumb.data = ["productId": product.id, "price": product.displayPrice]
        SentrySDK.addBreadcrumb(breadcrumb)
        
        defer {
            isPurchasing = false
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verificationResult):
                let transaction = try checkVerified(verificationResult)
                
                let successBreadcrumb = Breadcrumb()
                successBreadcrumb.level = .info
                successBreadcrumb.category = "purchase"
                successBreadcrumb.message = "Purchase completed"
                successBreadcrumb.data = ["productId": product.id, "transactionId": String(transaction.id)]
                SentrySDK.addBreadcrumb(successBreadcrumb)
                
                // Deliver credits
                try await deliverCredits(for: transaction, product: product)
                
                // Finish transaction
                await transaction.finish()
                
                return transaction
                
            case .userCancelled:
                let cancelBreadcrumb = Breadcrumb()
                cancelBreadcrumb.level = .info
                cancelBreadcrumb.category = "purchase"
                cancelBreadcrumb.message = "Purchase cancelled by user"
                cancelBreadcrumb.data = ["productId": product.id]
                SentrySDK.addBreadcrumb(cancelBreadcrumb)
                throw PurchaseError.userCancelled
                
            case .pending:
                let pendingBreadcrumb = Breadcrumb()
                pendingBreadcrumb.level = .info
                pendingBreadcrumb.category = "purchase"
                pendingBreadcrumb.message = "Purchase pending approval"
                pendingBreadcrumb.data = ["productId": product.id]
                SentrySDK.addBreadcrumb(pendingBreadcrumb)
                // "Ask to Buy" pending - transaction listener will handle when approved
                return nil
                
            @unknown default:
                let unknownBreadcrumb = Breadcrumb()
                unknownBreadcrumb.level = .error
                unknownBreadcrumb.category = "purchase"
                unknownBreadcrumb.message = "Unknown purchase result"
                unknownBreadcrumb.data = ["productId": product.id]
                SentrySDK.addBreadcrumb(unknownBreadcrumb)
                throw PurchaseError.storePurchaseFailed(NSError(domain: "StoreKit", code: -1))
            }
        } catch let error as PurchaseError {
            let errorBreadcrumb = Breadcrumb()
            errorBreadcrumb.level = .error
            errorBreadcrumb.category = "purchase"
            errorBreadcrumb.message = "Purchase failed"
            errorBreadcrumb.data = ["productId": product.id, "error": error.localizedDescription]
            SentrySDK.addBreadcrumb(errorBreadcrumb)
            purchaseError = error
            throw error
        } catch {
            let unexpectedBreadcrumb = Breadcrumb()
            unexpectedBreadcrumb.level = .error
            unexpectedBreadcrumb.category = "purchase"
            unexpectedBreadcrumb.message = "Purchase failed with unexpected error"
            unexpectedBreadcrumb.data = ["productId": product.id, "error": error.localizedDescription]
            SentrySDK.addBreadcrumb(unexpectedBreadcrumb)
            let wrappedError = PurchaseError.storePurchaseFailed(error)
            purchaseError = wrappedError
            throw wrappedError
        }
    }
    
    // MARK: - Transaction Verification
    
    private func checkVerified(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .unverified(_, let error):
            throw PurchaseError.failedVerification(error)
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Credit Delivery
    
    func deliverCredits(for transaction: Transaction, product: Product) async throws {
        let transactionID = String(transaction.id)
        
        // Check for duplicate
        guard !isTransactionProcessed(transactionID) else {
            #if DEBUG
            print("⚠️ Transaction already processed: \(transactionID)")
            #endif
            return
        }
        
        do {
            // Create purchase record
            let record = PurchaseRecord(
                productID: transaction.productID,
                transactionID: transactionID,
                priceUSD: product.price as Decimal,
                localizedPrice: product.displayPrice,
                currencyCode: product.priceFormatStyle.currencyCode,
                creditAmount: 1,
                purchaseDate: transaction.purchaseDate
            )
            context.insert(record)
            
            // Create credit
            // Use "universal" to indicate this credit can be used for any report area
            let credit = PurchaseCredit(
                reportArea: "universal",
                transactionID: transactionID,
                purchaseDate: transaction.purchaseDate
            )
            credit.purchaseRecord = record
            context.insert(credit)
            
            // Atomic save
            try context.save()
            
            #if DEBUG
            print("✅ Delivered credit for transaction \(transactionID)")
            #endif
        } catch {
            throw PurchaseError.saveFailed(error)
        }
    }
    
    // MARK: - Transaction Listener
    
    private func startTransactionListener() {
        transactionListenerTask = Task.detached { [weak self] in
            for await verificationResult in Transaction.updates {
                await self?.handleTransactionUpdate(verificationResult)
            }
        }
    }
    
    private func handleTransactionUpdate(_ verificationResult: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(verificationResult)
            
            // Find product
            guard let product = products.first(where: { $0.id == transaction.productID }) else {
                #if DEBUG
                print("⚠️ Product not found for transaction: \(transaction.productID)")
                #endif
                await transaction.finish()
                return
            }
            
            // Deliver credits if not already delivered
            try await deliverCredits(for: transaction, product: product)
            
            // Finish transaction
            await transaction.finish()
        } catch {
            #if DEBUG
            print("❌ Failed to handle transaction update: \(error)")
            #endif
            
            // Log to Sentry
            SentrySDK.capture(error: error) { scope in
                scope.setLevel(.error)
                scope.setTag(value: "transaction_listener", key: "operation")
                scope.setContext(value: ["action": "handleTransactionUpdate"], key: "purchase_service")
            }
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws {
        let breadcrumb = Breadcrumb()
        breadcrumb.level = .info
        breadcrumb.category = "purchase"
        breadcrumb.message = "Restore purchases initiated"
        SentrySDK.addBreadcrumb(breadcrumb)
        
        var restoredCount = 0
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            
            let transactionID = String(transaction.id)
            
            // Only restore if not already delivered
            if !isTransactionProcessed(transactionID) {
                // Find product
                guard let product = products.first(where: { $0.id == transaction.productID }) else {
                    await transaction.finish()
                    continue
                }
                
                try await deliverCredits(for: transaction, product: product)
                restoredCount += 1
                
                // Mark as restored
                if let record = findPurchaseRecord(transactionID: transactionID) {
                    record.markAsRestored()
                    try context.save()
                }
            }
            
            await transaction.finish()
        }
        
        let completeBreadcrumb = Breadcrumb()
        completeBreadcrumb.level = .info
        completeBreadcrumb.category = "purchase"
        completeBreadcrumb.message = "Restore purchases completed"
        completeBreadcrumb.data = ["restoredCount": restoredCount]
        SentrySDK.addBreadcrumb(completeBreadcrumb)
    }
    
    // MARK: - Helpers
    
    func isTransactionProcessed(_ transactionID: String) -> Bool {
        let descriptor = FetchDescriptor<PurchaseRecord>(
            predicate: #Predicate { $0.transactionID == transactionID }
        )
        return (try? context.fetchCount(descriptor)) ?? 0 > 0
    }
    
    private func findPurchaseRecord(transactionID: String) -> PurchaseRecord? {
        let descriptor = FetchDescriptor<PurchaseRecord>(
            predicate: #Predicate { $0.transactionID == transactionID }
        )
        return try? context.fetch(descriptor).first
    }
}
