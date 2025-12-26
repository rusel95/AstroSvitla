//
//  AstroSvitlaApp.swift
//  AstroSvitla
//
//  Created by Ruslan Popesku on 21.09.2025.
//

import SwiftUI
import Sentry
import RevenueCat
import SwiftData

@main
struct AstroSvitlaApp: App {
    
    private let sharedModelContainer: ModelContainer
    @StateObject private var preferences = AppPreferences()
    @StateObject private var repositoryContext: RepositoryContext
    @State private var purchaseService: RevenueCatPurchaseService
    @State private var creditManager: CreditManager
    
    init() {
        // 1. Configure Sentry first (for error tracking during init)
        SentrySDK.start { options in
            options.dsn = "https://2663ea6169f8259819b691c586a1af16@o1271632.ingest.us.sentry.io/4510221414957056"

            // Adds IP for users.
            // For more information, visit: https://docs.sentry.io/platforms/apple/data-management/data-collected/
            options.sendDefaultPii = true

            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 0.5

            // Configure profiling. Visit https://docs.sentry.io/platforms/apple/profiling/ to learn more.
            options.configureProfiling = {
                $0.sessionSampleRate = 0.5 // We recommend adjusting this value in production.
                $0.lifecycle = .trace
            }

            // Uncomment the following lines to add more data to your events
            options.attachScreenshot = true // This adds a screenshot to the error events
            options.attachViewHierarchy = true // This adds the view hierarchy to the error events

            // Enable experimental logging features
            options.experimental.enableLogs = true
        }
        
        // 2. Configure RevenueCat SDK
        RevenueCatConfiguration.configure()
        
        // Optional: Validate configuration
#if DEBUG
        do {
            try Config.validate()
            print("✅ Configuration validated successfully")
        } catch {
            print("⚠️ Configuration warning: \(error.localizedDescription)")
        }
#endif
        
        // 3. Set up ModelContainer
        do {
            sharedModelContainer = try ModelContainer.astroSvitlaShared()
        } catch {
            // Use capture(error:) for better stack traces and error context
            SentrySDK.capture(error: error) { scope in
                scope.setLevel(.fatal)
                scope.setTag(value: "startup", key: "phase")
                scope.setTag(value: "model_container", key: "operation")
                scope.setContext(value: [
                    "message": "Critical: Could not create ModelContainer - app cannot function"
                ], key: "error_context")
            }
            fatalError("Could not create ModelContainer: \(error)")
        }
        
        let repoContext = RepositoryContext(context: sharedModelContainer.mainContext)
        _repositoryContext = StateObject(wrappedValue: repoContext)
        
        // 4. Initialize RevenueCat Purchase Service
        purchaseService = RevenueCatPurchaseService(context: sharedModelContainer.mainContext)
        
        // 5. Initialize CreditManager
        creditManager = CreditManager(context: sharedModelContainer.mainContext)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferences)
                .environmentObject(repositoryContext)
                .environment(purchaseService)
                .environment(creditManager)
                .preferredColorScheme(preferences.selectedColorScheme)
                .task {
                    // Grant free trial credit for new users (first report is free)
                    creditManager.grantTrialCreditIfNeeded()
                    
                    // Load RevenueCat offerings and customer info
                    await purchaseService.load()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
