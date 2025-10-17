//
//  Config.swift
//  AstroSvitla
//
//  Created by Ruslan Popesku on 09.10.2025.
//

import Foundation

enum Config {

    /// Refer to `specs/005-enhance-astrological-report/quickstart.md` for setup guidance and placeholder replacement.

    // MARK: - OpenAI Configuration

    /// Replace with your project-specific OpenAI project identifier before distributing the app.
    static let openAIProjectID = ProcessInfo.processInfo.environment["OPENAI_PROJECT_ID"] ?? "YOUR_OPENAI_PROJECT_ID_HERE"

    /// Replace with your project-specific OpenAI API key before running the app.
    static let openAIAPIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "YOUR_OPENAI_API_KEY_HERE"

    /// OpenAI model to use for report generation
    static let openAIModel = "gpt-4o"

    /// Base URL for OpenAI API requests
    static let openAIBaseURL = "https://api.openai.com/v1"

    /// Identifier of the OpenAI vector store that contains the astrology knowledge base
    static let openAIVectorStoreID = ProcessInfo.processInfo.environment["OPENAI_VECTOR_STORE_ID"] ?? "YOUR_OPENAI_VECTOR_STORE_ID_HERE"

    // MARK: - Astrology API Configuration (api.astrology-api.io)

    /// Base URL for Astrology API requests
    static let astrologyAPIBaseURL = "https://api.astrology-api.io/api/v3"

    /// Bearer token used to authenticate against api.astrology-api.io. Replace the placeholder with a valid key before building.
    static let astrologyAPIKey = ProcessInfo.processInfo.environment["ASTROLOGY_API_KEY"] ?? "YOUR_ASTROLOGY_API_KEY_HERE"

    /// Rate limiting configuration (requests per time window) expected by api.astrology-api.io
    static let astrologyAPIRateLimitRequests = 10
    static let astrologyAPIRateLimitTimeWindow: TimeInterval = 60

    /// Request timeout for Astrology API calls
    static let astrologyAPIRequestTimeout: TimeInterval = 30

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

    /// Shows debug features like knowledge source logs
    /// Should be false in production builds
    static var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    // MARK: - Validation Helpers

    static var isOpenAIConfigured: Bool {
        openAIAPIKey.isEmpty == false &&
        openAIAPIKey != "YOUR_OPENAI_API_KEY_HERE"
    }

    static var isAstrologyAPIConfigured: Bool {
        astrologyAPIKey.isEmpty == false &&
        astrologyAPIKey != "YOUR_ASTROLOGY_API_KEY_HERE"
    }

    static func validate() throws {
        guard isOpenAIConfigured else {
            throw ConfigError.missingAPIKey("OpenAI API key not configured in Config.swift")
        }

        guard isAstrologyAPIConfigured else {
            throw ConfigError.missingAPIKey("Astrology API key not configured in Config.swift")
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
