//  RevenueCatPurchaseService.swift
//  AstroSvitla
//
//  Created for RevenueCat integration
//  Handles purchases, customer info, and entitlements using RevenueCat SDK

import Foundation
import RevenueCat
import SwiftData
import Observation
import Sentry

@MainActor
@Observable
final class RevenueCatPurchaseService {
    
    // MARK: - Published Properties
    
    /// Current offerings from RevenueCat
    private(set) var offerings: Offerings?
    
    /// Current customer info
    private(set) var customerInfo: CustomerInfo?
    
    /// Indicates if a purchase is in progress
    private(set) var isPurchasing = false
    
    /// Last error that occurred
    var purchaseError: Error?
    
    /// Indicates if the service is ready (offerings loaded)
    var isReady: Bool {
        offerings != nil
    }
    
    /// Check if user has Zorya Pro entitlement
    var hasProAccess: Bool {
        customerInfo?.entitlements[RevenueCatConfiguration.proEntitlementID]?.isActive == true
    }
    
    // MARK: - Dependencies
    
    private let context: ModelContext
    
    // MARK: - Initialization
    
    init(context: ModelContext) {
        self.context = context
        
        // Set delegate for customer info updates
        Purchases.shared.delegate = RevenueCatDelegate.shared
    }
    
    // MARK: - Loading
    
