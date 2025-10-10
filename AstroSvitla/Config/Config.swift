//
//  Config.swift
//  AstroSvitla
//
//  Created by Ruslan Popesku on 09.10.2025.
//

import Foundation

enum Config {

    // MARK: - OpenAI Configuration

    static let openAIProjectID = "proj_0Okcswia9PZrXTqsS4JkfsnN"
    /// Replace with your project-specific OpenAI API key
    static let openAIAPIKey = "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"

    /// OpenAI model to use for report generation
    static let openAIModel = "gpt-4o"

    /// Base URL for OpenAI API requests
    static let openAIBaseURL = "https://api.openai.com/v1"

    // MARK: - Prokerala API Configuration

    /// Prokerala API Token for Authentication
    /// Get credentials from https://api.prokerala.com/
    static let prokeralaAPIToken = "Lujc0u8mKE3lohy8SU10OWrIW5vx7ruR9o1BWTiV"

    /// Base URL for Prokerala API endpoints
    static let prokeralaAPIBaseURL = "https://api.prokerala.com/v2"

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

    static var isProkeralaAPIConfigured: Bool {
        !prokeralaAPIToken.isEmpty &&
        prokeralaAPIToken != "YOUR_API_KEY_HERE"
    }

    static func validate() throws {
        guard isOpenAIConfigured else {
            throw ConfigError.missingAPIKey("OpenAI API key not configured in Config.swift")
        }

        guard isProkeralaAPIConfigured else {
            throw ConfigError.missingAPIKey("Prokerala API token not configured in Config.swift")
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
