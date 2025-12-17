import Testing
import UIKit
@testable import AstroSvitla

/// Unit tests for Settings language functionality
/// Tests settings navigation to iOS language settings
struct SettingsLanguageTests {
    
    // MARK: - Language Display Tests
    
    @Test("Current language display name is not empty")
    func currentLanguageDisplayNameNotEmpty() {
        let displayName = LocaleHelper.currentLanguageDisplayName
        #expect(!displayName.isEmpty)
    }
    
    @Test("Current language code is in supported list")
    func currentLanguageCodeIsSupported() {
        let code = LocaleHelper.currentLanguageCode
        #expect(LocaleHelper.isSupported(code))
    }
    
    @Test("Settings URL string is valid")
    func settingsURLStringIsValid() {
        let urlString = UIKit.UIApplication.openSettingsURLString
        #expect(!urlString.isEmpty)
        let url = URL(string: urlString)
        #expect(url != nil)
    }
}