    /// Load offerings and customer info
    func load() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadOfferings() }
            group.addTask { await self.loadCustomerInfo() }
        }
    }
    
    /// Load available offerings from RevenueCat
    func loadOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            self.offerings = offerings
            
            #if DEBUG
            print("✅ [RevenueCat] Offerings loaded:")
            if let current = offerings.current {
                print("   Current offering: \(current.identifier)")
                for package in current.availablePackages {
                    print("   - \(package.identifier): \(package.storeProduct.localizedPriceString)")
                }
            }
            #endif
            
            let breadcrumb = Breadcrumb()
            breadcrumb.level = .info
            breadcrumb.category = "purchase"
            breadcrumb.message = "RevenueCat offerings loaded"
            breadcrumb.data = ["offeringCount": offerings.all.count]
            SentrySDK.addBreadcrumb(breadcrumb)
            
        } catch {
            #if DEBUG
            print("❌ [RevenueCat] Failed to load offerings: \(error)")
            #endif
            
            SentrySDK.capture(error: error) { scope in
                scope.setLevel(.error)
                scope.setContext(value: ["action": "loadOfferings"], key: "revenuecat")
            }
        }
    }
    
    /// Load current customer info
    func loadCustomerInfo() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            self.customerInfo = info
            
            #if DEBUG
            print("✅ [RevenueCat] Customer info loaded:")
            print("   App User ID: \(info.originalAppUserId)")
            print("   Active entitlements: \(info.entitlements.active.keys.joined(separator: ", "))")
            #endif
            
        } catch {
            #if DEBUG
            print("❌ [RevenueCat] Failed to load customer info: \(error)")
            #endif
        }
    }
    
    // MARK: - Purchases
    
    /// Purchase a package
    func purchase(package: Package) async throws -> CustomerInfo {
        isPurchasing = true
        purchaseError = nil
        
        defer { isPurchasing = false }
        
        let breadcrumb = Breadcrumb()
        breadcrumb.level = .info
        breadcrumb.category = "purchase"
        breadcrumb.message = "Purchase initiated"
        breadcrumb.data = [
            "packageId": package.identifier,
            "productId": package.storeProduct.productIdentifier,
            "price": package.storeProduct.localizedPriceString
        ]
        SentrySDK.addBreadcrumb(breadcrumb)
        
        do {
            let result = try await Purchases.shared.purchase(package: package)
            
            // Check if purchase was cancelled
            if result.userCancelled {
                throw PurchaseError.userCancelled
            }
            
            self.customerInfo = result.customerInfo
            
            // For consumables, deliver credits
            if package.storeProduct.productType == .consumable {
                await deliverCredits(for: result.transaction, product: package.storeProduct)
            }
            
            #if DEBUG
            print("✅ [RevenueCat] Purchase successful!")
            #endif
            
            let successBreadcrumb = Breadcrumb()
            successBreadcrumb.level = .info
            successBreadcrumb.category = "purchase"
            successBreadcrumb.message = "Purchase completed"
            successBreadcrumb.data = ["productId": package.storeProduct.productIdentifier]
            SentrySDK.addBreadcrumb(successBreadcrumb)
            
            return result.customerInfo
            
        } catch let error as ErrorCode {
            purchaseError = error
            
            #if DEBUG
            print("❌ [RevenueCat] Purchase failed with RevenueCat error: \(error)")
            #endif
            
            throw mapRevenueCatError(error)
            
        } catch {
            purchaseError = error
            
            #if DEBUG
            print("❌ [RevenueCat] Purchase failed: \(error)")
            #endif
            
            throw error
        }
    }
    
    /// Purchase consumable credit (convenience method)
    /// Finds the first consumable product from current offering
    func purchaseSingleCredit() async throws -> CustomerInfo {
        guard let offerings = offerings,
              let currentOffering = offerings.current else {
            throw PurchaseError.productNotFound
        }
        
        // Find first consumable package from current offering
        guard let consumablePackage = currentOffering.availablePackages.first(where: {
            $0.storeProduct.productType == .consumable
        }) else {
            throw PurchaseError.productNotFound
        }
        
        return try await purchase(package: consumablePackage)
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws -> CustomerInfo {
        let breadcrumb = Breadcrumb()
        breadcrumb.level = .info
        breadcrumb.category = "purchase"
        breadcrumb.message = "Restore purchases initiated"
        SentrySDK.addBreadcrumb(breadcrumb)
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            self.customerInfo = customerInfo
            
            #if DEBUG
            print("✅ [RevenueCat] Purchases restored")
            #endif
            
            return customerInfo
        } catch {
            #if DEBUG
            print("❌ [RevenueCat] Restore failed: \(error)")
            #endif
            throw error
        }
    }
    
    // MARK: - Product Helpers
    
    /// Get the current offering's consumable product
    var consumableProduct: StoreProduct? {
        offerings?.current?.availablePackages.first(where: {
            $0.storeProduct.productType == .consumable
        })?.storeProduct
    }
    
    /// Get localized price for consumable
    func getProductPrice() -> String {
        if let product = consumableProduct {
            return product.localizedPriceString
        }
        return String(localized: "purchase.price.unavailable", defaultValue: "Payment Unavailable")
    }
    
    /// Check if purchases are available
    func canPurchase() -> Bool {
        return offerings?.current != nil
    }
    
    // MARK: - Credit Delivery (for consumables)
    
    private func deliverCredits(for transaction: StoreTransaction?, product: StoreProduct) async {
        guard let transaction = transaction else { return }
        
        let transactionID = transaction.transactionIdentifier
        
        // Check for duplicate
        guard !isTransactionProcessed(transactionID) else {
            #if DEBUG
            print("⚠️ [RevenueCat] Transaction already processed: \(transactionID)")
            #endif
            return
        }
        
        do {
            // Create purchase record
            let record = PurchaseRecord(
                productID: product.productIdentifier,
                transactionID: transactionID,
                priceUSD: product.price,
                localizedPrice: product.localizedPriceString,
                currencyCode: product.currencyCode ?? "USD",
                creditAmount: 1,
                purchaseDate: transaction.purchaseDate
            )
            context.insert(record)
            
            // Create credit
            let credit = PurchaseCredit(
                reportArea: PurchaseCredit.universalReportArea,
                transactionID: transactionID,
                purchaseDate: transaction.purchaseDate
            )
            credit.purchaseRecord = record
            context.insert(credit)
            
            try context.save()
            
            #if DEBUG
            print("✅ [RevenueCat] Delivered credit for transaction \(transactionID)")
            #endif
            
        } catch {
            #if DEBUG
            print("❌ [RevenueCat] Failed to deliver credits: \(error)")
            #endif
            
            SentrySDK.capture(error: error) { scope in
                scope.setLevel(.error)
                scope.setContext(value: ["action": "deliverCredits"], key: "revenuecat")
            }
        }
    }
    
    private func isTransactionProcessed(_ transactionID: String) -> Bool {
        let descriptor = FetchDescriptor<PurchaseRecord>(
            predicate: #Predicate { $0.transactionID == transactionID }
        )
        return (try? context.fetchCount(descriptor)) ?? 0 > 0
    }
    
    // MARK: - Error Mapping
    
    private func mapRevenueCatError(_ error: ErrorCode) -> PurchaseError {
        switch error {
        case .purchaseCancelledError:
            return .userCancelled
        case .productNotAvailableForPurchaseError:
            return .productNotFound
        case .networkError:
            return .networkError
        case .receiptAlreadyInUseError:
            return .duplicateTransaction
        default:
            return .storePurchaseFailed(error)
        }
    }
}

// MARK: - RevenueCat Delegate

final class RevenueCatDelegate: NSObject, PurchasesDelegate, @unchecked Sendable {
    static let shared = RevenueCatDelegate()
    
    private override init() {
        super.init()
    }
    
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        #if DEBUG
        print("🔄 [RevenueCat] Customer info updated")
        print("   Active entitlements: \(customerInfo.entitlements.active.keys.joined(separator: ", "))")
        #endif
        
        // Post notification for UI updates
        Task { @MainActor in
            NotificationCenter.default.post(
                name: .revenueCatCustomerInfoUpdated,
                object: customerInfo
            )
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let revenueCatCustomerInfoUpdated = Notification.Name("revenueCatCustomerInfoUpdated")
}
