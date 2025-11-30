# Feature Specification: Instagram Share Templates for Zorya Astrology App

**Feature Branch**: `006-instagram-share-templates`  
**Created**: 2024-11-30  
**Status**: Draft  
**Input**: User description: "Create 4 professional Instagram share templates for PDF reports with Chart Only Stories, Key Insights Post, Recommendations Stories, and Full Carousel formats, positioned near the 'Export PDF' button in ReportDetailView"

---

## Clarifications

### Session 2024-11-30

- Q: When should AI generate share-specific condensed content? → A: Generate together with main report (stored in GeneratedReport)
- Q: Should share-optimized content be separate or integrated into existing fields? → A: New dedicated `shareContent` structure as a separate field in the report
- Q: Should branding tagline be localized or fixed? → A: Localized tagline matching user's app language
- Q: When should image rendering occur? → A: Pre-render all 4 templates in background when report loads
- Q: What content for "Detailed Analysis" carousel slide? → A: AI-generated 3-4 bullet points summarizing analysis (add to ShareContent)

---

## Overview

Enable users to share their astrological reports on Instagram using professionally designed templates. This feature provides 4 distinct template formats optimized for different Instagram sharing contexts, allowing users to share their natal chart insights with friends and followers while promoting the Zorya app.

## Success Criteria

1. Users can generate and share Instagram-ready images within 5 seconds
2. At least 30% of users who view a report attempt to share at least one template within the first month
3. Shared images maintain visual quality across all target device sizes (iPhone SE to iPhone 15 Pro Max)
4. All text renders correctly with proper character support for all supported languages (including Cyrillic: і, ї, є, ґ)
5. User satisfaction rating for share feature exceeds 4.0/5.0
6. Template images are under 1MB file size for quick sharing
7. 100% of generated images pass Instagram's recommended dimensions and format requirements

---

## User Scenarios & Testing

### Primary User Story
As a Zorya app user who has generated an astrological report, I want to share visually appealing images of my natal chart and insights on Instagram, so that I can express my personality and introduce my friends to astrology.

### Acceptance Scenarios

1. **Given** a user is viewing their completed report, **When** the report loads, **Then** all 4 template images are pre-rendered in background for instant access

2. **Given** a user is viewing their completed report, **When** they tap the share button area, **Then** they see 4 template options with already-generated previews (Chart Only, Key Insights, Recommendations, Carousel)

3. **Given** a user selects "Chart Only" template, **When** they view the preview, **Then** they see their natal chart in Instagram Stories format (9:16) with their name, birth details, and Zorya branding

4. **Given** a user selects "Key Insights" template, **When** they view the preview, **Then** they see a square format (1:1) image with their summary and top 3 planetary influences

5. **Given** a user selects "Recommendations" template, **When** they view the preview, **Then** they see a Stories format image with their personalized astrological recommendations

6. **Given** a user selects "Carousel" template, **When** they view the preview, **Then** they see 5 separate images: Cover, Summary, Top Influences, Detailed Analysis, and Recommendations+CTA

7. **Given** a user has selected any template, **When** they tap "Share", **Then** the iOS share sheet opens with the pre-rendered image(s) ready to post to Instagram

8. **Given** a user views a template, **When** the user's name contains Ukrainian characters (і, ї, є, ґ), **Then** all characters render correctly without substitution

9. **Given** a user is viewing the report, **When** they look at the action buttons area, **Then** the Instagram share options appear near/with the "Export PDF" button

### Edge Cases

- What happens when the natal chart image fails to load? → Show placeholder with retry option
- What happens when text content exceeds template bounds? → Truncate with "..." and ensure "See full report in Zorya" hint
- How does system handle users with very long names? → Truncate name after 20 characters with "..."
- What happens if user cancels share midway? → Clean up temporary files, return to report view
- How does system handle low memory situations? → Generate templates one at a time, show progress indicator

---

## Requirements

### Functional Requirements

#### Template Generation

- **FR-001**: System MUST provide 4 distinct share template types:
  - Chart Only (Stories format, 1080x1920px)
  - Key Insights (Post format, 1080x1080px)
  - Recommendations (Stories format, 1080x1920px)
  - Full Carousel (5 slides, Post format, 1080x1080px each)

