# Feature Specification: AstroSvitla - iOS Natal Chart & AI Predictions App

**Feature Branch**: `001-astrosvitla-ios-native`
**Created**: 2025-10-07
**Updated**: 2025-10-09
**Status**: Revised - Simplified Multi-Profile UX
**Input**: User description: "iOS native astrology app with personalized natal chart calculations and AI-powered life area predictions using pay-per-report model + Simplified multi-profile management: all profile selection and creation happens inline on Home tab with dropdown selector, no separate screens or modals"

## Execution Flow (main)
```
1. ✅ Parse user description from Input
2. ✅ Extract key concepts from description
3. ✅ Mark unclear aspects with [NEEDS CLARIFICATION]
4. ✅ Fill User Scenarios & Testing section
5. ✅ Generate Functional Requirements
6. ✅ Identify Key Entities
7. ✅ Run Review Checklist
8. ✅ Return: SUCCESS (spec ready for planning)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers

---

## User Scenarios & Testing

### Primary User Story
As a person interested in astrology, I want to generate personalized predictions for specific areas of my life and for my loved ones based on accurate natal charts, so I can gain insights for multiple people without paying for features I don't need. I want to easily switch between different people's charts and see their reports organized separately.

### Core User Journeys

#### Journey 1: First-Time User - Generate First Report
1. User opens app for the first time
2. User views onboarding screens explaining pay-per-report value proposition
3. User enters birth data: date, exact time, and location
4. System calculates natal chart with astronomical precision
5. User views their natal chart visualization
6. User selects a life area they want insights for (e.g., "Finances")
7. User sees price and confirms purchase
8. System generates personalized AI report based on chart and expert astrology rules
9. User reads detailed report with predictions and recommendations
10. User saves report for future reference or exports as PDF

#### Journey 2: Returning User - Additional Report
1. User opens app with existing natal chart
2. User views their previously generated chart
3. User selects different life area (e.g., "Career")
4. User purchases report
5. User receives new personalized report
6. User compares insights across different life areas

#### Journey 3: Simplified Multi-Profile Flow (Home Tab Only)
1. User opens app and lands on Home tab
2. User sees profile selector at top showing current profile (default: last used or "New Profile")
3. User taps profile selector dropdown
4. User chooses either:
   - **Option A**: Select existing profile from list
   - **Option B**: Tap "Create New Profile" button
5. If creating new profile:
   - User enters name (e.g., "Mom", "Partner", "John")
   - User enters birth date, time, and location directly below
   - User taps "Continue" button
   - System saves profile with calculated natal chart
   - Profile selector updates to show new profile name
6. If selecting existing profile:
   - System loads saved profile data
   - Birth data fields populate automatically
   - Profile selector shows selected profile name
7. User can now generate reports for currently selected profile
8. All actions (view chart, generate report) apply to active profile
9. Reports tab shows all reports grouped by profile

### Acceptance Scenarios

#### Scenario 1: Accurate Birth Data Input
- **Given** user is on birth data entry screen
- **When** user enters date (April 15, 1990), time (14:30), and location (Kyiv, Ukraine)
- **Then** system validates all required fields are filled
- **And** system geocodes location to precise latitude/longitude coordinates
- **And** system enables "Calculate Chart" button

#### Scenario 2: Chart Calculation & Visualization
- **Given** user has entered valid birth data
- **When** user taps "Calculate Chart"
- **Then** system calculates planetary positions, houses, and aspects
- **And** system displays circular natal chart visualization
- **And** chart shows 12 zodiac signs, planet positions, and ascendant marker
- **And** calculation completes within 3 seconds

#### Scenario 3: Life Area Selection
- **Given** user's natal chart is calculated
- **When** user views area selection screen
- **Then** system displays 5 available life areas with icons:
  - 💰 Finances and Material Prosperity
  - 💼 Career and Professional Growth
  - ❤️ Relationships and Love
  - 🏥 Health and Wellness
  - 🎯 General Life Overview
- **And** each area shows its individual price
- **And** user can tap any area to proceed to purchase

#### Scenario 4: Report Purchase & Generation
- **Given** user selects "Finances" area ($6.99)
- **When** user confirms purchase through system payment
- **And** payment succeeds
- **Then** system generates AI-powered personalized report
- **And** report includes: key influences (2-3 sentences), detailed financial analysis (400-500 words), practical recommendations (3-4 tips)
- **And** report generation completes within 10 seconds
- **And** report is saved to user's device
- **And** user can access report anytime without repurchasing

#### Scenario 5: Report Access & Export
- **Given** user has purchased report for "Career"
- **When** user opens purchased report
- **Then** system displays report with chart visualization
- **And** user can read full text content
- **And** user can export report as PDF
- **And** user can share report text

#### Scenario 6: Bilingual Support
- **Given** user's device is set to Ukrainian language
- **When** user opens app
- **Then** all UI elements display in Ukrainian
- **And** generated reports are in Ukrainian
- **Given** user's device is set to English language
- **Then** all UI elements display in English
- **And** generated reports are in English

#### Scenario 7: Profile Switcher - Select Existing Profile (Home Tab Only)
- **Given** user is on Home tab with "John" profile active
- **When** user taps profile selector dropdown at top of screen
- **Then** system shows inline dropdown list of all saved profiles
- **And** list shows: "John ✓", "Mom", "Partner", "Create New Profile"
- **When** user taps "Mom" from list
- **Then** dropdown closes automatically
- **And** profile selector button updates to show "Mom"
- **And** birth data fields below populate with Mom's saved data
- **And** user can now view chart or generate reports for Mom

#### Scenario 8: Profile Switcher - Create New Profile Inline (Home Tab Only)
- **Given** user is on Home tab viewing "John" profile
- **When** user taps profile selector dropdown
- **And** user taps "Create New Profile" from dropdown
- **Then** dropdown closes
- **And** profile selector shows "New Profile" label
- **And** all birth data fields clear to empty state
- **When** user enters name "Partner" in name field
- **And** user enters birth date, time, location in form below
- **And** user taps "Continue" button at bottom
- **Then** system validates name is unique and all fields filled
- **And** system calculates natal chart (shows loading indicator)
- **And** system saves new profile "Partner" to database
- **And** profile selector updates to show "Partner"
- **And** form fields remain populated with Partner's data
- **And** user can now proceed to generate reports

#### Scenario 9: First-Time User - No Profiles Exist
- **Given** user completes onboarding (no profiles created yet)
- **When** user lands on Home tab for first time
- **Then** profile selector shows "New Profile" as default
- **And** all birth data fields are empty (placeholder text visible)
- **And** "Continue" button is disabled (no data entered yet)
- **When** user enters name and complete birth data
- **And** user taps "Continue"
- **Then** system creates first profile
- **And** profile selector updates to show entered name
- **And** this profile becomes default for future app launches

#### Scenario 10: Profile Switcher - Edge Cases
- **What happens when** user selects same profile already active?
  - **Then** dropdown closes, no data reloads, no API calls
- **What happens when** user starts entering data for "New Profile" but switches to existing profile before saving?
  - **Then** system discards unsaved data, loads selected profile data
- **What happens when** user tries to create profile with duplicate name?
  - **Then** system shows error: "A profile with name 'John' already exists"
- **What happens when** user taps "Continue" with empty name field?
  - **Then** button remains disabled OR shows validation error

### Visual Flow Diagram: Simplified Profile Management (Home Tab Only)

```
┌─────────────────────────────────────────────────────────────────────┐
│                        HOME TAB (Main Screen)                        │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
              ┌────────────────────────────────────┐
              │   Profile Selector Dropdown        │
              │   [ John ▼ ]                       │
              └────────────────────────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │   User taps dropdown        │
                    └──────────────┬──────────────┘
                                   │
                                   ▼
              ┌────────────────────────────────────┐
              │   Dropdown Menu Shows:             │
              │   ✓ John (current)                 │
              │   • Mom                            │
              │   • Partner                        │
              │   ─────────────────                │
              │   + Create New Profile             │
              └────────────────────────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
                    ▼                             ▼
        ┌───────────────────┐         ┌──────────────────────┐
        │ SELECT EXISTING   │         │ CREATE NEW PROFILE   │
        │ (e.g., "Mom")     │         │                      │
        └───────────────────┘         └──────────────────────┘
                    │                             │
                    ▼                             ▼
        ┌───────────────────┐         ┌──────────────────────┐
        │ Dropdown closes   │         │ Dropdown closes      │
        │ Selector → "Mom"  │         │ Selector → "New..."  │
        │ Fields populate   │         │ Fields clear         │
        │ with Mom's data   │         │ (empty state)        │
        └───────────────────┘         └──────────────────────┘
                    │                             │
                    │                             ▼
                    │              ┌──────────────────────────┐
                    │              │ User fills form:         │
                    │              │ • Name: "Partner"        │
                    │              │ • Birth Date             │
                    │              │ • Birth Time             │
                    │              │ • Location               │
                    │              └──────────────────────────┘
                    │                             │
                    │                             ▼
                    │              ┌──────────────────────────┐
                    │              │ User taps "Continue"     │
                    │              └──────────────────────────┘
                    │                             │
                    │                             ▼
                    │              ┌──────────────────────────┐
                    │              │ System validates:        │
                    │              │ ✓ Name is unique         │
                    │              │ ✓ All fields filled      │
                    │              └──────────────────────────┘
                    │                             │
                    │                             ▼
                    │              ┌──────────────────────────┐
                    │              │ System:                  │
                    │              │ 1. Calculates chart      │
                    │              │ 2. Saves profile         │
                    │              │ 3. Sets as active        │
                    │              └──────────────────────────┘
                    │                             │
                    └─────────────┬───────────────┘
                                  │
                                  ▼
              ┌────────────────────────────────────┐
              │   Profile Active & Ready           │
              │   Selector shows: "Partner"        │
              │   Fields populated with data       │
              │   ─────────────────────────────    │
              │   User can now:                    │
              │   • View natal chart               │
              │   • Generate reports               │
              │   • Switch to another profile      │
              └────────────────────────────────────┘
