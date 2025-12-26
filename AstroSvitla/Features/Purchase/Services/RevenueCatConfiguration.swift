//  RevenueCatConfiguration.swift
//  AstroSvitla
//
//  Created for RevenueCat integration
//  Handles SDK configuration and entitlements

import Foundation
import RevenueCat

/// RevenueCat configuration for Zorya app
enum RevenueCatConfiguration {
    
    // MARK: - API Key (from gitignored Config.swift)
    
    /// RevenueCat API key - reads from Config.swift
    private static var apiKey: String {
        Config.revenueCatAPIKey
    }
    
    // MARK: - Entitlements
    
    /// Entitlement identifier for premium features (if you add subscriptions later)
    /// Configure this in RevenueCat Dashboard: Project → Entitlements
    static let proEntitlementID = "zorya_pro"
    
    // MARK: - Configuration
    
    /// Configure RevenueCat SDK
    /// Call this once at app startup (in App init)
    @MainActor
    static func configure() {
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .warn
        #endif
        
        Purchases.configure(withAPIKey: apiKey)
        
        #if DEBUG
        print("✅ [RevenueCat] SDK configured")
        #endif
    }
    
    /// Configure RevenueCat with a specific user ID
    /// Use this if you have your own user authentication system
    @MainActor
    static func configure(withUserID userID: String) {
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .warn
        #endif
        
        Purchases.configure(
            with: Configuration.Builder(withAPIKey: apiKey)
                .with(appUserID: userID)
                .build()
        )
        
        #if DEBUG
        print("✅ [RevenueCat] SDK configured for user: \(userID)")
        #endif
    }
}


