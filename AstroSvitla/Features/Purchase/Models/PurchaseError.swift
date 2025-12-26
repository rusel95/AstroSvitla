//  PurchaseError.swift
//  AstroSvitla
//
//  Created on 2025-12-23
//  Feature: 008-implement-in-app
//
//  Error types for purchase flow with localized messages

import Foundation
import StoreKit

enum PurchaseError: LocalizedError {
    case networkError
    case userCancelled
    case failedVerification(VerificationResult<Transaction>.VerificationError)
    case insufficientCredits
    case productNotFound
    case productLoadFailed(Error)
    case storePurchaseFailed(Error)
    case duplicateTransaction
    case saveFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return String(localized: "purchase.error.network", defaultValue: "No internet connection. Please check your connection and try again.")
        case .userCancelled:
            return nil // No error message for user cancellation
        case .failedVerification:
            return String(localized: "purchase.error.verification", defaultValue: "Purchase verification failed. Please try again or contact support.")
        case .insufficientCredits:
            return String(localized: "purchase.error.insufficient", defaultValue: "You don't have enough credits. Please purchase more to continue.")
        case .productNotFound:
            return String(localized: "purchase.error.product_not_found", defaultValue: "Product not available. Please try again later.")
        case .productLoadFailed:
            return String(localized: "purchase.error.load_failed", defaultValue: "Failed to load products. Please try again.")
        case .storePurchaseFailed:
            return String(localized: "purchase.error.purchase_failed", defaultValue: "Purchase failed. Please try again.")
        case .duplicateTransaction:
            return String(localized: "purchase.error.duplicate", defaultValue: "This purchase has already been processed.")
        case .saveFailed:
            return String(localized: "purchase.error.save_failed", defaultValue: "Failed to save purchase. Please contact support.")
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return String(localized: "purchase.error.network.recovery", defaultValue: "Check your internet connection and try again.")
        case .userCancelled:
            return nil
        case .failedVerification:
            return String(localized: "purchase.error.verification.recovery", defaultValue: "Please try purchasing again. If the problem persists, contact support.")
        case .insufficientCredits:
            return String(localized: "purchase.error.insufficient.recovery", defaultValue: "Purchase a credit to continue.")
        case .productNotFound:
            return String(localized: "purchase.error.product_not_found.recovery", defaultValue: "Try again later or contact support if the issue persists.")
        case .productLoadFailed, .storePurchaseFailed, .saveFailed:
            return String(localized: "purchase.error.generic.recovery", defaultValue: "Try again or contact support if the problem continues.")
        case .duplicateTransaction:
            return String(localized: "purchase.error.duplicate.recovery", defaultValue: "Your credit should already be available. Check your credit balance.")
        }
    }
}
