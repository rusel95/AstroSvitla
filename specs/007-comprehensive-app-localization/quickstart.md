# Quickstart: Comprehensive App Localization

**Feature**: 007-comprehensive-app-localization  
**Date**: 2025-12-03

## Overview

This guide helps developers get started implementing comprehensive localization for AstroSvitla.

---

## Prerequisites

- Xcode 15.0+
- iOS 17.0+ deployment target
- Access to translation services or team
- Familiarity with Swift String Catalogs

---

## Quick Setup Steps

### 1. Create LocaleHelper Utility

Create `AstroSvitla/Shared/Utilities/LocaleHelper.swift`:

```swift
import Foundation

enum LocaleHelper {
    static let supportedLanguageCodes = [
        "en", "uk", "de", "fr", "es", "pt-BR", 
        "it", "ja", "ko", "zh-Hans", "zh-Hant", "ru", "tr"
    ]
    
    static var currentLanguageCode: String {
        let preferred = Locale.preferredLanguages.first ?? "en"
        let components = Locale.Components(identifier: preferred)
        let code = components.languageComponents.languageCode?.identifier ?? "en"
        
        if preferred.hasPrefix("zh-Hans") { return "zh-Hans" }
        if preferred.hasPrefix("zh-Hant") { return "zh-Hant" }
        if preferred.hasPrefix("pt-BR") { return "pt-BR" }
        
        return supportedLanguageCodes.contains(code) ? code : "en"
    }
    
    static var currentLanguageDisplayName: String {
        Locale.current.localizedString(forLanguageCode: currentLanguageCode) ?? "English"
    }
}
```

### 2. Add Language Settings Button

In `SettingsView.swift`, add a new section:

```swift
private var languageSection: some View {
    VStack(alignment: .leading, spacing: 16) {
        SettingsSectionHeader(
            title: String(localized: "settings.section.language"),
            icon: "globe"
        )
        
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            SettingsRow(
                icon: "character.bubble",
                iconColor: .blue,
                title: String(localized: "settings.language.change"),
                subtitle: LocaleHelper.currentLanguageDisplayName
            )
        }
        .buttonStyle(.plain)
    }
    .glassCard(cornerRadius: 20, padding: 18, intensity: .regular)
}
```

### 3. Update ReportPurchase Model

Add language field to `AstroSvitla/Models/SwiftData/ReportPurchase.swift`:

```swift
@Model
final class ReportPurchase {
    // ... existing fields ...
    
    var languageCode: String = "en"
    
    // ... rest of model ...
}
```

### 4. Update Report Generation

In the report generation flow, pass the current language:

```swift
let report = try await openAIService.generateReport(
    // ... existing params ...
    languageCode: LocaleHelper.currentLanguageCode,
    languageDisplayName: LocaleHelper.currentLanguageDisplayName
)

// Save language with report
reportPurchase.languageCode = LocaleHelper.currentLanguageCode
```

### 5. Extract Hardcoded Strings

Replace hardcoded strings with localized versions:

```swift
// Before
.navigationTitle(Text("Налаштування"))

// After  
.navigationTitle(Text("settings.title"))
```

Add keys to `Localizable.xcstrings`:

```json
"settings.title": {
  "localizations": {
    "en": { "stringUnit": { "state": "translated", "value": "Settings" } },
    "uk": { "stringUnit": { "state": "translated", "value": "Налаштування" } }
  }
}
```

---

## Testing Your Changes

### Unit Test for Locale Detection

```swift
import XCTest
@testable import AstroSvitla

final class LocaleHelperTests: XCTestCase {
    func testSupportedLanguagesCount() {
        #expect(LocaleHelper.supportedLanguageCodes.count == 13)
    }
    
    func testEnglishIsSupported() {
        #expect(LocaleHelper.isSupported("en"))
    }
    
    func testUnsupportedFallsToEnglish() {
        // When device has unsupported language, should fall back
        // This test requires mocking Locale.preferredLanguages
    }
}
```

### UI Test for Settings Button

```swift
func testLanguageSettingsButtonExists() {
    let app = XCUIApplication()
    app.launch()
    
    // Navigate to Settings
    app.tabBars.buttons["Settings"].tap()
    
    // Verify language button exists
    XCTAssertTrue(app.buttons["settings.language.change"].exists)
}
```

---

## Common Patterns

### Locale-Aware Date Formatting

```swift
let formatter = DateFormatter()
formatter.locale = Locale.current
formatter.dateStyle = .long
formatter.timeStyle = .short
let dateString = formatter.string(from: date)
```

### Locale-Aware Number Formatting

```swift
let formatter = NumberFormatter()
formatter.locale = Locale.current
formatter.numberStyle = .decimal
let numberString = formatter.string(from: NSNumber(value: 1234.56))
```

### Pluralization

In `Localizable.xcstrings`:

```json
"reports.count": {
  "localizations": {
    "en": {
      "variations": {
        "plural": {
          "one": { "stringUnit": { "value": "%lld report" } },
          "other": { "stringUnit": { "value": "%lld reports" } }
        }
      }
    }
  }
}
```

Usage:

```swift
Text("reports.count \(count)")
```

---

## Translation Workflow

### Export for Translation

1. In Xcode: `Product` → `Export Localizations...`
2. Select target languages
3. Save XLIFF files
4. Send to translators

### Import Translations

1. Receive translated XLIFF files
2. In Xcode: `Product` → `Import Localizations...`
3. Select translated XLIFF file
4. Review and merge

---

## Verification Checklist

Before submitting PR:

- [ ] All hardcoded strings extracted to `Localizable.xcstrings`
- [ ] All 13 languages have translations (state: "translated")
- [ ] Language Settings button opens iOS Settings
- [ ] Report generation uses `LocaleHelper.currentLanguageCode`
- [ ] `ReportPurchase.languageCode` is saved with new reports
- [ ] Unit tests pass
- [ ] UI tests pass
- [ ] Manual testing in at least 3 languages (en, uk, + one other)

---

## Resources

- [Apple: Localizing your app](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
- [String Catalogs (WWDC23)](https://developer.apple.com/videos/play/wwdc2023/10155/)
- [Per-App Language Settings](https://developer.apple.com/documentation/bundleresources/information_property_list/cfbundlelocalizations)
