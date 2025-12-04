# Tasks: Comprehensive App Localization

**Feature**: 007-comprehensive-app-localization  
**Generated**: 2025-12-03  
**Total Tasks**: 32  
**Estimated Effort**: Medium-High (translation effort is primary driver)

---

## Overview

Tasks organized by user story for implementing comprehensive localization across AstroSvitla. Each story phase is independently testable.

### User Stories (Priority Order)

| Story | Priority | Description | Tasks |
|-------|----------|-------------|-------|
| Setup | - | Infrastructure & utilities | 4 |
| US1 | P1 | UI displays in device language | 8 |
| US2 | P1 | Settings language button | 4 |
| US3 | P2 | Reports in device language | 6 |
| US4 | P2 | Sharing/export localized | 5 |
| US5 | P3 | Onboarding localized | 3 |
| Polish | - | Final verification | 2 |

---

## Phase 1: Setup & Infrastructure

**Goal**: Create foundational utilities and update data model needed by all user stories.

### Tasks

- [x] **T001** [Setup] Create LocaleHelper utility
- **File**: `AstroSvitla/Shared/Utilities/LocaleHelper.swift`
- **Action**: Create new file with `LocaleHelper` enum
- **Details**:
  - Add `supportedLanguageCodes` array (13 languages)
  - Add `currentLanguageCode` computed property
  - Add `currentLanguageDisplayName` computed property  
  - Add `displayName(for:)` and `isSupported(_:)` methods
  - Handle regional variants (zh-Hans, zh-Hant, pt-BR)
- **Acceptance**: `LocaleHelper.currentLanguageCode` returns valid code

- [x] **T002** [Setup] Add languageCode to ReportPurchase model
- **File**: `AstroSvitla/Models/SwiftData/ReportPurchase.swift`
- **Action**: Add new field to existing model
- **Details**:
  - Add `var languageCode: String = "en"` property
  - Add documentation comment referencing FR-021
- **Acceptance**: Model compiles, SwiftData migration works automatically

- [x] **T003** [Setup] [P] Create LocaleHelperTests
- **File**: `AstroSvitlaTests/Shared/Utilities/LocaleHelperTests.swift`
- **Action**: Create unit tests for LocaleHelper
- **Details**:
  - Test `supportedLanguageCodes` contains 13 items
  - Test `isSupported` returns true for valid codes
  - Test `isSupported` returns false for unsupported codes
  - Test English fallback for unsupported languages
- **Acceptance**: All tests pass

- [x] **T004** [Setup] [P] Verify Info.plist localizations
- **File**: `AstroSvitla/Info.plist`
- **Action**: Verify CFBundleLocalizations includes all 13 languages
- **Details**:
  - Check `CFBundleLocalizations` array contains: en, uk, de, fr, es, pt-BR, it, ja, ko, zh-Hans, zh-Hant, ru, tr
  - Add missing language codes if needed
- **Acceptance**: iOS recognizes app supports all 13 languages

**⏸️ CHECKPOINT**: LocaleHelper functional, model updated, tests pass

---

## Phase 2: US1 - UI Displays in Device Language (P1)

**Goal**: All static UI text displays in user's iOS device language.
**Test Criteria**: Launch app with device set to Ukrainian → all visible text is Ukrainian.

### Tasks

### ✅ T005 [US1] Audit and extract Settings screen strings
- **Status**: COMPLETE
- **File**: `AstroSvitla/Features/Settings/SettingsView.swift`
- **Action**: Replace hardcoded Ukrainian strings with localized keys
- **Details**:
  - Replace `"Налаштування"` → `String(localized: "settings.title")`
  - Replace `"Профілі"` → `String(localized: "settings.section.profiles")`
  - Replace `"Керувати профілями"` → `String(localized: "settings.profiles.manage")`
  - Replace `"Оформлення"` → `String(localized: "settings.section.appearance")`
  - Replace `"Тема додатку"` → `String(localized: "settings.theme.title")`
  - Replace `"Система"/"Світле"/"Темне"` → localized keys
  - Replace `"Про додаток"` → `String(localized: "settings.section.about")`
  - Replace `"Версія"` → `String(localized: "settings.about.version")`
  - Replace `"Зроблено з любов'ю"` → `String(localized: "settings.about.made_with_love")`
  - Replace Dev Mode toast messages
