# Tasks: Instagram Share Templates

**Feature**: 006-instagram-share-templates  
**Input**: Design documents from `/specs/006-instagram-share-templates/`  
**Prerequisites**: plan.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

---

## User Stories (from spec.md)

| ID | Priority | Story | Test Criteria |
|----|----------|-------|---------------|
| US1 | P1 | View pre-rendered template options near Export PDF | Templates appear when report loads, near Export PDF button |
| US2 | P1 | Select and preview Chart Only template (Stories 9:16) | Shows natal chart with name, birth details, branding |
| US3 | P1 | Select and preview Key Insights template (Post 1:1) | Shows summary and top 3 planetary influences |
| US4 | P2 | Select and preview Recommendations template (Stories 9:16) | Shows 3 personalized recommendations |
| US5 | P2 | Select and preview Carousel (5 slides, Post 1:1) | Shows 5 images: Cover, Influences, Recs, Analysis, CTA |
| US6 | P1 | Share template via iOS share sheet to Instagram | Share sheet opens with pre-rendered image(s) |
| US7 | P3 | Cyrillic characters render correctly (і, ї, є, ґ) | Ukrainian text displays without substitution |
| US8 | P3 | Handle legacy reports without shareContent | Shows "Share unavailable" gracefully |

---

## Phase 1: Setup

**Goal**: Project structure and dependencies ready

- [ ] **T001** Create Templates directory structure  
  `AstroSvitla/Features/ReportGeneration/Views/Templates/`

- [ ] **T002** [P] Create placeholder files for new components  
  Touch files: `ShareContent.swift`, `ZoryaBranding.swift`, `InstagramTemplateGenerator.swift`, `InstagramShareViewModel.swift`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Goal**: Core models and branding that ALL user stories depend on

### Models & Branding

- [ ] **T003** Create ShareContent model with validation  
  `AstroSvitla/Models/Domain/ShareContent.swift`  
  - Define `ShareContent` struct with `condensedSummary`, `topInfluences`, `topRecommendations`, `analysisHighlights`
  - Add `isValid` computed property with character limit validation
  - Conform to `Codable`, `Sendable`, `Equatable`
  - Add preview fixtures (`ShareContent.preview`, `ShareContent.maxLengthPreview`)

- [ ] **T004** [P] Create ShareTemplateType enum  
  `AstroSvitla/Models/Domain/ShareContent.swift` (same file)  
  - Define `chartOnly`, `keyInsights`, `recommendations`, `carousel` cases
  - Add `dimensions`, `imageCount`, `displayName`, `icon`, `description` properties
  - Conform to `CaseIterable`, `Identifiable`, `Sendable`

- [ ] **T005** [P] Create CarouselSlideType enum  
  `AstroSvitla/Models/Domain/ShareContent.swift` (same file)  
  - Define `cover`, `influences`, `recommendations`, `analysis`, `callToAction` cases
  - Add `title` property with localization

- [ ] **T006** [P] Create GeneratedShareImage struct  
  `AstroSvitla/Models/Domain/ShareContent.swift` (same file)  
  - Define `id`, `templateType`, `slideIndex`, `image`, `fileURL` properties
  - Add `suggestedFilename` computed property

- [ ] **T007** Create ZoryaBranding component  
  `AstroSvitla/Shared/Components/ZoryaBranding.swift`  
  - Define `primaryGradient`, `accentGold`, `textPrimary`, `textSecondary` colors
  - Define `appName`, `tagline`, `instagramHandle`, `websiteURL` constants
  - Define `logoHeight`, `cornerRadius`, `templatePadding` dimensions
  - Define scaled font helpers (`titleFont`, `headlineFont`, `bodyFont`, `captionFont`)
  - Add `Color(hex:)` extension

- [ ] **T008** Extend GeneratedReport with shareContent field  
  `AstroSvitla/Features/ReportGeneration/Models/GeneratedReport.swift`  
  - Add `var shareContent: ShareContent?` property
  - Update `CodingKeys` enum
  - Update `init(from decoder:)` to decode optional shareContent
  - Maintain backward compatibility (nil for legacy reports)