```

### State Machine: Profile Selector

```
States:
  ┌─────────────────┐
  │ NO_PROFILE      │ → First-time user, no profiles exist
  └─────────────────┘
           │
           ▼
  ┌─────────────────┐
  │ PROFILE_ACTIVE  │ → Existing profile selected, data loaded
  └─────────────────┘
           │
           ▼
  ┌─────────────────┐
  │ NEW_PROFILE     │ → "Create New" selected, fields empty
  └─────────────────┘
           │
           ▼
  ┌─────────────────┐
  │ SAVING_PROFILE  │ → Validating & calculating chart
  └─────────────────┘
           │
           ▼
  ┌─────────────────┐
  │ PROFILE_ACTIVE  │ → New profile saved, now active
  └─────────────────┘

Transitions:
  NO_PROFILE → PROFILE_ACTIVE (user creates first profile)
  PROFILE_ACTIVE → PROFILE_ACTIVE (user switches to another saved profile)
  PROFILE_ACTIVE → NEW_PROFILE (user taps "Create New Profile")
  NEW_PROFILE → SAVING_PROFILE (user taps "Continue")
  NEW_PROFILE → PROFILE_ACTIVE (user switches to existing profile, discards new)
  SAVING_PROFILE → PROFILE_ACTIVE (validation + save succeeds)
  SAVING_PROFILE → NEW_PROFILE (validation fails, show error)
