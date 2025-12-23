# Research: Comprehensive App Localization

**Feature**: 007-comprehensive-app-localization  
**Date**: 2025-12-03

## Overview

Research findings for implementing comprehensive localization across AstroSvitla iOS app.

---

## 1. iOS Per-App Language Settings

### Decision
Use `UIApplication.openSettingsURLString` to navigate users to iOS app-specific settings where they can change the app language.

### Rationale
- iOS 13+ supports per-app language selection natively
- No custom UI needed; uses system-provided interface
- Language changes apply immediately when user returns to app
- Aligns with Apple Human Interface Guidelines

### Implementation Pattern
```swift
// Open app-specific settings
if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
    UIApplication.shared.open(settingsURL)
}
```

### Alternatives Considered
| Alternative | Rejected Because |
|-------------|------------------|
| Custom in-app picker | Explicitly excluded by requirements; duplicates system functionality |
| Device-level settings only | Less discoverable; user must navigate manually |

---

## 2. String Localization Strategy

### Decision
Use Swift's `String(localized:)` API with `Localizable.xcstrings` String Catalog format.

### Rationale
- Native Xcode 15+ String Catalogs provide better tooling than legacy `.strings` files
- Automatic pluralization and device variation support
- Built-in translation state tracking (new, translated, needs review)
- Xcode can auto-extract strings from SwiftUI views

### Current State Analysis
- `Localizable.xcstrings` exists with ~6000 lines
- Partial translations exist for: en, uk, de, fr, es, pt-BR, it, ja, ko, zh-Hans, zh-Hant, ru, tr
- Many strings still have `"state": "new"` (untranslated)
- Some hardcoded Ukrainian strings in `SettingsView.swift` and other files

### Pattern
```swift
// Preferred: Use String(localized:) for programmatic strings
let title = String(localized: "settings.language.title")

// SwiftUI views: Use LocalizedStringKey directly
Text("settings.language.title")
```

### Alternatives Considered
| Alternative | Rejected Because |
|-------------|------------------|
| NSLocalizedString | Legacy API; String(localized:) is preferred in Swift 5.5+ |
| Third-party libs (e.g., SwiftGen) | Adds dependency; native tooling sufficient |
| Separate .strings per language | String Catalogs consolidate all languages in one file |

---

## 3. Detecting Current Language

### Decision
Create `LocaleHelper` utility to centralize locale detection using `Locale.current.language.languageCode`.

### Rationale
- Single source of truth for language detection
- Handles edge cases (regional variants, fallbacks)
- Testable in isolation

### Implementation Pattern
```swift
enum LocaleHelper {
    /// Returns the current app language code (e.g., "en", "uk", "de")
    static var currentLanguageCode: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }
    
    /// Returns display name for current language
    static var currentLanguageDisplayName: String {
        Locale.current.localizedString(forLanguageCode: currentLanguageCode) ?? "English"
    }
    
    /// Supported language codes
    static let supportedLanguages = ["en", "uk", "de", "fr", "es", "pt-BR", "it", "ja", "ko", "zh-Hans", "zh-Hant", "ru", "tr"]
}
```

---

## 4. Report Generation Language

### Decision
Pass device language to existing `languageCode` / `languageDisplayName` parameters in `OpenAIService`. Note: AstrologyAPI does not currently support a language parameter for chart rendering (chart labels remain in English).

### Rationale
- OpenAI service already accepts language parameters (confirmed in codebase)
- AI prompt builder already includes language instruction
- No architectural changes needed for report text generation

### Current Implementation (AIPromptBuilder.swift)
```swift
Always answer in language: \(languageDisplayName) (language code: \(languageCode)).
```

### Changes Needed
- Update OpenAI service call sites to pass `LocaleHelper.currentLanguageCode` instead of hardcoded values
- Store language code in `ReportPurchase` SwiftData model for reference
- Note: AstrologyAPI natal chart SVG labels remain English-only (API limitation)

---

## 5. Report Language Persistence

### Decision
Add `languageCode: String` field to `ReportPurchase` SwiftData model.