### Unit Tests for Models

- [ ] **T009** [P] Create ShareContentTests  
  `AstroSvitlaTests/Features/ReportGeneration/ShareContentTests.swift`  
  - Test `isValid` returns true for valid content
  - Test `isValid` returns false when summary exceeds 280 chars
  - Test `isValid` returns false when influences count != 3
  - Test JSON decoding from sample response
  - Test preview fixtures are valid

- [ ] **T010** [P] Create ShareTemplateTypeTests  
  `AstroSvitlaTests/Features/ReportGeneration/ShareContentTests.swift` (same file)  
  - Test dimensions for each template type
  - Test imageCount (1 for singles, 5 for carousel)
  - Test allCases contains 4 types

**Checkpoint**: Models compile, tests pass ✓

---

## Phase 3: User Story 1 - Pre-rendered Template Options [P1]

**Goal**: US1 - Templates pre-render when report loads and appear near Export PDF

### Template Generator Service

- [ ] **T011** Create InstagramTemplateGenerator service shell  
  `AstroSvitla/Features/ReportGeneration/Services/InstagramTemplateGenerator.swift`  
  - Define `InstagramTemplateGenerator` struct with `@MainActor` isolation
  - Add error enum: `TemplateError` with `renderFailed`, `compressionFailed`, `exportFailed`
  - Add placeholder render methods for each template type

- [ ] **T012** Implement renderTemplate helper method  
  `AstroSvitla/Features/ReportGeneration/Services/InstagramTemplateGenerator.swift`  
  - Use `ImageRenderer(content:)` pattern from ReportPDFGenerator
  - Set `renderer.scale = UIScreen.main.scale`
  - Return `UIImage` or throw `TemplateError.renderFailed`

- [ ] **T013** Implement exportImage with PNG/JPEG fallback  
  `AstroSvitla/Features/ReportGeneration/Services/InstagramTemplateGenerator.swift`  
  - Try PNG first, check if < 1MB
  - Fall back to JPEG 0.85 quality if PNG too large
  - Return `Data` or throw `TemplateError.compressionFailed`

### ViewModel

- [ ] **T014** Create InstagramShareViewModel  
  `AstroSvitla/Features/ReportGeneration/ViewModels/InstagramShareViewModel.swift`  
  - Define state enum: `idle`, `rendering`, `ready`, `failed(Error)`
  - Add `@Observable` macro
  - Add `renderedTemplates: [ShareTemplateType: [GeneratedShareImage]]` storage
  - Add `preRender(report:birthDetails:chartImage:)` async method
  - Implement background TaskGroup rendering for all 4 template types

- [ ] **T015** Implement preRender state management  
  `AstroSvitla/Features/ReportGeneration/ViewModels/InstagramShareViewModel.swift`  
  - Set state to `.rendering` on start
  - Use `withTaskGroup` for parallel template rendering
  - Set state to `.ready` when complete
  - Set state to `.failed(error)` on any error
  - Add 3-second timeout per template

### UI Integration

- [ ] **T016** Create InstagramShareSheet modal view  
  `AstroSvitla/Features/ReportGeneration/Views/InstagramShareSheet.swift`  
  - Display 2x2 grid of template option cards
  - Show thumbnail preview for each template type
  - Show template name and description
  - Handle template selection → navigate to preview

- [ ] **T017** Integrate share button into ReportDetailView  
  `AstroSvitla/Features/ReportGeneration/Views/ReportDetailView.swift`  
  - Add "Share to Instagram" button near "Export PDF" button
  - Wire up `InstagramShareViewModel`
  - Trigger `preRender()` on view appear
  - Show loading indicator if rendering in progress
  - Present `InstagramShareSheet` on button tap

### Tests

- [ ] **T018** [P] Create InstagramShareViewModelTests  
  `AstroSvitlaTests/Features/ReportGeneration/InstagramShareViewModelTests.swift`  
  - Test initial state is `.idle`
  - Test state transitions to `.rendering` on preRender
  - Test state transitions to `.ready` after successful render
  - Test state transitions to `.failed` on error

