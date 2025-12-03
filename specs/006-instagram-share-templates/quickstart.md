# Quickstart: Instagram Share Templates

**Feature**: 006-instagram-share-templates  
**Date**: November 30, 2024  
**Branch**: `006-instagram-share-templates`

## Overview

This guide covers development setup, testing procedures, and implementation sequence for the Instagram Share Templates feature.

---

## Prerequisites

### Development Environment

- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- iOS 17.0+ Simulator or device
- Swift 5.9

### Repository Setup

```bash
# Clone and checkout feature branch
git clone https://github.com/[org]/AstroSvitla.git
cd AstroSvitla
git checkout 006-instagram-share-templates

# Open project
open AstroSvitla.xcodeproj
```

### Configuration

No additional secrets required. The feature uses existing AI/API configuration from `Config.swift`.

---

## Project Structure

### New Files to Create

```
AstroSvitla/
├── Models/Domain/
│   └── ShareContent.swift              # NEW: ShareContent, ShareTemplateType, etc.
├── Features/ReportGeneration/
│   ├── Services/
│   │   └── InstagramTemplateGenerator.swift  # NEW: Template rendering service
│   ├── ViewModels/
│   │   └── InstagramShareViewModel.swift     # NEW: Pre-rendering state
│   └── Views/
│       ├── InstagramShareSheet.swift         # NEW: Template selection modal
│       ├── InstagramTemplatePreview.swift    # NEW: Template preview
│       └── Templates/
│           ├── ChartOnlyTemplate.swift       # NEW: 9:16 chart template
│           ├── KeyInsightsTemplate.swift     # NEW: 1:1 insights template
│           ├── RecommendationsTemplate.swift # NEW: 9:16 recs template
│           └── CarouselTemplates.swift       # NEW: 5-slide carousel
├── Shared/Components/
│   └── ZoryaBranding.swift                   # NEW: Brand constants
└── Resources/
    └── Localizable.xcstrings                 # MODIFY: Add share strings

AstroSvitlaTests/Features/ReportGeneration/
├── ShareContentTests.swift                   # NEW
├── InstagramTemplateGeneratorTests.swift     # NEW
└── InstagramShareViewModelTests.swift        # NEW

AstroSvitlaUITests/
└── InstagramShareFlowTests.swift             # NEW
```

### Files to Modify

| File | Changes |
|------|---------|
| `GeneratedReport.swift` | Add `shareContent: ShareContent?` field |
| `ReportDetailView.swift` | Add Instagram share button section |
| `Localizable.xcstrings` | Add localization keys for share UI |

---

## Implementation Sequence

Follow this order to minimize dependencies:

### Phase 1: Foundation (Days 1-2)

1. **Create ShareContent model** (`Models/Domain/ShareContent.swift`)
   - Define `ShareContent` struct
   - Define `ShareTemplateType` enum
   - Define `CarouselSlideType` enum
   - Define `GeneratedShareImage` struct
   - Add validation and preview fixtures

2. **Create ZoryaBranding** (`Shared/Components/ZoryaBranding.swift`)
   - Define color constants
   - Define typography scales
   - Add `Color(hex:)` extension

3. **Extend GeneratedReport** (`Features/ReportGeneration/Models/GeneratedReport.swift`)
   - Add optional `shareContent` field
   - Update `CodingKeys` and decoding

### Phase 2: Templates (Days 3-5)

4. **Create ChartOnlyTemplate** (`Features/ReportGeneration/Views/Templates/`)
   - 1080×1920 Stories format
   - Gradient background
   - Natal chart image
   - Name and date overlay
   - Branding footer

5. **Create KeyInsightsTemplate**
   - 1080×1080 Post format
   - Top 3 influences with emoji icons
   - Branding elements

6. **Create RecommendationsTemplate**
   - 1080×1920 Stories format
   - 3 recommendations with icons
   - CTA element

7. **Create CarouselTemplates**
   - 5 separate slide views
   - Cover, Influences, Recommendations, Analysis, CTA
   - Consistent styling across slides

### Phase 3: Rendering Service (Days 6-7)

8. **Create InstagramTemplateGenerator** (`Features/ReportGeneration/Services/`)
   - `ImageRenderer` based rendering
   - PNG export with compression
   - Temp file management
   - Cleanup utilities

9. **Create InstagramShareViewModel** (`Features/ReportGeneration/ViewModels/`)
   - Pre-rendering state machine
   - Background async rendering
   - Error handling

### Phase 4: UI Integration (Days 8-9)