- **FR-002**: System MUST generate images in PNG format with RGB color space

- **FR-003**: System MUST include the following dynamic content in templates:
  - User's name (from BirthDetails)
  - Birth date and time (formatted per user's locale)
  - Birth location
  - Natal chart visualization
  - AI-generated share-optimized summary (max 280 characters, generated with main report)
  - AI-generated condensed key influences (3-5 items, max 40 chars each)
  - AI-generated short recommendations (up to 4 items, max 60 chars each)
  - AI-generated analysis bullet points (3-4 items, max 50 chars each, for carousel)
  - Report area type (e.g., "Фінанси", "Кар'єра")

- **FR-004**: System MUST apply consistent Zorya branding to all templates:
  - App name: "Zorya" with localized tagline (matching user's app language)
  - Brand colors: Purple/violet gradient primary, gold accent
  - App URL: "zorya.app"
  - Localized watermark (e.g., "Згенеровано за допомогою Zorya" / "Generated with Zorya")

- **FR-005**: System MUST support full character sets for all supported languages including Cyrillic (і, ї, є, ґ) and proper typographic characters

- **FR-006**: System MUST ensure all generated images are under 1MB file size

#### User Interface

- **FR-007**: System MUST display Instagram share options in proximity to the existing "Export PDF" button in ReportDetailView

- **FR-008**: System MUST pre-render all 4 template types in background when report view loads, enabling instant preview access

- **FR-009**: System MUST show template previews before sharing to help users choose

- **FR-010**: System MUST display a loading indicator if background rendering is still in progress when user accesses share options

- **FR-011**: System MUST allow users to preview generated images before sharing

- **FR-012**: System MUST integrate with iOS share sheet for Instagram and other social sharing

#### Visual Quality

- **FR-013**: System MUST maintain text legibility with minimum 7:1 contrast ratio for body text

- **FR-014**: System MUST ensure natal chart images are crisp and readable at target dimensions

- **FR-015**: System MUST render smooth gradients without visible banding

#### Data Handling

- **FR-016**: System MUST clean up temporary image files after sharing completes or cancels

- **FR-017**: System MUST handle generation failures gracefully with user-friendly error messages

### Key Entities

- **ShareTemplate**: Represents a template type with its format, dimensions, and layout configuration
- **ShareContent**: Dedicated structure within GeneratedReport containing AI-generated content optimized for social sharing:
  - `shareSummary`: Summary text ≤280 characters
  - `shareInfluences`: Array of 3-5 condensed influence strings ≤40 characters each
  - `shareRecommendations`: Array of up to 4 short recommendations ≤60 characters each
  - `shareAnalysisBullets`: Array of 3-4 analysis summary bullet points ≤50 characters each (for carousel)
- **TemplateContent**: The user-specific data populated into a template (name, birth details, ShareContent, natal chart)
- **GeneratedShareImage**: The resulting PNG image ready for sharing, including file path and metadata

---

## Assumptions

1. Users have a generated report with valid natal chart data before accessing share features
2. Device has sufficient memory to generate high-resolution images (minimum 100MB free)
3. Brand colors and visual style match existing Zorya app design language
4. App supports multiple languages; share content respects user's selected locale
5. iOS share sheet provides adequate integration for Instagram sharing without custom Instagram SDK
6. Template layouts use fixed positioning (not responsive) given the fixed output dimensions
7. Natal chart visualization reuses existing NatalChartWheelView rendering capability
8. AI generates share-optimized content during main report generation (no separate on-demand call)

---

## Out of Scope

- Android implementation
- Direct Instagram API integration (posting without share sheet)
- Custom referral/tracking codes per user
- QR code generation on templates
- User photo personalization
- Light mode template variants
- Animated template formats (GIF/MP4)
- A/B testing infrastructure for template variations
- Analytics tracking of share completions and referrals

---

## Dependencies

- Existing NatalChartWheelView for chart rendering
- Existing GeneratedReport model with summary, keyInfluences, recommendations
- Existing BirthDetails model with user information
- iOS share sheet functionality

---

## Review & Acceptance Checklist

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Success criteria are technology-agnostic
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

---

## Execution Status

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities resolved (using reasonable defaults)
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist passed

---