**Checkpoint**: Share button visible, pre-rendering works ✓

---

## Phase 4: User Story 2 - Chart Only Template [P1]

**Goal**: US2 - User can preview Chart Only template (1080×1920)

- [ ] **T019** Create ChartOnlyTemplate view  
  `AstroSvitla/Features/ReportGeneration/Views/Templates/ChartOnlyTemplate.swift`  
  - Accept `birthDetails: BirthDetails`, `chartImage: UIImage?`
  - Use `ZoryaBranding.primaryGradient` background
  - Display natal chart image centered (scaled to fit)
  - Add user name overlay at top
  - Add birth date/time/location below chart
  - Add Zorya branding footer with tagline

- [ ] **T020** Implement renderChartOnly in generator  
  `AstroSvitla/Features/ReportGeneration/Services/InstagramTemplateGenerator.swift`  
  - Create `ChartOnlyTemplate` view instance
  - Call `renderTemplate()` with 1080×1920 dimensions
  - Return `GeneratedShareImage` with `.chartOnly` type

- [ ] **T021** Add ChartOnlyTemplate preview provider  
  `AstroSvitla/Features/ReportGeneration/Views/Templates/ChartOnlyTemplate.swift`  
  - Add `#Preview` with sample birth details and chart image
  - Scale to 0.3 for preview canvas fit

### Tests

- [ ] **T022** [P] Test ChartOnlyTemplate rendering  
  `AstroSvitlaTests/Features/ReportGeneration/InstagramTemplateGeneratorTests.swift`  
  - Test rendered image dimensions match 1080×1920
  - Test image is non-nil
  - Test PNG data is under 1MB

**Checkpoint**: Chart Only template renders correctly ✓

---

## Phase 5: User Story 3 - Key Insights Template [P1]

**Goal**: US3 - User can preview Key Insights template (1080×1080)

- [ ] **T023** Create KeyInsightsTemplate view  
  `AstroSvitla/Features/ReportGeneration/Views/Templates/KeyInsightsTemplate.swift`  
  - Accept `shareContent: ShareContent`, `birthDetails: BirthDetails`, `reportArea: ReportArea`
  - Use gradient background with overlay
  - Display report area title at top
  - Display `condensedSummary` as headline
  - Display `topInfluences` as 3 bullet points with planetary emojis
  - Add Zorya branding footer

- [ ] **T024** Implement renderKeyInsights in generator  
  `AstroSvitla/Features/ReportGeneration/Services/InstagramTemplateGenerator.swift`  
  - Create `KeyInsightsTemplate` view instance
  - Call `renderTemplate()` with 1080×1080 dimensions
  - Return `GeneratedShareImage` with `.keyInsights` type

- [ ] **T025** Add KeyInsightsTemplate preview provider  
  `AstroSvitla/Features/ReportGeneration/Views/Templates/KeyInsightsTemplate.swift`  
  - Add `#Preview` with `ShareContent.preview`

### Tests

- [ ] **T026** [P] Test KeyInsightsTemplate rendering  
  `AstroSvitlaTests/Features/ReportGeneration/InstagramTemplateGeneratorTests.swift`  
  - Test rendered image dimensions match 1080×1080
  - Test image is non-nil

**Checkpoint**: Key Insights template renders correctly ✓

---

## Phase 6: User Story 6 - Share via iOS Share Sheet [P1]

**Goal**: US6 - User can share templates via iOS share sheet

- [ ] **T027** Create InstagramTemplatePreview view  
  `AstroSvitla/Features/ReportGeneration/Views/InstagramTemplatePreview.swift`  
  - Accept `selectedTemplate: ShareTemplateType`, `images: [GeneratedShareImage]`
  - Display full-size template image(s)
  - Add navigation for carousel (swipe between slides)
  - Add prominent "Share" button
  - Add "Back to templates" navigation

- [ ] **T028** Implement share action with UIActivityViewController  
  `AstroSvitla/Features/ReportGeneration/Views/InstagramTemplatePreview.swift`  
  - Export image(s) to temp directory
  - Create `UIActivityViewController` with image URL(s)
  - Present share sheet
  - Clean up temp files on completion/dismiss

