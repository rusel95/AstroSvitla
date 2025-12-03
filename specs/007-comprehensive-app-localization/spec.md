# Feature Specification: Comprehensive App Localization

**Feature Branch**: `007-comprehensive-app-localization`  
**Created**: 2025-12-03  
**Status**: Tasks Ready  
**Input**: User description: "Localization across the app. All text which is shown, all received reports, sharing, EVERYTHING! And we should have a switcher of language on Settings. ONLY native localization. So no custom language selection - selection via settings"

---

## Clarifications

### Session 2025-12-03

- Q: How should the Settings language button work? → A: Button in app Settings directly opens iOS app-specific settings page for language selection, allowing easy navigation back to app.
- Q: Translation rollout strategy for 13 languages? → A: All 13 languages required at launch; block release until complete.
- Q: Missing translation handling? → A: Fall back to English for specific missing strings (iOS native behavior); however, all translations must be 100% complete at launch.
- Q: Source for astrological terminology translations? → A: Use established astrological literature/dictionaries for each language.

---

## Overview

Complete localization coverage for the AstroSvitla app ensuring all user-facing content is translated, including UI text, generated astrological reports, sharing content, and system messages. Language selection follows iOS native behavior through Settings app rather than custom in-app language picker.

---

## User Scenarios & Testing

### Primary User Story

As a user who speaks a language other than English, I want the entire app experience—including all UI elements, generated reports, shared content, and notifications—to appear in my preferred language as set in iOS device settings, so I can fully understand and use the app without language barriers.

### Acceptance Scenarios

1. **Given** a user has their device language set to Ukrainian, **When** they launch the app for the first time, **Then** all UI text, labels, buttons, and navigation elements display in Ukrainian.

2. **Given** a user generates a natal chart report in Spanish, **When** the report is created, **Then** the entire report content (analysis text, section headers, recommendations) appears in Spanish.

3. **Given** a user shares their natal chart via Instagram carousel, **When** they view the shared images, **Then** all text overlays, captions, and call-to-action text appear in the user's device language.

4. **Given** a user exports a report as PDF, **When** they open the PDF, **Then** all report text, headers, and metadata labels are in the user's device language.

5. **Given** a user changes their iOS device language from English to German, **When** they reopen the app, **Then** the entire app interface and any newly generated content appears in German.

6. **Given** a user views the Settings screen, **When** they look for language options, **Then** they see a link/button that directs them to iOS Settings to change the app language (no in-app language picker).

7. **Given** the app receives an error from the server, **When** the error message is displayed, **Then** the error appears in the user's preferred language.

8. **Given** a user has previously saved reports in English, **When** they change device language to French, **Then** previously saved reports remain in English (original generation language) but new reports are generated in French.

### Edge Cases

- What happens when a user's device language is not supported? The app falls back to English.
- What happens when a specific string is missing translation in a supported language? Falls back to English for that string only (iOS native behavior). Note: All translations must be 100% complete at launch.
- What happens when report generation occurs offline with cached content? Cached content displays in its original language with a note that fresh content may differ.
- How does the system handle right-to-left (RTL) languages if supported in the future? UI elements automatically mirror layout direction based on language settings.
- What happens when a user shares content and the recipient has a different language? Shared content remains in the sharer's language at time of sharing.

---

## Requirements

### Functional Requirements

#### UI Localization

- **FR-001**: System MUST display all static UI text (labels, buttons, titles, placeholders, accessibility labels) in the user's iOS device language.
- **FR-002**: System MUST localize all navigation elements including tab bar titles, navigation bar titles, and toolbar items.
- **FR-003**: System MUST localize all error messages, alerts, and confirmation dialogs.
- **FR-004**: System MUST localize all empty state messages and placeholder content.
- **FR-005**: System MUST localize all tooltips, help text, and informational messages.

#### Generated Content Localization