- **Acceptance**: No hardcoded Ukrainian strings remain in file
- **Completed**: Replaced 15+ hardcoded strings with localized keys

### ✅ T006 [US1] [P] Add Settings strings to Localizable.xcstrings
- **Status**: COMPLETE
- **File**: `AstroSvitla/Resources/Localizable.xcstrings`
- **Action**: Add new keys with translations for all 13 languages
- **Details**:
  - Add `settings.title` (Settings/Налаштування/Einstellungen/...)
  - Add `settings.section.profiles`, `settings.profiles.manage`
  - Add `settings.section.appearance`, `settings.theme.*`
  - Add `settings.section.about`, `settings.about.*`
  - Add `settings.devmode.enabled`, `settings.devmode.disabled`
  - Ensure all keys have state "translated" for all languages
- **Acceptance**: All Settings keys exist with 13 language translations
- **Completed**: Added 25+ settings keys with all 13 translations

### ✅ T007 [US1] Audit and extract Chart Input screen strings
- **Status**: COMPLETE
- **Files**: `AstroSvitla/Features/ChartInput/**/*.swift`
- **Action**: Find and replace hardcoded strings
- **Details**:
  - Replaced 7 Ukrainian strings in BirthDataInputView.swift
  - Replaced 3 Ukrainian strings in LocationSearchView.swift
  - Replaced 1 Ukrainian string in BirthDataInputViewModel.swift
  - Added `birth.location.placeholder` key with 13 translations
- **Acceptance**: No hardcoded strings in ChartInput feature
- **Completed**: All ChartInput files now use localized keys

### ✅ T008 [US1] [P] Audit and extract Area Selection screen strings
- **Status**: COMPLETE
- **Files**: `AstroSvitla/Features/AreaSelection/**/*.swift`
- **Action**: Find and replace hardcoded strings
- **Details**:
  - Replaced 5 Ukrainian strings in AreaSelectionView.swift
  - Replaced 6 Ukrainian strings in AreaCard.swift
  - Added 10 new area.* keys with 13 translations
- **Acceptance**: No hardcoded strings in AreaSelection feature
- **Completed**: All AreaSelection files now use localized keys

### ✅ T009 [US1] [P] Audit and extract Chart Visualization strings
- **Status**: COMPLETE (NO CHANGES NEEDED)
- **Files**: `AstroSvitla/Features/ChartVisualization/**/*.swift`
- **Action**: Find and replace hardcoded strings
- **Note**: No hardcoded Ukrainian strings found - feature already uses localized keys or English-only labels from AstrologyAPI
- **Acceptance**: No hardcoded strings in ChartVisualization feature

**T010** [US1] Audit and extract common components strings
- **Files**: `AstroSvitla/Shared/Components/**/*.swift`
- **Action**: Find and replace hardcoded strings
- **Details**:
  - Use `action.*` prefix for buttons (Back, Cancel, Done, OK, etc.)
  - Use `error.*` and `alert.*` prefixes for error messages
- **Acceptance**: No hardcoded strings in Shared/Components

**T011** [US1] Add all extracted strings to Localizable.xcstrings
- **File**: `AstroSvitla/Resources/Localizable.xcstrings`
- **Action**: Add remaining keys from T007-T010 with all 13 translations
- **Details**:
  - Group keys by feature prefix
  - Ensure consistent naming convention
  - Mark all as state "translated"
- **Acceptance**: All new keys have complete translations

**T012** [US1] Verify locale-aware date/number/time formatting
- **Files**: Various files using DateFormatter/NumberFormatter
- **Action**: Ensure all formatters use `Locale.current`
- **Details**:
  - Search for `DateFormatter()` usages and ensure `formatter.locale = Locale.current`
  - Search for `NumberFormatter()` usages (decimal separators: "3.14" vs "3,14")
  - Verify time formatting respects locale (24h vs 12h AM/PM - e.g., Ukraine uses 24h)
  - Test date/time/number formats display correctly per locale
- **Acceptance**: Dates, times, and numbers format according to device locale

**⏸️ CHECKPOINT**: App UI fully localized; switch device language → UI updates