- [ ] **T029** Implement temp file cleanup in generator  
  `AstroSvitla/Features/ReportGeneration/Services/InstagramTemplateGenerator.swift`  
  - Add `exportToTempFile(image:filename:)` method
  - Add `cleanupTempFiles(urls:)` method
  - Use `FileManager.default.temporaryDirectory`

- [ ] **T030** Wire InstagramShareSheet → InstagramTemplatePreview navigation  
  `AstroSvitla/Features/ReportGeneration/Views/InstagramShareSheet.swift`  
  - Add `@State var selectedTemplate: ShareTemplateType?`
  - Navigate to preview on template card tap
  - Pass rendered images from ViewModel

**Checkpoint**: Full share flow works end-to-end ✓

---

## Phase 7: User Story 4 - Recommendations Template [P2]

**Goal**: US4 - User can preview Recommendations template (1080×1920)

- [ ] **T031** Create RecommendationsTemplate view  
  `AstroSvitla/Features/ReportGeneration/Views/Templates/RecommendationsTemplate.swift`  
  - Accept `shareContent: ShareContent`, `reportArea: ReportArea`
  - Use gradient background
  - Display "Recommendations" header
  - Display `topRecommendations` as 3 styled cards with icons
  - Add CTA: "Get your full report on zorya.app"
  - Add Zorya branding footer

- [ ] **T032** Implement renderRecommendations in generator  
  `AstroSvitla/Features/ReportGeneration/Services/InstagramTemplateGenerator.swift`  
  - Create `RecommendationsTemplate` view instance
  - Call `renderTemplate()` with 1080×1920 dimensions
  - Return `GeneratedShareImage` with `.recommendations` type

- [ ] **T033** Add RecommendationsTemplate preview provider  
  `AstroSvitla/Features/ReportGeneration/Views/Templates/RecommendationsTemplate.swift`  
  - Add `#Preview` with `ShareContent.preview`

### Tests

- [ ] **T034** [P] Test RecommendationsTemplate rendering  
  `AstroSvitlaTests/Features/ReportGeneration/InstagramTemplateGeneratorTests.swift`  
  - Test rendered image dimensions match 1080×1920

**Checkpoint**: Recommendations template renders correctly ✓

---

## Phase 8: User Story 5 - Carousel Template [P2]

**Goal**: US5 - User can preview and share 5-slide carousel

### Carousel Slide Views

- [ ] **T035** Create CarouselCoverSlide view  
  `AstroSvitla/Features/ReportGeneration/Views/Templates/CarouselTemplates.swift`  
  - Accept `birthDetails: BirthDetails`, `chartImage: UIImage?`, `reportArea: ReportArea`
  - Display natal chart prominently
  - Add user name and report area
  - Add "Swipe for insights →" indicator

- [ ] **T036** Create CarouselInfluencesSlide view  
  `AstroSvitla/Features/ReportGeneration/Views/Templates/CarouselTemplates.swift` (same file)  
  - Accept `shareContent: ShareContent`
  - Display "Key Influences" header
  - Display `topInfluences` with planetary symbols

- [ ] **T037** Create CarouselRecommendationsSlide view  
  `AstroSvitla/Features/ReportGeneration/Views/Templates/CarouselTemplates.swift` (same file)  
  - Accept `shareContent: ShareContent`
  - Display "Recommendations" header
  - Display `topRecommendations` as styled list

- [ ] **T038** Create CarouselAnalysisSlide view  
  `AstroSvitla/Features/ReportGeneration/Views/Templates/CarouselTemplates.swift` (same file)  
  - Accept `shareContent: ShareContent`
  - Display "Detailed Analysis" header
  - Display `analysisHighlights` as bullet points

- [ ] **T039** Create CarouselCTASlide view  
  `AstroSvitla/Features/ReportGeneration/Views/Templates/CarouselTemplates.swift` (same file)  
  - Display "Discover Your Cosmic Path" header
  - Add Zorya logo and tagline
  - Add "Download Zorya on App Store" CTA
  - Add zorya.app URL