- **FR-006**: System MUST generate natal chart reports in the user's device language.
- **FR-007**: System MUST include localized astrological terminology in reports (planet names, zodiac signs, house names, aspect names).
- **FR-008**: System MUST localize all report section headers and subheaders.
- **FR-009**: System MUST localize numerical formatting (date formats, decimal separators) according to locale.
- **FR-010**: System MUST preserve the language of previously generated reports (no retroactive translation).

#### Sharing & Export Localization

- **FR-011**: System MUST generate Instagram carousel images with text overlays in the user's device language.
- **FR-012**: System MUST localize PDF export content including headers, footers, and metadata labels.
- **FR-013**: System MUST localize share sheet default text and suggested captions.
- **FR-014**: System MUST localize any watermarks or branding text in shared content.

#### Settings & Language Selection

- **FR-015**: System MUST use iOS native language selection mechanism (no custom in-app picker).
- **FR-016**: System MUST provide a button in the app's Settings screen that directly opens the iOS app-specific settings page, allowing users to easily change language and return to the app.
- **FR-017**: System MUST immediately reflect language changes when user returns from iOS Settings.
- **FR-018**: System MUST display current language setting in the Settings screen for user awareness.

#### Onboarding & First Launch

- **FR-019**: System MUST display onboarding content in the user's device language on first launch.
- **FR-020**: System MUST localize all onboarding tutorial text, images with text, and call-to-action buttons.

#### Data & Persistence

- **FR-021**: System MUST store the language used when generating each report for reference.
- **FR-022**: System MUST NOT automatically re-translate saved content when language changes.

### Supported Languages

- **FR-024**: System MUST support English (en) as the base/fallback language.
- **FR-025**: System MUST support Ukrainian (uk) as a fully translated language.
- **FR-026**: System MUST support all additional languages at launch: German (de), French (fr), Spanish (es), Portuguese-Brazil (pt-BR), Italian (it), Japanese (ja), Korean (ko), Simplified Chinese (zh-Hans), Traditional Chinese (zh-Hant), Russian (ru), Turkish (tr). Release is blocked until all 13 languages are complete.

### Key Entities

- **LocalizableString**: A text element that requires translation, with base language value and translations per supported locale.
- **GeneratedReport**: An astrological report that stores both content and the language in which it was generated.
- **ShareableContent**: Images or documents with embedded localized text for sharing.
- **LocaleConfiguration**: User's preferred locale settings derived from iOS device settings.

---

## Assumptions

1. The existing localization file will be extended to cover all strings.
2. Report generation service can accept a language parameter to return localized content.
3. iOS per-app language settings feature is available to all target users (iOS 13+).
4. All astrological terminology translations are sourced from established astrological literature/dictionaries for each language (not literal translations).
5. RTL language support is out of scope for initial implementation.
6. Machine translation is not used; all translations are human-verified.

---

## Success Criteria

1. **100% UI coverage**: All visible text in the app is localized with no hardcoded strings remaining.
2. **Report localization**: Users can generate reports in any supported language, with accuracy verified by native speakers.
3. **Sharing quality**: Shared Instagram carousels and PDFs display properly formatted localized text.
4. **Native experience**: Language changes via iOS Settings take effect immediately without requiring app restart.
5. **User satisfaction**: Users in non-English markets report understanding all app content in user feedback.
6. **Fallback reliability**: Users with unsupported device languages see a complete English experience with no missing translations.

---

## Out of Scope

- Custom in-app language picker (explicitly excluded per requirements)
- Right-to-left (RTL) language support (Arabic, Hebrew)
- Audio/voice localization
- Localized push notification content (server-side configuration)
- Community-contributed translations

---

## Dependencies

- iOS per-app language settings (iOS 13+)
- Backend service support for language parameter in report generation
- Translation services/team for completing missing translations
- QA resources for language-specific testing

---

## Execution Status

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked (none required - clear requirements)
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist passed

---