---

## Phase 3: US2 - Settings Language Button (P1)

**Goal**: User can tap button in Settings to open iOS language settings.
**Test Criteria**: Tap "Change Language" → iOS Settings opens to app page.

### Tasks

**T013** [US2] Add Language section to SettingsView
- **File**: `AstroSvitla/Features/Settings/SettingsView.swift`
- **Action**: Add new section with language settings button
- **Details**:
  - Add `languageSection` computed property
  - Add `SettingsSectionHeader` with globe icon and "Language" title
  - Add `SettingsRow` showing current language from `LocaleHelper.currentLanguageDisplayName`
  - Add button action calling `UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)`
  - Place section between Appearance and About sections
- **Acceptance**: Language section visible in Settings

**T014** [US2] Add Language section strings to Localizable.xcstrings
- **File**: `AstroSvitla/Resources/Localizable.xcstrings`
- **Action**: Add localized strings for language section
- **Details**:
  - Add `settings.section.language` (Language/Мова/Sprache/...)
  - Add `settings.language.change` (Change Language/Змінити мову/...)
  - Add `settings.language.current` if needed for subtitle
- **Acceptance**: Language section displays correctly in all 13 languages

**T015** [US2] [P] Create SettingsLanguageTests
- **File**: `AstroSvitlaTests/Features/Settings/SettingsLanguageTests.swift`
- **Action**: Create tests for language settings functionality
- **Details**:
  - Test `LocaleHelper.currentLanguageDisplayName` returns non-empty string
  - Test language section appears in SettingsView (ViewInspector or snapshot)
- **Acceptance**: Tests pass

**T016** [US2] [P] Create UI test for Settings navigation
- **File**: `AstroSvitlaUITests/SettingsLanguageUITests.swift`
- **Action**: Create UI test verifying Settings button exists
- **Details**:
  - Navigate to Settings tab
  - Verify language change button exists
  - Note: Cannot verify iOS Settings opens (system limitation)
- **Acceptance**: UI test passes

**⏸️ CHECKPOINT**: Language button works; tapping opens iOS Settings

---

## Phase 4: US3 - Reports in Device Language (P2)

**Goal**: Generated reports use device language; language stored with report.
**Test Criteria**: Generate report with device in Spanish → report content in Spanish.

### Tasks

**T017** [US3] Update report generation to use LocaleHelper
- **File**: `AstroSvitla/Features/ReportGeneration/ViewModels/ReportGenerationViewModel.swift`
- **Action**: Pass device language to OpenAI service for response language
- **Details**:
  - Import `LocaleHelper` (if in different module)
  - Replace hardcoded language with `LocaleHelper.currentLanguageCode`
  - Keep existing OpenAI prompt instructions as-is, but ensure response language parameter is set
  - Note: OpenAI will generate report content in the specified language
- **Acceptance**: Reports generate in device language

**T018** [US3] Store languageCode when saving report
- **File**: `AstroSvitla/Features/ReportGeneration/ViewModels/ReportGenerationViewModel.swift`
- **Action**: Save language code to ReportPurchase
- **Details**:
  - Set `reportPurchase.languageCode = LocaleHelper.currentLanguageCode` when creating
  - Ensure this happens before saving to SwiftData
- **Acceptance**: Saved reports have correct languageCode field

**T019** [US3] [P] ~~Update AstrologyAPIService calls with language~~ **SKIPPED**
- **Note**: AstrologyAPI (natal chart SVG) returns English-only labels. No language parameter available.
- **Action**: No changes needed - chart labels remain in English
- **Acceptance**: N/A - API limitation documented

**T020** [US3] [P] Display report language indicator
- **File**: `AstroSvitla/Features/ReportGeneration/Views/ReportListView.swift` (contains `SavedReportDetailView`)
- **Action**: Show original language for saved reports
- **Details**:
  - Add small language indicator/badge to saved report cells in `ReportListRow`
  - Use `LocaleHelper.displayName(for: report.languageCode)`
  - Optional: Only show if different from current device language
- **Acceptance**: User can see what language each saved report is in

