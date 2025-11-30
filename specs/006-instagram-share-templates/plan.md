# Implementation Plan: Instagram Share Templates

**Branch**: `006-instagram-share-templates` | **Date**: 2024-11-30 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/006-instagram-share-templates/spec.md`

## Summary

Enable users to share their astrological reports on Instagram using 4 professionally designed templates (Chart Only, Key Insights, Recommendations, Full Carousel). The feature extends the existing `GeneratedReport` model with a `ShareContent` structure containing AI-generated condensed content, pre-renders all templates in background when the report loads, and integrates with iOS share sheet for social sharing. Templates are positioned near the existing "Export PDF" button in ReportDetailView.

## Technical Context

| Attribute | Value |
|-----------|-------|
| Language/Version | Swift 5.9 |
| Primary Dependencies | SwiftUI, UIKit (UIGraphicsImageRenderer), CoreGraphics |
| Storage | Temporary file storage for PNG images (iOS temp directory) |
| Testing | XCTest with `#expect` macro, XCUITest for UI flows |
| Target Platform | iOS 17+ |
| Project Type | Mobile (iOS single app) |
| Performance Goals | Pre-render 4 templates within 3s; instant share sheet |
| Constraints | Images <1MB each; Cyrillic support; 1080x1920/1080x1080 px |
| Scale/Scope | Single report view, 4 template types, 8 images total |

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Spec-Driven Delivery | ✅ PASS | spec.md complete with clarifications, plan.md in progress |
| II. SwiftUI Modular Architecture | ✅ PASS | Components in Features/ReportGeneration/, Models in Domain/ |
| III. Test-First Reliability | ✅ PASS | Tests planned for ShareContent, Generator, ViewModel |
| IV. Secure Configuration | ✅ PASS | No secrets; branding uses static values |
| V. Release Quality Discipline | ✅ PASS | Unit tests, UI tests, PR screenshots planned |

---

## Project Structure

### Documentation (this feature)

```
specs/006-instagram-share-templates/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (AI prompt contract)
└── tasks.md             # Phase 2 output (not created by /speckit.plan)
```

### Source Code (repository root)

```
AstroSvitla/
├── Models/
│   └── Domain/
│       └── ShareContent.swift                    # NEW: AI-generated share content
├── Features/
│   └── ReportGeneration/
│       ├── Models/
│       │   └── GeneratedReport.swift             # MODIFY: Add shareContent field
│       ├── Services/
│       │   ├── ReportPDFGenerator.swift          # EXISTING: Reference pattern
│       │   └── InstagramTemplateGenerator.swift  # NEW: Template image generation
│       ├── ViewModels/
│       │   └── InstagramShareViewModel.swift     # NEW: Pre-rendering state
│       └── Views/
│           ├── ReportDetailView.swift            # MODIFY: Add share button
│           ├── InstagramShareSheet.swift         # NEW: Template selection modal
│           ├── InstagramTemplatePreview.swift    # NEW: Template preview
│           └── Templates/
│               ├── ChartOnlyTemplate.swift       # NEW: Stories 9:16
│               ├── KeyInsightsTemplate.swift     # NEW: Post 1:1
│               ├── RecommendationsTemplate.swift # NEW: Stories 9:16
│               └── CarouselTemplates.swift       # NEW: 5-slide carousel
├── Resources/
│   └── Localizable.xcstrings                     # MODIFY: Share strings
└── Shared/
    └── Components/
        └── ZoryaBranding.swift                   # NEW: Brand colors/styles

AstroSvitlaTests/
└── Features/
    └── ReportGeneration/
        ├── ShareContentTests.swift               # NEW
        ├── InstagramTemplateGeneratorTests.swift # NEW
        └── InstagramShareViewModelTests.swift    # NEW

AstroSvitlaUITests/
└── InstagramShareFlowTests.swift                 # NEW
```

**Structure Decision**: Follows existing MVVM pattern in Features/ReportGeneration/. New ShareContent model in Models/Domain/ following existing patterns (BirthDetails, ReportArea). Template views isolated in Templates/ subfolder for organization.

---

## Complexity Tracking

*No constitution violations identified. Feature follows established patterns.*

| Aspect | Approach | Rationale |
|--------|----------|-----------|
| Pre-rendering | Background Task on view appear | Leverage Swift concurrency for non-blocking render |
| Template rendering | UIGraphicsImageRenderer | Standard iOS approach, matches ReportPDFGenerator |
| State management | Dedicated ViewModel | Keeps ReportDetailView clean, testable state |
| Image storage | Temporary directory with cleanup | No persistent cache needed; regenerate on session |

---

## Phases

### Phase 0: Research

**Goal**: Document technical decisions and external dependencies

