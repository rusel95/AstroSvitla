import Testing
@testable import AstroSvitla

/// Unit tests for LocaleHelper utility
/// Validates FR-024, FR-025, FR-026: 13 supported languages
struct LocaleHelperTests {
    
    // MARK: - Supported Languages Tests
    
    @Test("Supported languages count is exactly 13")
    func supportedLanguagesCount() {
        #expect(LocaleHelper.supportedLanguageCodes.count == 13)
    }
    
    @Test("English is supported as base language")
    func englishIsSupported() {
        #expect(LocaleHelper.isSupported("en"))
    }
    
    @Test("Ukrainian is supported")
    func ukrainianIsSupported() {
        #expect(LocaleHelper.isSupported("uk"))
    }
    
    @Test("All required languages are supported")
    func allRequiredLanguagesSupported() {
        let requiredLanguages = [
            "en", "uk", "de", "fr", "es", "pt-BR",
            "it", "ja", "ko", "zh-Hans", "zh-Hant", "ru", "tr"
        ]
        
        for language in requiredLanguages {
            #expect(LocaleHelper.isSupported(language), "Expected \(language) to be supported")
        }
    }
    
    // MARK: - Unsupported Languages Tests
    
    @Test("Unsupported language returns false from isSupported")
    func unsupportedLanguageNotSupported() {
        #expect(!LocaleHelper.isSupported("ar"))  // Arabic
        #expect(!LocaleHelper.isSupported("he"))  // Hebrew
        #expect(!LocaleHelper.isSupported("pl"))  // Polish
        #expect(!LocaleHelper.isSupported("xyz")) // Invalid
    }
    
    // MARK: - Display Name Tests
    
    @Test("Current language display name is not empty")
    func currentLanguageDisplayNameNotEmpty() {
        let displayName = LocaleHelper.currentLanguageDisplayName
        #expect(!displayName.isEmpty)
    }
    
    @Test("Display name for English returns valid string")
    func displayNameForEnglish() {
        let displayName = LocaleHelper.displayName(for: "en")
        #expect(!displayName.isEmpty)
        // In most locales, "en" should resolve to a display name like "English"
        // Only verify it's not empty and contains alphabetic characters
        #expect(displayName.rangeOfCharacter(from: .letters) != nil)
    }
    
    @Test("Display name for Ukrainian returns valid string")
    func displayNameForUkrainian() {
        let displayName = LocaleHelper.displayName(for: "uk")
        #expect(!displayName.isEmpty)
    }
    
    @Test("Display name for regional variants returns valid string")
    func displayNameForRegionalVariants() {
        #expect(!LocaleHelper.displayName(for: "zh-Hans").isEmpty)
        #expect(!LocaleHelper.displayName(for: "zh-Hant").isEmpty)
        #expect(!LocaleHelper.displayName(for: "pt-BR").isEmpty)
    }
    
    // MARK: - Current Language Code Tests
    
    @Test("Current language code is not empty")
    func currentLanguageCodeNotEmpty() {
        let code = LocaleHelper.currentLanguageCode
        #expect(!code.isEmpty)
    }
    
    @Test("Current language code is in supported list")
    func currentLanguageCodeIsSupported() {
        let code = LocaleHelper.currentLanguageCode
        #expect(LocaleHelper.isSupported(code))
    }
}