**T021** [US3] Localize report section headers
- **File**: `AstroSvitla/Resources/Localizable.xcstrings`
- **Action**: Add/verify report content string translations
- **Details**:
  - Add `report.section.*` keys for any static report headers
  - Verify `generating.*` keys are fully translated
  - Note: Most report content comes from AI, not static strings
- **Acceptance**: Static report UI elements localized

**T022** [US3] [P] Test report language persistence
- **File**: `AstroSvitlaTests/Features/ReportGeneration/ReportLanguageTests.swift`
- **Action**: Create tests for language persistence
- **Details**:
  - Test new ReportPurchase has languageCode set
  - Test languageCode matches LocaleHelper.currentLanguageCode
- **Acceptance**: Tests pass

**⏸️ CHECKPOINT**: Reports generate in device language; language stored correctly

---

## Phase 5: US4 - Sharing/Export Localized (P2)

**Goal**: Instagram carousels and PDFs display text in device language.
**Test Criteria**: Share carousel with device in German → slide text in German.

### Tasks

**T023** [US4] Localize Instagram carousel slide text and watermarks
- **File**: `AstroSvitla/Features/ReportGeneration/ViewModels/InstagramShareViewModel.swift`
- **Action**: Ensure all slide text and branding uses localized strings
- **Details**:
  - Verify `carousel_title_*` keys are used
  - Replace any remaining hardcoded strings
  - Check CTA text is localized
  - Localize any watermarks or branding text (e.g., "Created with AstroSvitla")
- **Acceptance**: All carousel text and branding comes from Localizable.xcstrings

**T024** [US4] Add carousel strings for all languages
- **File**: `AstroSvitla/Resources/Localizable.xcstrings`
- **Action**: Complete translations for carousel keys
- **Details**:
  - Verify `carousel_title_cover`, `carousel_title_analysis`, etc.
  - Add `carousel_cta_*` keys if missing
  - Add `carousel_branding_*` keys for watermarks/branding
  - Ensure all 13 languages have translations
- **Acceptance**: Carousel keys fully translated

**T025** [US4] [P] Localize PDF export content and branding
- **File**: `AstroSvitla/Features/ReportGeneration/Services/ReportPDFGenerator.swift`
- **Action**: Replace hardcoded PDF text with localized strings
- **Details**:
  - Localize PDF title, headers, footers
  - Localize "Generated on" label
  - Localize any watermarks or branding text in PDF
  - Use locale-aware date formatter for timestamp
  - Add `pdf.*` keys to Localizable.xcstrings
- **Acceptance**: PDF content and branding displays in device language

**T026** [US4] [P] Localize share sheet text
- **File**: `AstroSvitla/Utils/ShareSheet.swift`
- **Action**: Localize default share text and captions
- **Details**:
  - Find share sheet initialization
  - Replace hardcoded share text with localized string
  - Add `share.*` keys to Localizable.xcstrings
- **Acceptance**: Share sheet default text is localized

**T027** [US4] Test CJK font rendering in carousels
- **Action**: Manual verification task
- **Details**:
  - Generate carousel with device in Japanese, Korean, Chinese
  - Verify text renders correctly (no missing glyphs)
  - Check text doesn't overflow/truncate
- **Acceptance**: CJK text displays correctly in carousel images

**⏸️ CHECKPOINT**: Sharing and export fully localized

---

## Phase 6: US5 - Onboarding Localized (P3)

**Goal**: Onboarding screens display in device language.
**Test Criteria**: First launch with device in French → onboarding in French.

### Tasks

**T028** [US5] Verify onboarding string extraction
- **Files**: `AstroSvitla/Features/Onboarding/**/*.swift`
- **Action**: Confirm all strings use `String(localized:)` or LocalizedStringKey
- **Details**:
  - Review OnboardingViewModel.swift (already has localized strings)
  - Review OnboardingView.swift for any hardcoded strings
  - Check OnboardingPageView and related components
- **Acceptance**: All onboarding text uses localization

**T029** [US5] Complete onboarding translations
- **File**: `AstroSvitla/Resources/Localizable.xcstrings`
- **Action**: Verify all `onboarding.*` keys have 13 translations
- **Details**:
  - Check `onboarding.page1.*`, `onboarding.page2.*`, etc.
  - Check `onboarding.skip`, `onboarding.next`, `onboarding.start`
  - Fill in any missing translations