```

### Edge Cases

#### Data Input Edge Cases
- **What happens when** user enters birth time at midnight (00:00)? → System correctly handles edge of day boundary
- **What happens when** user enters date from 1900s? → System accepts dates from 1900-2100
- **What happens when** location search returns multiple results? → System shows autocomplete list; user selects specific location
- **What happens when** user enters location without internet connection? → System shows error: "Internet required for location search"
- **What happens when** user doesn't know exact birth time? → "unknown time" mode with less specific report generation - we just have to mention this report is more clear with specific time

#### Chart Calculation Edge Cases
- **What happens when** user is born during daylight saving time transition? → System correctly converts to UTC accounting for DST
- **What happens when** user is born in location near date line? → System handles timezone edge cases correctly
- **What happens when** calculation fails due to invalid ephemeris data? → System shows error: "Unable to calculate chart. Please verify birth data."

#### Purchase & Payment Edge Cases
- **What happens when** user's payment is declined? → System shows payment error; no report generated; user can retry
- **What happens when** payment succeeds but report generation fails? → payments should be stored WITH REVENUECAT and retry should be handled
- **What happens when** user tries to purchase same area report twice for same chart? → prevent
- **What happens when** user loses internet during report generation? → retry

#### Multi-User Edge Cases
- **What happens when** user has 10+ saved user profiles? → System allows unlimited users with scrollable list
- **What happens when** user deletes a user profile with purchased reports? → just extra alert before deletion
- **What happens when** user tries to create user with duplicate name? → force unique
- **What happens when** no user is selected on first app launch? → HAS TO BE
- **What happens when** user switches between users while viewing report? → System should exit report view and show main tab for newly selected user
- **What happens when** active user is deleted while being viewed? → Just alert

#### Localization Edge Cases
- **What happens when** user switches language mid-session? → UI updates immediately; previously generated reports remain in original language
- **What happens when** user's device language is neither English nor Ukrainian? → default to eng

#### Storage & Data Edge Cases
- **What happens when** device storage is full? → System shows error before attempting to save
- **What happens when** user reinstalls app? → restore receipts

---

## Requirements

### Functional Requirements

#### Birth Data Input (FR-001 to FR-007)
- **FR-001**: System MUST collect three required fields: birth date, birth time, and birth location
- **FR-002**: System MUST validate birth date is between January 1, 1900 and December 31, 2100
- **FR-003**: System MUST validate birth time with minute-level precision (HH:MM format)
- **FR-004**: System MUST provide location search with autocomplete showing city and country
- **FR-005**: System MUST geocode selected location to latitude/longitude coordinates
- **FR-006**: System MUST prevent chart calculation if any required field is empty
- **FR-007**: System MUST allow users to edit birth data after initial entry

#### Natal Chart Calculation (FR-008 to FR-014)
- **FR-008**: System MUST calculate planetary positions for Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, and Pluto
- **FR-009**: System MUST determine which zodiac sign each planet occupies
- **FR-010**: System MUST calculate 12 houses using Placidus house system
- **FR-011**: System MUST determine which house each planet occupies
- **FR-012**: System MUST calculate major aspects between planets (conjunction, opposition, square, trine, sextile)
- **FR-013**: System MUST identify retrograde planetary motion
- **FR-014**: System MUST complete chart calculation within 3 seconds

#### Chart Visualization (FR-015 to FR-020)
- **FR-015**: System MUST display natal chart as circular diagram
- **FR-016**: Chart MUST show 12 zodiac signs around outer circle
- **FR-017**: Chart MUST display planet positions with standard astrological symbols
- **FR-018**: Chart MUST mark Ascendant (rising sign) clearly
- **FR-019**: Chart MUST be viewable in both light and dark mode
- **FR-020**: Chart visualization MUST be static (no zoom, pan, or interactive elements in MVP)

#### Life Area Selection (FR-021 to FR-026)
- **FR-021**: System MUST offer exactly 5 life area report options:
  - Finances and Material Prosperity
  - Career and Professional Growth
  - Relationships and Love
  - Health and Wellness
  - General Life Overview
- **FR-022**: System MUST display each area as card with icon, title, description, and price
- **FR-023**: System MUST show price in USD for all users
- **FR-024**: System MUST allow user to select any single area at a time
- **FR-025**: System MUST disable already-purchased areas with "View Report" option instead of purchase
- **FR-026**: System MUST clearly communicate pay-per-report model (no subscriptions)

#### Report Generation (FR-027 to FR-035)
- **FR-027**: System MUST generate personalized report based on natal chart data and selected life area
- **FR-028**: Report MUST include three sections:
  1. Key Influences (2-3 sentences about dominant planetary factors)
  2. Detailed Analysis (400-500 words specific to chosen life area)
  3. Practical Recommendations (3-4 actionable tips)
- **FR-029**: System MUST use expert astrology interpretation rules as foundation for report content
- **FR-029a**: System MUST source those rules via an OpenAI-hosted vector store (uploaded embeddings + retrieval API) rather than injecting the entire corpus into a single prompt
- **FR-030**: System MUST generate report in same language as app UI (English or Ukrainian)
- **FR-031**: System MUST complete report generation within 10 seconds
- **FR-032**: Report MUST be personalized and specific to user's unique chart (not generic)
- **FR-033**: System MUST display generation progress indicator during report creation
- **FR-034**: System MUST handle generation errors gracefully with clear error messages
- **FR-035**: System MUST retry failed generation attempts automatically (up to 2 retries)

#### Purchase & Payment (FR-036 to FR-042)
- **FR-036**: System MUST integrate native iOS in-app purchase functionality
- **FR-037**: System MUST show price confirmation sheet before purchase
- **FR-038**: System MUST validate payment success before generating report
- **FR-039**: System MUST store transaction receipt for each purchase
- **FR-040**: System MUST prevent report generation if payment fails
- **FR-041**: System MUST restore previous purchases if user reinstalls app -> all of them, but let it be in leftovers
- **FR-042**: Pricing MUST be:
  - General Overview: $9.99
  - Finances: $6.99
  - Career: $6.99
  - Relationships: $5.99
  - Health: $5.99

#### Report Storage & Access (FR-043 to FR-049)
- **FR-043**: System MUST save purchased reports to device local storage
- **FR-044**: System MUST allow users to access purchased reports offline
- **FR-045**: System MUST display list of all purchased reports organized by user profile on Reports tab
- **FR-046**: System MUST group reports by user with user name as section header
- **FR-047**: System MUST show purchase date, life area, and user name for each report
- **FR-048**: System MUST allow users to export any purchased report as PDF
- **FR-049**: System MUST allow users to share report text via system share sheet

#### Multi-Profile Management - Simplified Flow (FR-050 to FR-065)
**Core Principle**: All profile management happens inline on Home tab, no separate screens or modals

- **FR-050**: System MUST allow users to create multiple user profiles (each with own natal chart)
- **FR-051**: System MUST require unique name for each user profile (e.g., "Me", "Partner", "Mom")
- **FR-052**: System MUST display profile selector dropdown at top of Home tab showing active profile name
- **FR-053**: Profile selector dropdown MUST show:
  - List of all saved profiles with checkmark on active profile
  - "Create New Profile" option at bottom of list
- **FR-054**: When user selects existing profile from dropdown:
  - System MUST close dropdown automatically
  - System MUST load selected profile's birth data into form fields below
  - System MUST update profile selector to show selected profile name
  - System MUST NOT navigate to another screen
- **FR-055**: When user selects "Create New Profile" from dropdown:
  - System MUST close dropdown automatically
  - System MUST clear all birth data fields to empty state
  - System MUST update profile selector to show "New Profile" label
  - System MUST NOT navigate to another screen
- **FR-056**: System MUST show birth data input form directly below profile selector on Home tab at all times
- **FR-057**: Birth data form MUST include: Name field, Birth Date, Birth Time, Birth Location, Continue button
- **FR-058**: When creating new profile, "Continue" button MUST:
  - Validate all fields are filled and name is unique
  - Calculate natal chart in background
  - Save new profile to local storage
  - Update profile selector to show new profile name
  - Keep user on same Home tab screen
- **FR-059**: System MUST maintain "active profile" context throughout app session
- **FR-060**: System MUST persist active profile selection across app launches
- **FR-061**: System MUST associate all purchased reports with active profile
- **FR-062**: System MUST NOT allow profile deletion from Home tab (keep it simple - deletion only in Settings)
- **FR-063**: Reports tab MUST show reports grouped by profile with profile name as section header
- **FR-064**: When no profiles exist (first-time user), system MUST show "New Profile" as default in selector
- **FR-065**: When user switches profiles while editing unsaved "New Profile" data, system MUST discard unsaved data without confirmation

#### Localization (FR-066 to FR-070)
- **FR-066**: System MUST support English language (primary)
- **FR-067**: System MUST support Ukrainian language (secondary)
- **FR-068**: System MUST automatically detect device language and display appropriate language
- **FR-069**: System MUST localize all UI text, labels, and buttons
- **FR-070**: System MUST generate reports in same language as UI

#### Onboarding (FR-071 to FR-074)
- **FR-071**: System MUST show 3-screen onboarding flow on first app launch
- **FR-072**: Onboarding MUST explain: personalized predictions, pay-per-report model, expert knowledge + AI interpretation
- **FR-073**: User MUST be able to skip or navigate through onboarding screens
- **FR-074**: System MUST not show onboarding again after completion

#### Data & Privacy (FR-075 to FR-079)
- **FR-075**: System MUST store all user data locally on device only (no cloud sync in MVP)
- **FR-076**: System MUST NOT require user account or registration
- **FR-077**: System MUST NOT collect analytics or tracking data
- **FR-078**: System MUST NOT share birth data with third parties
- **FR-079**: System MUST handle user data in compliance with iOS privacy requirements

### Non-Functional Requirements

#### Performance (NFR-001 to NFR-005)
- **NFR-001**: App launch time MUST be under 2 seconds
- **NFR-002**: Chart calculation MUST complete within 3 seconds
- **NFR-003**: Report generation MUST complete within 10 seconds
- **NFR-004**: UI interactions MUST maintain 60 FPS
- **NFR-005**: App size MUST be under 50 MB

#### Reliability (NFR-006 to NFR-008)
- **NFR-006**: App crash-free rate MUST exceed 99%
- **NFR-007**: Chart calculations MUST have astronomical accuracy (NASA ephemeris precision)
- **NFR-008**: Report generation success rate MUST exceed 95%

#### Usability (NFR-009 to NFR-011)
- **NFR-009**: App MUST support iOS 17.0 and later
- **NFR-010**: App MUST support iPhone SE (2020) and newer devices
- **NFR-011**: App MUST support portrait orientation only

### Key Entities

#### App User (Device Owner)
- Represents: Anonymous app user (no account/registration)
- Attributes: Unique device identifier, app installation date, active user profile ID
- Relationships: Has many User Profiles, Has many Report Purchases
- Business Rules: No authentication required; one app installation per device; maintains single "active user profile" context

#### User Profile
- Represents: Individual person with their own natal chart and birth data
- Attributes: Unique name (within device), birth date, birth time, birth location (city name, latitude, longitude), creation date, is_active flag
- Relationships: Belongs to App User, Has one Birth Chart, Has many Report Purchases
- Business Rules: Name must be unique within device; one user profile can only have one natal chart; represents real person (self or others)

#### Birth Chart
- Represents: Complete natal chart for specific User Profile at specific birth moment
- Attributes: Calculation results (planetary positions, houses, aspects), calculation date
- Relationships: Belongs to User Profile
- Business Rules: Requires exact birth time for accuracy; location must be geocoded; calculations are immutable once generated; one-to-one with User Profile

#### Report Purchase
- Represents: Single purchased report for specific life area for specific User Profile
- Attributes: Life area type (finances/career/relationships/health/general), generated report text, purchase date, price paid, transaction receipt ID, user profile ID
- Relationships: Belongs to User Profile, Belongs to Birth Chart, Belongs to App User
- Business Rules: Each purchase is for one life area only; report content is fixed after generation; user owns report permanently; reports are associated with specific User Profile and their chart

#### Life Area
- Represents: Category of astrological prediction
- Options: Finances, Career, Relationships, Health, General Overview
- Attributes: Display name, description, price, icon/emoji
- Business Rules: Fixed set of 5 areas; each has individual price; user can purchase multiple areas for same chart

#### Astrological Rule
- Represents: Expert interpretation guideline for chart pattern
- Attributes: Rule identifier, category (life area), condition (planet + house + aspects), interpretation text (English), interpretation text (Ukrainian), relevance weight
- Business Rules: Rules are curated by professional astrologer; stored as embedded data in app; used as foundation for AI report generation

---

## Review & Acceptance Checklist

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No markers remain (10 clarifications needed - see edge cases and FR-060)
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

### Open Questions Requiring Clarification
1. Should app support "unknown birth time" mode? How to handle incomplete data?
2. What is refund/retry policy if payment succeeds but report generation fails?
3. Should system prevent duplicate purchases of same area report for same user profile?
4. What is retry mechanism if user loses internet during report generation?
5. What happens to purchased reports when user deletes associated User Profile?
6. What is default language behavior if device language is neither English nor Ukrainian?
7. What specific purchases are restorable after app reinstall?
8. What happens when user tries to create User Profile with duplicate name?
9. What happens on first app launch when no User Profile exists yet?
10. What happens when active User Profile is deleted while being viewed?

---

## Execution Status

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [ ] Review checklist passed (pending clarifications)

---

## Success Metrics

### User Acquisition
- Target: 100 downloads in first month
- Target: 1,000 downloads by month 3
- App Store rating target: 4.5+

### User Engagement
- Target: 50% of users create natal chart
- Target: 30% conversion rate (chart creation → purchase)
- Target: Average 2.5 reports purchased per converting user

### Revenue
- Month 1 target: $200-300
- Month 3 target: $2,000-2,500
- Month 6 target: $10,000-15,000

### Quality
- Crash-free rate: >99%
- Chart calculation accuracy: NASA ephemeris precision
- Report generation success rate: >95%
- Average report generation time: <10 seconds

---

## Constraints & Assumptions

### Constraints
- iOS platform only (no Android, web)
- English and Ukrainian languages only
- USD pricing only (App Store handles conversion)
- Portrait orientation only
- No user accounts/authentication
- No cloud sync (local storage only)
- Pay-per-report model only (no subscriptions)

### Assumptions
- Users know their exact birth time (or can obtain it)
- Users have internet connection for initial report generation
- Users are comfortable with English or Ukrainian language
- Users have iOS device with iOS 17.0+
- Expert astrology rules database is curated and accurate
- AI-generated reports are coherent and valuable to users

### Dependencies
- Expert astrologer provides interpretation rules database
- Astronomical calculation library (ephemeris data) is accurate and maintained
- AI service is available and reliable for report generation
- iOS App Store approval and in-app purchase functionality
- Payment processing infrastructure (Apple)

---

## Out of Scope (Not in MVP)

The following features are explicitly excluded from initial release:

### Future Features (Post-MVP)
- **Transits**: Current planetary influences and personal event calendar
- **Synastry**: Compatibility analysis between two charts
- **Progressions**: Chart evolution over time, yearly predictions
- **Social Features**: Share charts with friends, social media export
- **Premium Subscription**: Unlimited reports, early access to features
- **Cloud Sync**: Multi-device access, data backup
- **Android App**: Android platform support
- **Additional Languages**: Beyond English and Ukrainian
- **User Accounts**: Login, profiles, saved preferences
- **Push Notifications**: Daily horoscopes, transit alerts
- **In-app Chat**: Consultation with professional astrologers
- **Custom Reports**: User-defined report templates
- **Advanced Visualizations**: Interactive charts, aspect lines, 3D models

---

## Appendix: Glossary

**Natal Chart**: Astrological chart representing exact positions of celestial bodies at moment and location of birth

**Ascendant (Rising Sign)**: Zodiac sign rising on eastern horizon at moment of birth

**Houses**: 12 divisions of astrological chart representing life areas

**Aspects**: Angular relationships between planets (conjunction, opposition, trine, square, sextile)

**Ephemeris**: Table of calculated positions of celestial objects at regular intervals

**Retrograde**: Apparent backward motion of planet from Earth's perspective

**Placidus House System**: Method of dividing chart into 12 houses based on time

**Geocoding**: Converting location name into latitude/longitude coordinates

**Pay-per-Report**: Monetization model where users pay for individual reports rather than subscription

**Life Area**: Specific domain of life (finances, career, relationships, health, general)