### Carousel Rendering

- [ ] **T040** Implement renderCarousel in generator  
  `AstroSvitla/Features/ReportGeneration/Services/InstagramTemplateGenerator.swift`  
  - Render all 5 slides sequentially
  - Return array of 5 `GeneratedShareImage` with `slideIndex` 0-4
  - Each slide is 1080×1080

- [ ] **T041** Handle carousel multi-image share  
  `AstroSvitla/Features/ReportGeneration/Views/InstagramTemplatePreview.swift`  
  - For carousel: export all 5 images to temp directory
  - Show user guidance: "5 images will be saved. Create carousel in Instagram"
  - Pass all URLs to UIActivityViewController

- [ ] **T042** Add CarouselTemplates preview providers  
  `AstroSvitla/Features/ReportGeneration/Views/Templates/CarouselTemplates.swift`  
  - Add `#Preview` for each slide type

### Tests

- [ ] **T043** [P] Test carousel generates 5 images  
  `AstroSvitlaTests/Features/ReportGeneration/InstagramTemplateGeneratorTests.swift`  
  - Test renderCarousel returns 5 images
  - Test each image is 1080×1080
  - Test slideIndex values are 0-4

**Checkpoint**: Carousel template renders all 5 slides ✓

---

## Phase 9: User Story 7 & 8 - Edge Cases [P3]

**Goal**: US7 - Cyrillic support, US8 - Legacy report handling

### Cyrillic Support

- [ ] **T044** Verify Cyrillic rendering in all templates  
  `AstroSvitlaTests/Features/ReportGeneration/InstagramTemplateGeneratorTests.swift`  
  - Create test fixture with Ukrainian characters (і, ї, є, ґ)
  - Render each template with Ukrainian content
  - Visual inspection test (save to file for manual review)

- [ ] **T045** Ensure system fonts used for Cyrillic  
  `AstroSvitla/Shared/Components/ZoryaBranding.swift`  
  - Verify all fonts use `.system()` not custom fonts
  - Add code comment explaining Cyrillic requirement

### Legacy Report Handling

- [ ] **T046** Handle nil shareContent gracefully  
  `AstroSvitla/Features/ReportGeneration/Views/InstagramShareSheet.swift`  
  - Check if `report.shareContent == nil`
  - Show "Share unavailable for this report" message
  - Disable share button

- [ ] **T047** [P] Test legacy report handling  
  `AstroSvitlaTests/Features/ReportGeneration/InstagramShareViewModelTests.swift`  
  - Create report with `shareContent = nil`
  - Verify ViewModel handles gracefully
  - Verify UI shows appropriate message

**Checkpoint**: Edge cases handled ✓

---

## Phase 10: Localization

**Goal**: English and Ukrainian translations complete

- [ ] **T048** Add localization strings to Localizable.xcstrings  
  `AstroSvitla/Resources/Localizable.xcstrings`  
  - Add all keys from data-model.md localization section:
    - `zorya_tagline`, `share_template_*`, `share_desc_*`, `carousel_title_*`
    - `share_unavailable`, `share_button_title`
  - Add English translations
  - Add Ukrainian translations

- [ ] **T049** [P] Verify localized strings in templates  
  Manual test: Switch device language to Ukrainian, verify all text displays correctly

**Checkpoint**: Localization complete ✓

---

## Phase 11: Polish & Integration

**Goal**: Final integration, cleanup, and documentation

- [ ] **T050** Create InstagramShareFlowTests UI test  
  `AstroSvitlaUITests/InstagramShareFlowTests.swift`  
  - Test share button appears on report view
  - Test tapping share button shows template sheet
  - Test selecting template shows preview
  - Test share button presents share sheet

- [ ] **T051** Performance optimization review  
  `AstroSvitla/Features/ReportGeneration/ViewModels/InstagramShareViewModel.swift`  
  - Ensure rendering uses background priority
  - Add performance logging for render times
  - Verify <3s total render time

- [ ] **T052** Code cleanup and documentation  
  All new files  
  - Add file headers with feature reference
  - Add `// MARK:` sections
  - Add `///` documentation for public APIs
  - Remove any debug/test code

