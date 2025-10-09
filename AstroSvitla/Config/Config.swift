//
//  Config.swift
//  AstroSvitla
//
//  Created by Ruslan Popesku on 09.10.2025.
//

import Foundation

enum Config {

    // MARK: - OpenAI Configuration

    /// Replace with your project-specific OpenAI API key
    static let openAIAPIKey = "YOUR_OPENAI_API_KEY_HERE"

    /// OpenAI model to use for report generation
    static let openAIModel = "gpt-4o"

    /// Base URL for OpenAI API requests
    static let openAIBaseURL = "https://api.openai.com/v1"

    // MARK: - AstrologyAPI (Prokerala) Configuration

    /// AstrologyAPI User ID for Basic Authentication
    /// Get credentials from https://astrologyapi.com (Free tier: 5,000 credits/month)
    static let astrologyAPIUserID = "20b1efa7-2ebc-4b06-b4b4-ef776c0b9aff"

    /// AstrologyAPI Key for Basic Authentication
    static let astrologyAPIKey = "Lujc0u8mKE3lohy8SU10OWrIW5vx7ruR9o1BWTiV"

    /// Base URL for AstrologyAPI endpoints
    static let astrologyAPIBaseURL = "https://json.astrologyapi.com/v1"

    // MARK: - App Configuration

    static let appVersion = "1.0.0"
    static let buildNumber = "1"
    static let bundleIdentifier = "com.astrosvitla.astroinsight"

    // MARK: - StoreKit Product IDs

    enum ProductID {
        static let generalReport = "com.astrosvitla.astroinsight.report.general"
        static let financesReport = "com.astrosvitla.astroinsight.report.finances"
        static let careerReport = "com.astrosvitla.astroinsight.report.career"
        static let relationshipsReport = "com.astrosvitla.astroinsight.report.relationships"
        static let healthReport = "com.astrosvitla.astroinsight.report.health"

        static var all: [String] {
            [
                generalReport,
                financesReport,
                careerReport,
                relationshipsReport,
                healthReport,
            ]
        }
    }

    // MARK: - Feature Flags

    static let debugLoggingEnabled = true
    static let analyticsEnabled = false

    // MARK: - Validation Helpers

    static var isOpenAIConfigured: Bool {
        openAIAPIKey.isEmpty == false &&
        openAIAPIKey != "YOUR_OPENAI_API_KEY_HERE"
    }

    static var isAstrologyAPIConfigured: Bool {
        !astrologyAPIUserID.isEmpty &&
        astrologyAPIUserID != "YOUR_USER_ID_HERE" &&
        !astrologyAPIKey.isEmpty &&
        astrologyAPIKey != "YOUR_API_KEY_HERE"
    }

    static func validate() throws {
        guard isOpenAIConfigured else {
            throw ConfigError.missingAPIKey("OpenAI API key not configured in Config.swift")
        }

        guard isAstrologyAPIConfigured else {
            throw ConfigError.missingAPIKey("AstrologyAPI credentials not configured in Config.swift")
        }
    }
}

enum ConfigError: LocalizedError {
    case missingAPIKey(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let message):
            return message
        }
    }
}
