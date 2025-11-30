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

    /// OpenAI project identifier - loaded from environment or Info.plist
    static let openAIProjectID: String = {
        if let envValue = ProcessInfo.processInfo.environment["OPENAI_PROJECT_ID"], !envValue.isEmpty {
            return envValue
        }
        if let plistValue = Bundle.main.infoDictionary?["OPENAI_PROJECT_ID"] as? String, !plistValue.isEmpty {
            return plistValue
        }
        // Fallback for local development only - replace with your key
        return "proj_0Okcswia9PZrXTqsS4JkfsnN"
    }()

    /// OpenAI API key - loaded from environment or Info.plist
    /// ⚠️ NEVER commit real API keys to version control!
    static let openAIAPIKey: String = {
        if let envValue = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envValue.isEmpty {
            return envValue
        }
        if let plistValue = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String, !plistValue.isEmpty {
            return plistValue
        }
        // Fallback for local development only - replace with your key
        return "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"
    }()

    /// OpenAI model to use for report generation
    static let openAIModel = "gpt-4o"

    /// Base URL for OpenAI API requests
    static let openAIBaseURL = "https://api.openai.com/v1"

    /// Identifier of the OpenAI vector store that contains the astrology knowledge base
    static let openAIVectorStoreID: String = {
        if let envValue = ProcessInfo.processInfo.environment["OPENAI_VECTOR_STORE_ID"], !envValue.isEmpty {
            return envValue
        }
        if let plistValue = Bundle.main.infoDictionary?["OPENAI_VECTOR_STORE_ID"] as? String, !plistValue.isEmpty {
            return plistValue
        }
        return "vs_68c18fef3df48191810b0d2584b3e507"
    }()

    // MARK: - Astrology API Configuration (api.astrology-api.io)

    /// Base URL for Astrology API requests
    static let astrologyAPIBaseURL = "https://api.astrology-api.io/api/v3"

    /// Bearer token used to authenticate against api.astrology-api.io. Replace the placeholder with a valid key before building.
//    static let astrologyAPIKey = ProcessInfo.processInfo.environment["ASTROLOGY_API_KEY"] ?? "YOUR_ASTROLOGY_API_KEY_HERE"

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

    static func validate() throws {
        guard isOpenAIConfigured else {
            throw ConfigError.missingAPIKey("OpenAI API key not configured in Config.swift")
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
