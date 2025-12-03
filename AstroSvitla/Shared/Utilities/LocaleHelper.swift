import Foundation

/// Centralized helper for locale and language operations
/// Supporting FR-024, FR-025, FR-026: 13 languages at launch
enum LocaleHelper {
    
    // MARK: - Supported Languages
    
    /// Supported language codes matching spec requirements
    /// - English (base), Ukrainian, German, French, Spanish, Portuguese-Brazil
    /// - Italian, Japanese, Korean, Simplified Chinese, Traditional Chinese, Russian, Turkish
    static let supportedLanguageCodes: [String] = [
        "en",       // English (base/fallback)
        "uk",       // Ukrainian
        "de",       // German
        "fr",       // French
        "es",       // Spanish
        "pt-BR",    // Portuguese (Brazil)
        "it",       // Italian
        "ja",       // Japanese
        "ko",       // Korean
        "zh-Hans",  // Simplified Chinese
        "zh-Hant",  // Traditional Chinese
        "ru",       // Russian
        "tr"        // Turkish
    ]
    
    // MARK: - Current Language Detection
    
    /// Current app language code from device settings
    /// Falls back to "en" for unsupported languages
    static var currentLanguageCode: String {
        let preferred = Locale.preferredLanguages.first ?? "en"
        
        // Handle regional variants first (before extracting base code)
        if preferred.hasPrefix("zh-Hans") { return "zh-Hans" }
        if preferred.hasPrefix("zh-Hant") { return "zh-Hant" }
        if preferred.hasPrefix("pt-BR") { return "pt-BR" }
        
        // Extract base language code (e.g., "en-US" -> "en", "uk-UA" -> "uk")
        let components = Locale.Components(identifier: preferred)
        let languageCode = components.languageComponents.languageCode?.identifier ?? "en"
        
        // Return supported code or fallback to English
        return supportedLanguageCodes.contains(languageCode) ? languageCode : "en"
    }
    
    /// Display name for current language in user's locale
    /// Example: "English", "Українська", "Deutsch"
    static var currentLanguageDisplayName: String {
        displayName(for: currentLanguageCode)
    }
    
    // MARK: - Display Name Helpers
    
    /// Display name for a specific language code in user's current locale
    /// - Parameter languageCode: ISO language code (e.g., "en", "uk", "zh-Hans")
    /// - Returns: Localized language name or the code itself as fallback
    static func displayName(for languageCode: String) -> String {
        // Handle regional variants
        let lookupCode: String
        switch languageCode {
        case "zh-Hans":
            lookupCode = "zh-Hans"
        case "zh-Hant":
            lookupCode = "zh-Hant"
        case "pt-BR":
            lookupCode = "pt-BR"
        default:
            lookupCode = languageCode
        }
        
        return Locale.current.localizedString(forLanguageCode: lookupCode) ?? languageCode
    }
    
    // MARK: - Validation
    
    /// Check if a language code is supported by the app
    /// - Parameter languageCode: ISO language code to check
    /// - Returns: true if the language is in the supported list
    static func isSupported(_ languageCode: String) -> Bool {
        supportedLanguageCodes.contains(languageCode)
    }
}
