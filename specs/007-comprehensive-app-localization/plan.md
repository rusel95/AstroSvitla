# Implementation Plan: Comprehensive App Localization

**Branch**: `007-comprehensive-app-localization` | **Date**: 2025-12-03 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-comprehensive-app-localization/spec.md`

## Summary

Implement complete localization coverage across the AstroSvitla iOS app for 13 languages (en, uk, de, fr, es, pt-BR, it, ja, ko, zh-Hans, zh-Hant, ru, tr). This includes:
- Extracting and translating all hardcoded UI strings to `Localizable.xcstrings`
- Adding a Settings button to open iOS app-specific language settings
- Ensuring report generation passes the device language to AI/API services
- Localizing Instagram carousel templates and PDF exports
- Adding language metadata to saved reports

## Technical Context

**Language/Version**: Swift 5.9  
**Primary Dependencies**: SwiftUI, SwiftData, Foundation (Locale, Bundle)  
**Storage**: SwiftData (existing), `Localizable.xcstrings` (String Catalogs)  
**Testing**: XCTest (unit + UI tests)  
**Target Platform**: iOS 17+  
**Project Type**: Mobile iOS app (single project)  
**Performance Goals**: Language switch reflects immediately upon return from iOS Settings  
**Constraints**: No custom in-app language picker; must use iOS native per-app settings  
**Scale/Scope**: ~6000 lines in Localizable.xcstrings, 13 target languages, ~50 screens

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Spec-Driven Delivery | ✅ PASS | Spec completed via `/speckit.specify`, clarified via `/speckit.clarify` |
| II. SwiftUI Modular Architecture | ✅ PASS | Localization uses standard iOS patterns; no new modules needed |
| III. Test-First Reliability | ✅ PASS | Will add tests for locale detection, string coverage, Settings navigation |
| IV. Secure Configuration | ✅ PASS | No secrets involved in localization |
| V. Release Quality | ✅ PASS | All 13 languages must be 100% complete before release (per clarification) |

**Assets & Localization (Operational Standard)**: This feature directly addresses the constitution requirement to "ship English and Ukrainian strings together so each release remains bilingual" - extending it to 13 languages.

## Project Structure

### Documentation (this feature)

```
specs/007-comprehensive-app-localization/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```
AstroSvitla/
├── Resources/
│   └── Localizable.xcstrings    # Primary localization file (extend)
├── Features/
│   └── Settings/
│       └── SettingsView.swift   # Add language settings button
├── Services/
│   └── Transformers/            # Locale-aware formatters
├── Shared/
│   └── Utilities/
│       └── LocaleHelper.swift   # New: centralized locale utilities
└── Models/
    └── SwiftData/
        └── ReportPurchase.swift # Add languageCode field

AstroSvitlaTests/
└── Features/
    └── Settings/
        └── SettingsLanguageTests.swift  # New: test settings navigation
```

**Structure Decision**: Follows existing iOS MVVM structure. Localization extends `Resources/Localizable.xcstrings`. New `LocaleHelper` utility centralizes device language detection.

## Complexity Tracking

*No Constitution violations. Feature aligns with existing patterns.*

| Area | Complexity | Mitigation |
|------|------------|------------|
| 13 languages at launch | High translation effort | Use professional translation service; prioritize by market size |
| Hardcoded strings audit | Medium | Use Xcode "Export for Localization" + grep for unloc'd strings |
| Report language persistence | Low | Add single field to existing SwiftData model |
