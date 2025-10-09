//
//  AstroSvitlaApp.swift
//  AstroSvitla
//
//  Created by Ruslan Popesku on 21.09.2025.
//

import SwiftUI
import SwiftData
import SwissEphemeris

@main
struct AstroSvitlaApp: App {

    private let sharedModelContainer: ModelContainer
    @StateObject private var preferences = AppPreferences()
    @StateObject private var repositoryContext: RepositoryContext

    init() {
        // CRITICAL: Initialize SwissEphemeris before any astronomical calculations
        // This sets the path to ephemeris data files (bundled with the library)
        JPLFileManager.setEphemerisPath()

        // Optional: Validate configuration
        #if DEBUG
        do {
            try Config.validate()
            print("✅ Configuration validated successfully")
        } catch {
            print("⚠️ Configuration warning: \(error.localizedDescription)")
        }
        #endif

        do {
            sharedModelContainer = try ModelContainer.astroSvitlaShared()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        let repoContext = RepositoryContext(context: sharedModelContainer.mainContext)
        repoContext.loadActiveProfile()
        _repositoryContext = StateObject(wrappedValue: repoContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferences)
                .environmentObject(repositoryContext)
                .preferredColorScheme(preferences.selectedColorScheme)
                .environment(\.locale, preferences.selectedLocale)
                .task {
                    // Ensure active profile is loaded when app starts
                    repositoryContext.loadActiveProfile()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
