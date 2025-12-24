//  ProductIdentifier.swift
//  AstroSvitla
//
//  Created on 2025-12-23
//  Feature: 008-implement-in-app
//
//  Enum for StoreKit product identifiers

import Foundation
import StoreKit

enum PurchaseProduct: String, CaseIterable {
    case singleCredit = "com.zorya.report_generation"
    
    var type: Product.ProductType {
        return .consumable
    }
    
    var creditAmount: Int {
        switch self {
        case .singleCredit:
            return 1
        }
    }
    
    var displayName: String {
        switch self {
        case .singleCredit:
            return String(localized: "purchase.product.single_credit.name", defaultValue: "1 Report Credit")
        }
    }
    
    var description: String {
        switch self {
        case .singleCredit:
            return String(localized: "purchase.product.single_credit.description", defaultValue: "Purchase 1 credit to generate an AI-powered astrology report")
        }
    }
}