10. **Create InstagramShareSheet** (`Features/ReportGeneration/Views/`)
    - Template selection grid
    - Preview thumbnails
    - Share action handling

11. **Create InstagramTemplatePreview**
    - Full-size template preview
    - Swipe between templates
    - Share button

12. **Integrate into ReportDetailView**
    - Add "Share to Instagram" button group
    - Wire up ViewModel
    - Handle share flow

### Phase 5: Localization & Polish (Day 10)

13. **Add localization strings**
    - English and Ukrainian translations
    - Template names and descriptions
    - Error messages

14. **Update AI prompt**
    - Add `shareContent` generation to system prompt
    - Test with sample requests

---

## Testing Commands

### Run Unit Tests

```bash
# All tests
xcodebuild test \
  -scheme AstroSvitla \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  | xcpretty

# Share feature tests only
xcodebuild test \
  -scheme AstroSvitla \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:AstroSvitlaTests/ShareContentTests \
  -only-testing:AstroSvitlaTests/InstagramTemplateGeneratorTests \
  -only-testing:AstroSvitlaTests/InstagramShareViewModelTests \
  | xcpretty
```

### Run UI Tests

```bash
xcodebuild test \
  -scheme AstroSvitla \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:AstroSvitlaUITests/InstagramShareFlowTests \
  | xcpretty
```

### Validate Prerequisites

```bash
./scripts/check-prerequisites.sh --json
```

---

## Development Tips

### Template Preview

Use SwiftUI Previews for rapid template iteration:

```swift
#Preview("Chart Only Template") {
    ChartOnlyTemplate(
        birthDetails: .preview,
        chartImage: UIImage(named: "sample-chart")!
    )
    .frame(width: 1080, height: 1920)
    .scaleEffect(0.3)  // Fit in preview
}
```

### Testing Image Output

Render templates to files for visual inspection:

```swift
@Test func debugRenderChartOnlyTemplate() async throws {
    let generator = InstagramTemplateGenerator()
    let image = try await generator.renderChartOnly(
        birthDetails: .preview,
        chartImage: UIImage(named: "sample-chart")!
    )
    
    // Save to desktop for inspection
    let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
    let url = desktop.appendingPathComponent("chart-only-test.png")
    try image.pngData()?.write(to: url)
    print("Saved to: \(url.path)")
}
```

### Simulating Share

Test UIActivityViewController without actual sharing:

```swift
// In UI test
let shareButton = app.buttons["share_to_instagram"]
shareButton.tap()

// Wait for share sheet
let shareSheet = app.otherElements["ActivityListView"]
XCTAssertTrue(shareSheet.waitForExistence(timeout: 3))
```

---

## Common Issues

### Template Rendering Slow

**Symptom**: Pre-rendering takes >3 seconds

**Solution**: Ensure rendering happens on background queue with low priority:

```swift
Task(priority: .background) {
    await viewModel.preRender(...)
}
```

### Share Sheet Not Appearing

**Symptom**: `UIActivityViewController` doesn't present

**Solution**: Ensure presentation happens on main thread:

```swift
await MainActor.run {
    viewController.present(activityVC, animated: true)
}
```

### Image Quality Issues

**Symptom**: Templates look pixelated

**Solution**: Check `ImageRenderer.scale` is set to device scale:

```swift
renderer.scale = UIScreen.main.scale  // Should be 3.0
```

### Cyrillic Text Not Rendering

**Symptom**: Ukrainian characters show as boxes

**Solution**: Use system fonts which include Cyrillic:

```swift
.font(.system(size: 24, weight: .semibold))  // ✓ Works
.font(.custom("SomeFont", size: 24))          // ✗ May lack Cyrillic
```

---

## Checklist Before PR

- [ ] All new files follow naming conventions
- [ ] `shareContent` decodes correctly from API response
- [ ] All 4 template types render correctly
- [ ] Carousel generates 5 properly named files
- [ ] Share sheet presents and dismisses cleanly
- [ ] Temp files are cleaned up after sharing
- [ ] English and Ukrainian localizations complete
- [ ] Unit tests pass for ShareContent validation
- [ ] UI tests pass for share flow
- [ ] `./scripts/check-prerequisites.sh` passes
- [ ] Screenshots captured for PR

---

## Related Documentation

- [Specification](./spec.md)
- [Implementation Plan](./plan.md)
- [Research Decisions](./research.md)
- [Data Model](./data-model.md)
- [AI Prompt Contract](./contracts/share-content-prompt.md)

---

**Quickstart Status**: ✅ **COMPLETE**

Ready to begin implementation following the sequence above.