**Deliverables**:
- `research.md` with decisions on:
  - Template rendering approach (UIGraphicsImageRenderer vs ImageRenderer)
  - Image compression settings for <1MB constraint
  - ShareContent field integration with existing AI prompt system
  - Carousel file packaging strategy for Instagram

**Dependencies**:
- Existing `ReportPDFGenerator.swift` pattern analysis ✅ (completed in context)
- Understanding of AI prompt structure for report generation (in contracts/)

### Phase 1: Design

**Goal**: Define data models, contracts, and integration points

**Deliverables**:
- `data-model.md`:
  - `ShareContent` model with character-limited fields
  - `ShareTemplate` enum for template types
  - `GeneratedShareImage` for rendered output
- `contracts/share-content-prompt.md`:
  - AI prompt contract addendum for `shareContent` generation
- `quickstart.md`:
  - Development setup and testing instructions

**Integration Points**:
- **GeneratedReport.swift**: Add optional `shareContent: ShareContent?` field
- **AI Prompt System**: Extend system prompt to request share-optimized content
- **ReportDetailView.swift**: Add "Instagram Share" button group

### Phase 2: Tasks (not generated by /speckit.plan)

**Note**: Tasks will be generated during `/speckit.tasks` phase. Estimated breakdown:

| Task | Complexity | Dependencies |
|------|------------|--------------|
| Create ShareContent model | Low | None |
| Create ZoryaBranding component | Low | None |
| Extend GeneratedReport with shareContent | Low | ShareContent model |
| Create ChartOnlyTemplate view | Medium | ZoryaBranding |
| Create KeyInsightsTemplate view | Medium | ZoryaBranding, ShareContent |
| Create RecommendationsTemplate view | Medium | ZoryaBranding, ShareContent |
| Create CarouselTemplates views (5) | High | All above |
| Create InstagramTemplateGenerator service | Medium | All template views |
| Create InstagramShareViewModel | Medium | Generator service |
| Create InstagramShareSheet modal | Medium | ViewModel, templates |
| Integrate into ReportDetailView | Low | ShareSheet |
| Add localization strings | Low | None |
| Unit tests for ShareContent | Low | Model complete |
| Unit tests for Generator | Medium | Service complete |
| Integration tests for ViewModel | Medium | All services |
| UI tests for share flow | Medium | All views |
| Update AI prompt for shareContent | Medium | Contract defined |

---

## Key Decisions Log

| Decision | Choice | Rationale | Date |
|----------|--------|-----------|------|
| Content generation timing | With main report | Avoids extra API call, consistent data | Clarify Q1 |
| Content structure | Dedicated `shareContent` field | Clean separation, explicit character limits | Clarify Q2 |
| Localization approach | User's app language | Branding in user's language | Clarify Q3 |
| Rendering timing | Pre-render on report load | Instant share UX | Clarify Q4 |
| Carousel analysis content | AI-generated bullets | 3-4 bullet points, ≤50 chars each | Clarify Q5 |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Template images exceed 1MB | Medium | Low | PNG compression, reduce detail; test complex charts |
| Pre-rendering takes >3s | Low | Medium | Async with progress indicator; prioritize templates |
| ShareContent missing from older reports | High | Low | Graceful fallback to truncated existing content |
| Instagram carousel share limitations | Medium | Medium | Document manual carousel creation workflow |

---

## Testing Strategy

### Unit Tests
- **ShareContentTests**: Validate character limits, encoding, localization
- **InstagramTemplateGeneratorTests**: Verify image dimensions, branding placement
- **InstagramShareViewModelTests**: Test pre-rendering state transitions

### Integration Tests
- End-to-end template generation from GeneratedReport
- Temporary file creation and cleanup

### UI Tests
- Share button visibility and tap response
- Template selection modal navigation
- Share sheet presentation

### Manual Testing Checklist
- [ ] Chart Only template renders correctly with various chart styles
- [ ] Key Insights template displays Cyrillic characters properly
- [ ] Recommendations template handles long/short content gracefully
- [ ] Carousel exports all 5 images with correct naming
- [ ] Share sheet opens Instagram when installed
- [ ] Fallback to Photos app when Instagram unavailable

---

## Related Specifications

- **001-astrosvitla-ios-native**: Base app architecture
- **005-enhance-astrological-report**: Report generation context

---

## Next Steps

1. ✅ Complete plan.md (this document)
2. ✅ Create research.md with technical decisions
3. ✅ Create data-model.md with entity definitions
4. ✅ Create contracts/share-content-prompt.md
5. ✅ Create quickstart.md
6. ✅ Run update-agent-context.sh copilot

---

**Plan Phase Status**: ✅ **COMPLETE**

Ready for `/speckit.tasks` to generate implementation tasks.
