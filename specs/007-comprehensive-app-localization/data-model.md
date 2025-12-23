# Data Model: Comprehensive App Localization

**Feature**: 007-comprehensive-app-localization  
**Date**: 2025-12-03

## Overview

Data model changes required for comprehensive localization. This feature primarily extends the existing localization infrastructure with minimal data model changes.

---

## Entity Changes

### 1. ReportPurchase (Existing Model - Modification)

**Location**: `AstroSvitla/Models/SwiftData/ReportPurchase.swift`

**Change**: Add `languageCode` field to track the language used when generating the report.

```swift
@Model
final class ReportPurchase {
    // Existing fields...
    
    /// Language code used when this report was generated (e.g., "en", "uk", "de")
    /// Used for FR-021: Store language used when generating each report
    var languageCode: String = "en"
    
    // Existing relationships...
}
```

**Migration**: SwiftData performs lightweight migration automatically. Default value `"en"` applies to existing records.

---

### 2. LocaleHelper (New Utility - No Persistence)

**Location**: `AstroSvitla/Shared/Utilities/LocaleHelper.swift`

**Purpose**: Centralized locale detection and supported language management.

```swift
import Foundation

/// Centralized helper for locale and language operations
enum LocaleHelper {
    
    /// Supported language codes matching FR-024, FR-025, FR-026
    static let supportedLanguageCodes: [String] = [
        "en",       // English (base)
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
    
    /// Current app language code from device settings
    static var currentLanguageCode: String {
        let preferred = Locale.preferredLanguages.first ?? "en"
        // Extract base language code (e.g., "en-US" -> "en")
        let components = Locale.Components(identifier: preferred)
        let languageCode = components.languageComponents.languageCode?.identifier ?? "en"
        
        // Handle regional variants
        if preferred.hasPrefix("zh-Hans") { return "zh-Hans" }
        if preferred.hasPrefix("zh-Hant") { return "zh-Hant" }
        if preferred.hasPrefix("pt-BR") { return "pt-BR" }
        
        return supportedLanguageCodes.contains(languageCode) ? languageCode : "en"
    }
    
    /// Display name for current language in current locale
    static var currentLanguageDisplayName: String {
        Locale.current.localizedString(forLanguageCode: currentLanguageCode) ?? "English"
    }
    
    /// Display name for a specific language code
    static func displayName(for languageCode: String) -> String {
        Locale.current.localizedString(forLanguageCode: languageCode) ?? languageCode
    }
    
    /// Check if a language code is supported
    static func isSupported(_ languageCode: String) -> Bool {
        supportedLanguageCodes.contains(languageCode)
    }
}
```

---

## Localization String Categories

### String Key Naming Convention

All localization keys follow a hierarchical naming pattern:

```
{feature}.{section}.{element}
```

**Examples**:

| Key | English Value | Description |
|-----|---------------|-------------|
| `settings.title` | Settings | Navigation title |
| `settings.section.profiles` | Profiles | Section header |
| `settings.profiles.manage` | Manage Profiles | Button title |
| `settings.language.title` | Language | Settings row title |
| `settings.language.change` | Change Language | Button to open iOS settings |
| `settings.theme.system` | System | Theme option |
| `settings.theme.light` | Light | Theme option |
| `settings.theme.dark` | Dark | Theme option |
| `settings.devmode.enabled` | Dev Mode enabled | Toast message |
| `settings.devmode.disabled` | Dev Mode disabled | Toast message |
| `settings.about.title` | About | Section header |
| `settings.about.version` | Version | Label |
| `settings.about.made_with_love` | Made with love | Footer text |

### Categories

| Category | Key Prefix | Count (Est.) |
|----------|------------|--------------|
| Settings | `settings.*` | ~25 |
| Onboarding | `onboarding.*` | ~40 |
| Chart Input | `birth.*`, `location.*` | ~30 |
| Area Selection | `area.*` | ~20 |
| Report Generation | `generating.*`, `report.*` | ~35 |
| Chart Visualization | `chart.*`, `chart_details.*` | ~50 |
| Sharing | `share.*`, `carousel.*` | ~20 |
| Common Actions | `action.*` | ~15 |
| Errors | `error.*`, `alert.*` | ~25 |
| Profile Management | `profile.*` | ~30 |

**Total Estimated New/Updated Keys**: ~290

---

## Relationships

```text
┌─────────────────┐         ┌─────────────────┐
│  ReportPurchase │────────▶│  LocaleHelper   │
│                 │  uses   │   (utility)     │
│  + languageCode │         │                 │
└─────────────────┘         │  + currentCode  │
                            │  + displayName  │
                            └─────────────────┘
                                    │
                                    │ reads
                                    ▼
                            ┌─────────────────┐
                            │  Locale.current │
                            │  (iOS System)   │
                            └─────────────────┘
```

---

## Validation Rules

### Language Code Validation

| Field | Rule | Error |
|-------|------|-------|
| `ReportPurchase.languageCode` | Must be in `LocaleHelper.supportedLanguageCodes` | Falls back to "en" |
| Settings display | Language must resolve to valid display name | Shows language code if no display name |

---

## State Transitions

### Report Language Assignment

```text
┌──────────────────┐
│ User initiates   │
│ report generation│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Get current      │
│ language code    │──▶ LocaleHelper.currentLanguageCode
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Pass to          │
│ OpenAIService    │──▶ languageCode, languageDisplayName params
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Store in         │
│ ReportPurchase   │──▶ reportPurchase.languageCode = code
└──────────────────┘
```

---

## Notes

- No database schema changes required beyond adding one String field
- SwiftData handles migration automatically with default value
- Most localization is in `Localizable.xcstrings`, not data models
- `LocaleHelper` is stateless utility, not persisted
