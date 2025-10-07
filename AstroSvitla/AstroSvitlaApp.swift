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
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
