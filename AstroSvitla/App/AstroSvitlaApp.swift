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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferences)
                .preferredColorScheme(preferences.selectedColorScheme)
                .environment(\.locale, preferences.selectedLocale)
        }
        .modelContainer(sharedModelContainer)
    }
}
