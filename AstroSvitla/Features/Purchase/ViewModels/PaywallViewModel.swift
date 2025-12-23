//  PaywallViewModel.swift
//  AstroSvitla
//
//  Created on 2025-12-23
//  Feature: 008-implement-in-app

import Foundation
import StoreKit
import Observation

@MainActor
@Observable
final class PaywallViewModel {
    
    // MARK: - Published Properties
    
    var product: Product?
    var isPurchasing = false
    var error: PurchaseError?
    var purchaseCompleted = false
    var showConfirmation = false
    
    // MARK: - Localized Strings
    
    var confirmationTitle: String {
        String(localized: "purchase.confirmation.title")
    }
    
    var confirmationMessage: String {
        String(localized: "purchase.confirmation.message")
    }
    
    var confirmationButton: String {
        String(localized: "purchase.confirmation.button")
    }
    
    // MARK: - Dependencies
    
    private let purchaseService: PurchaseService
    let reportArea: String
    var onPurchaseComplete: ((String) -> Void)?
    
    // MARK: - Initialization
    
    init(purchaseService: PurchaseService, reportArea: String) {
        self.purchaseService = purchaseService
        self.reportArea = reportArea
    }
    
    // MARK: - Actions
    
    func loadProduct() async {
        do {
            try await purchaseService.loadProducts()
            self.product = purchaseService.products.first
        } catch {
            self.error = error as? PurchaseError ?? .productLoadFailed(error)
        }
    }
    
    func purchase() async {
        guard let product = product else {
            error = .productNotFound
            return
        }
        
        isPurchasing = true
        error = nil
        
        do {
            _ = try await purchaseService.purchase(product)
            purchaseCompleted = true
            onPurchaseComplete?(reportArea)
        } catch PurchaseError.userCancelled {
            // User cancelled - no error to show
            isPurchasing = false
        } catch let purchaseError as PurchaseError {
            error = purchaseError
            isPurchasing = false
        } catch {
            self.error = .storePurchaseFailed(error)
            isPurchasing = false
        }
    }
    
    func restorePurchases() async {
        isPurchasing = true
        error = nil
        
        do {
            try await purchaseService.restorePurchases()
            isPurchasing = false
        } catch {
            self.error = .storePurchaseFailed(error)
            isPurchasing = false
        }
    }
}