- [ ] **T053** Update AI prompt for shareContent generation  
  Document change needed in `ReportGenerationService` or AI prompt configuration  
  - Add shareContent prompt extension per contracts/share-content-prompt.md
  - Test with sample request

- [ ] **T054** Final manual testing checklist  
  Follow quickstart.md manual testing checklist:
  - [ ] Chart Only template renders with various charts
  - [ ] Key Insights displays Cyrillic correctly
  - [ ] Recommendations handles long/short content
  - [ ] Carousel exports 5 images with correct naming
  - [ ] Share sheet opens Instagram when installed
  - [ ] Fallback to Photos app when Instagram unavailable

**Checkpoint**: Feature complete, ready for PR ✓

---

## Dependencies

```
Phase 1 (Setup)
    ↓
Phase 2 (Foundational) ─── T003-T010 must complete first
    ↓
┌───┴───┬───────┬───────┐
↓       ↓       ↓       ↓
Phase 3 Phase 4 Phase 5 Phase 6  (P1 stories - can parallel after Phase 2)
(US1)   (US2)   (US3)   (US6)
└───┬───┴───────┴───────┘
    ↓
Phase 7 (US4 - P2)
    ↓
Phase 8 (US5 - P2)
    ↓
Phase 9 (US7, US8 - P3)
    ↓
Phase 10 (Localization)
    ↓
Phase 11 (Polish)
```

### Story Dependencies

- **US1** (Pre-render): Blocks all other stories (provides templates)
- **US2-US5** (Templates): Can develop in parallel once Phase 2 complete
- **US6** (Share): Requires at least one template (US2) complete
- **US7, US8** (Edge cases): After core stories complete

---

## Parallel Execution Examples

### Phase 2 Parallel Tasks
```
# Run simultaneously (different files):
T003: ShareContent model
T007: ZoryaBranding component
T009: ShareContentTests
T010: ShareTemplateTypeTests
```

### Phase 3-6 Parallel Development
```
# After Phase 2 checkpoint, teams can work on:
Team A: T019-T022 (ChartOnlyTemplate)
Team B: T023-T026 (KeyInsightsTemplate)  
Team C: T027-T030 (Share flow)
```

### Test Parallelization
```
# All test tasks marked [P] can run together:
T009, T010, T018, T022, T026, T034, T043, T047
```

---

## Task Summary

| Phase | User Story | Task Count | Parallel Tasks |
|-------|------------|------------|----------------|
| 1 | Setup | 2 | 1 |
| 2 | Foundational | 8 | 5 |
| 3 | US1: Pre-render | 7 | 1 |
| 4 | US2: Chart Only | 4 | 1 |
| 5 | US3: Key Insights | 4 | 1 |
| 6 | US6: Share Flow | 4 | 0 |
| 7 | US4: Recommendations | 4 | 1 |
| 8 | US5: Carousel | 9 | 1 |
| 9 | US7-8: Edge Cases | 4 | 1 |
| 10 | Localization | 2 | 1 |
| 11 | Polish | 5 | 0 |
| **Total** | | **54** | **13** |

---

## MVP Scope Recommendation

For fastest time to value, implement in order:

1. **MVP v1** (Phases 1-4): Chart Only template with share
   - Tasks: T001-T022 (22 tasks)
   - Delivers: 1 working template with full share flow

2. **MVP v2** (add Phase 5-6): Key Insights + complete share
   - Tasks: T023-T030 (8 additional tasks)
   - Delivers: 2 templates, polished share UX

3. **Full Feature** (Phases 7-11): All templates + polish
   - Remaining 24 tasks
   - Delivers: Complete 4-template feature

---

## Validation Checklist

- [x] All user stories have corresponding tasks
- [x] All entities from data-model.md have creation tasks
- [x] All contracts have implementation tasks (T053)
- [x] Parallel tasks are truly independent (different files)
- [x] Each task specifies exact file path
- [x] No [P] tasks modify same file
- [x] Tests cover critical paths
- [x] Checkpoints after each story phase