- **Acceptance**: All onboarding keys have state "translated" for all languages

**T030** [US5] [P] Test onboarding in multiple languages
- **File**: `AstroSvitlaUITests/OnboardingLocalizationUITests.swift`
- **Action**: Create UI tests for onboarding localization
- **Details**:
  - Note: Changing device language in UI tests is limited
  - Can verify onboarding elements exist and have text
  - Manual testing required for full language verification
- **Acceptance**: UI tests pass; manual verification complete

**⏸️ CHECKPOINT**: Onboarding fully localized

---

## Phase 7: Polish & Verification

**Goal**: Final verification that all strings are translated and no hardcoded text remains.

### Tasks

**T031** [Polish] Run comprehensive hardcoded string audit
- **Action**: Search entire codebase for remaining hardcoded strings
- **Details**:
  - Run `grep -rn 'Text("' --include="*.swift" AstroSvitla/ | grep -v 'localized'`
  - Run `grep -rn '\"[А-Яа-яЇїІіЄєҐґ]' --include="*.swift" AstroSvitla/` for Cyrillic
  - Review and extract any remaining user-visible strings
- **Acceptance**: No hardcoded user-visible strings found

**T032** [Polish] Verify translation completeness
- **File**: `AstroSvitla/Resources/Localizable.xcstrings`
- **Action**: Check all strings have "translated" state
- **Details**:
  - Open in Xcode and check translation status
  - Look for any "new" or "needs review" states
  - Ensure all 13 languages are complete
- **Acceptance**: 100% translation coverage; release gate passed

**⏸️ CHECKPOINT**: Feature complete; ready for QA and release

---

## Dependencies

```text
T001 (LocaleHelper) ──┬──▶ T005-T012 (US1: UI Localization)
                      ├──▶ T013-T016 (US2: Settings Button)
                      ├──▶ T017-T022 (US3: Reports)
                      └──▶ T023-T027 (US4: Sharing)

T002 (Model) ─────────▶ T018, T020 (Report persistence)

T004 (Info.plist) ────▶ All phases (iOS language recognition)

US1 ───▶ US2 ───┬───▶ US3 ───▶ US4 ───▶ US5 ───▶ Polish
                │
                └───▶ Can start in parallel after T001
```

---

## Parallel Execution Opportunities

### Within Setup Phase
- T003 (tests) and T004 (Info.plist) can run in parallel

### Within US1 Phase
- T006, T008, T009 can run in parallel (different files)
- T005, T007, T010 are sequential (may share components)

### Within US2 Phase
- T015 (unit tests) and T016 (UI tests) can run in parallel

### Within US3 Phase
- T019, T020, T022 can run in parallel

### Within US4 Phase
- T025 and T026 can run in parallel

### Cross-Phase Parallelism
After T001 completes:
- US1 (T005-T012) and US2 (T013-T016) can run in parallel
- US3 and US4 can start once US1 checkpoint passes

---

## Implementation Strategy

### MVP Scope (Recommended First Delivery)
1. Complete **Phase 1 (Setup)** + **Phase 2 (US1)** + **Phase 3 (US2)**
2. This delivers:
   - All UI localized
   - Settings language button working
   - Foundation for remaining stories
3. Estimate: 2-3 days development + translation time

### Full Delivery
1. Complete remaining phases (US3, US4, US5, Polish)
2. Coordinate with translation team for all 13 languages
3. QA verification in each language
4. Estimate: 1-2 additional days development + translation review

### Translation Coordination
- Export XLIFF after T011 (all strings extracted)
- Send to translators with context notes
- Import translations before T032 (verification)
- Block release until all languages complete (per clarification)

---

## Summary

| Metric | Value |
|--------|-------|
| Total Tasks | 32 |
| Setup Tasks | 4 |
| US1 Tasks (UI Localization) | 8 |
| US2 Tasks (Settings Button) | 4 |
| US3 Tasks (Reports) | 6 |
| US4 Tasks (Sharing/Export) | 5 |
| US5 Tasks (Onboarding) | 3 |
| Polish Tasks | 2 |
| Parallel Opportunities | 12 tasks marked [P] |
| Checkpoints | 7 |