### Rationale
- FR-021 requires storing the language used when generating each report
- Enables displaying original language indicator on saved reports
- Supports future "regenerate in different language" feature (FR-023)

### Migration Strategy
- Add field with default value `"en"` for existing reports
- SwiftData handles lightweight migration automatically

---

## 6. Hardcoded String Audit

### Decision
Audit all `.swift` files for hardcoded user-visible strings and extract to `Localizable.xcstrings`.

### Identified Hardcoded Strings (Sample from SettingsView.swift)
| String | Recommended Key |
|--------|----------------|
| "Налаштування" | `settings.title` |
| "Dev Mode увімкнено" | `settings.devmode.enabled` |
| "Dev Mode вимкнено" | `settings.devmode.disabled` |
| "Профілі" | `settings.section.profiles` |
| "Керувати профілями" | `settings.profiles.manage` |
| "Оформлення" | `settings.section.appearance` |
| "Тема додатку" | `settings.theme.title` |
| "Система" / "Світле" / "Темне" | `settings.theme.system/light/dark` |
| "Про додаток" | `settings.section.about` |
| "Версія" | `settings.version` |
| "Зроблено з любов'ю" | `settings.made_with_love` |

### Audit Process
1. Run `grep -r "Text(\"" --include="*.swift" AstroSvitla/` to find potential hardcoded strings
2. Check each for user visibility
3. Add to `Localizable.xcstrings` with appropriate key naming convention

---

## 7. Instagram Carousel Localization

### Decision
Use `String(localized:)` for all text rendered on carousel images.

### Current State
- `InstagramShareViewModel.swift` generates carousel slides
- Text overlays are rendered programmatically
- Some localization keys already exist (e.g., `carousel_title_cover`, `carousel_title_analysis`)

### Changes Needed
- Ensure all slide text uses localized strings
- Verify font rendering for CJK characters (Japanese, Korean, Chinese)
- Test text length variations across languages

---

## 8. PDF Export Localization

### Decision
Localize all PDF template strings using the same `Localizable.xcstrings` approach.

### Affected Areas
- PDF header/footer text
- Section titles
- Metadata labels (Date, Time, Location)
- "Generated on" timestamp format

### Date/Number Formatting
```swift
// Use locale-aware formatters
let dateFormatter = DateFormatter()
dateFormatter.locale = Locale.current
dateFormatter.dateStyle = .long

let numberFormatter = NumberFormatter()
numberFormatter.locale = Locale.current
numberFormatter.numberStyle = .decimal
```

---

## 9. Translation Workflow

### Decision
Use Xcode's "Export for Localization" feature to generate XLIFF files for professional translators.

### Workflow
1. `Product > Export Localizations...` generates XLIFF per language
2. Send XLIFF files to translation service/team
3. Receive translated XLIFF files
4. `Product > Import Localizations...` merges translations back

### Quality Assurance
- Native speaker review for astrological terminology
- Use established astrological literature as reference (per clarification)
- Screenshot testing for text truncation/overflow

---

## 10. Testing Strategy

### Decision
Implement three levels of localization testing.

### Test Categories

**Unit Tests (LocalizationCoverageTests.swift)**
- Verify all keys in `Localizable.xcstrings` have translations for all 13 languages
- Check for missing translations (state != "translated")
- Validate placeholder consistency across languages

**Integration Tests**
- Test `LocaleHelper` returns correct language codes
- Verify Settings button opens correct URL
- Test report generation includes language parameter

**UI Tests**
- Screenshot tests for each language (sample screens)
- Test text truncation on constrained UI elements
- Verify RTL layout not broken (even though RTL languages out of scope)

---

## Summary of Decisions

| Topic | Decision |
|-------|----------|
| Language selection | iOS native via Settings button |
| String format | String Catalogs (Localizable.xcstrings) |
| Locale detection | Centralized LocaleHelper utility |
| Report generation | Pass device language to existing APIs |
| Persistence | Add languageCode to ReportPurchase model |
| Hardcoded strings | Extract all to Localizable.xcstrings |
| Translation workflow | XLIFF export/import via Xcode |
| Testing | Unit + Integration + UI tests |
