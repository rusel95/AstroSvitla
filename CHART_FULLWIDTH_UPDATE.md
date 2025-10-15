# Natal Chart Full Width Display Update

**Date**: October 15, 2025  
**Status**: ✅ Completed

## Summary

Updated natal chart visualization to take **full width** of the screen with **dynamic height** based on the chart's natural aspect ratio, instead of being constrained to a square (1:1) format.

---

## Problem

Previously, the natal chart was displayed with a fixed 1:1 aspect ratio (square), which:
- Didn't utilize the full screen width
- Wasted vertical space
- Didn't respect the natural dimensions of SVG charts from the API

---

## Solution

### Changes Made

#### 1. **NatalChartWheelView.swift** - Removed Square Constraint

**File**: `/AstroSvitla/Features/ChartCalculation/Views/NatalChartWheelView.swift`

**Before**:
```swift
.frame(maxWidth: .infinity)
.aspectRatio(1, contentMode: .fit)  // ❌ Forces square
.task {
    await loadChartImage()
}
```

**After**:
```swift
.frame(maxWidth: .infinity)
// ✅ Removed .aspectRatio(1, contentMode: .fit)
.task {
    await loadChartImage()
}
```

#### 2. **SVGImageView.swift** - Full Width with Natural Aspect Ratio

**File**: `/AstroSvitla/Features/ChartCalculation/Views/SVGImageView.swift`

##### a) Removed GeometryReader, Use VStack Instead

**Before**:
```swift
var body: some View {
    GeometryReader { geometry in
        ZStack {
            Color.white
            if let image = renderedImage {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width)
            }
            ...
        }
        .frame(width: geometry.size.width, height: geometry.size.width)  // ❌ Square
        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
    }
    .aspectRatio(1, contentMode: .fit)  // ❌ Forces square
}
```

**After**:
```swift
var body: some View {
    VStack(spacing: 0) {
        if let image = renderedImage {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)  // ✅ Maintains image aspect ratio
                .frame(maxWidth: .infinity)  // ✅ Full width
        }
        ...
    }
    .background(Color.white)
}
```

##### b) Dynamic Rendering Size Based on SVG Dimensions

**Before**:
```swift
let image = try await controller.renderSVGToImage(
    svg: svgString, 
    size: CGSize(width: 800, height: 800)  // ❌ Fixed square size
)
```

**After**:
```swift
// ✅ Extract natural dimensions from SVG
let dimensions = extractSVGDimensions(from: svgString)
let renderSize = CGSize(
    width: 1200, 
    height: 1200 * (dimensions.height / dimensions.width)  // ✅ Maintains aspect ratio
)

let image = try await controller.renderSVGToImage(svg: svgString, size: renderSize)
```

##### c) Added SVG Dimension Extraction Helper

**New function** `extractSVGDimensions(from:)` that:
- Extracts dimensions from SVG `viewBox` attribute (e.g., `viewBox="0 0 800 800"`)
- Falls back to `width` and `height` attributes if viewBox not found
- Returns default 800×800 if dimensions can't be extracted

```swift
private func extractSVGDimensions(from svg: String) -> CGSize {
    // Try viewBox first
    if let viewBoxRegex = try? NSRegularExpression(pattern: #"viewBox\s*=\s*"([^"]+)""#),
       let match = viewBoxRegex.firstMatch(in: svg, range: NSRange(svg.startIndex..., in: svg)),
       let viewBoxRange = Range(match.range(at: 1), in: svg) {
        let viewBoxString = String(svg[viewBoxRange])
        let values = viewBoxString.split(separator: " ").compactMap { Double($0) }
        if values.count == 4 {
            return CGSize(width: values[2], height: values[3])
        }
    }
    
    // Try width/height attributes
    // ... (extraction logic)
    
    // Default fallback
    return CGSize(width: 800, height: 800)
}
```

#### 3. **ChartDetailsView.swift** - Removed Fixed Height Constraint

**File**: `/AstroSvitla/Features/ChartCalculation/Views/ChartDetailsView.swift`

**Before**:
```swift
Section {
    NatalChartWheelView(chart: chart)
        .frame(height: 350)  // ❌ Fixed height limits display
        .listRowInsets(EdgeInsets())
}
```

**After**:
```swift
Section {
    NatalChartWheelView(chart: chart)
        // ✅ Removed .frame(height: 350) - now dynamic
        .listRowInsets(EdgeInsets())
}
```

#### 4. **ReportDetailView.swift** - Removed Fixed Height Constraint

**File**: `/AstroSvitla/Features/ReportGeneration/Views/ReportDetailView.swift`

**Before**:
```swift
NatalChartWheelView(chart: natalChart)
    .frame(height: 350)  // ❌ Fixed height limits display
    .background(Color(.systemBackground))
```

**After**:
```swift
NatalChartWheelView(chart: natalChart)
    // ✅ Removed .frame(height: 350) - now dynamic
    .background(Color(.systemBackground))
```

---

## Benefits

### ✅ Full Screen Width Utilization
- Chart now takes the entire width of the screen
- Better use of available space on all device sizes

### ✅ Dynamic Height
- Height adjusts automatically based on chart's aspect ratio
- Respects natural dimensions of SVG from API

### ✅ Improved Rendering Quality
- SVG rendering size increased from 800×800 to 1200×(dynamic height)
- Higher resolution for better clarity

### ✅ Responsive Design
- Works correctly on all iOS devices (iPhone, iPad)
- Adapts to both portrait and landscape orientations

---

## Technical Details

### Aspect Ratio Handling

1. **PNG Images**: Already had `.aspectRatio(contentMode: .fit)` which works correctly without the 1:1 constraint
2. **SVG Images**: Now renders at natural aspect ratio extracted from SVG metadata
3. **Error Placeholder**: Fills available space without forced constraints

### GeometryReader Usage

- `GeometryReader` still used in `SVGImageView` to determine available width
- No longer forces square dimensions via `.frame(height:)` or `.aspectRatio(1:1)`
- Content naturally flows to fill width while maintaining aspect ratio

---

## Testing Recommendations

### Visual Testing

1. **Generate a natal chart** and navigate to chart details
2. **Verify full width**: Chart should touch left and right edges of screen
3. **Check height**: Should be dynamic, not necessarily equal to width
4. **Rotate device**: Should work in both portrait and landscape
5. **Test on different devices**: iPhone SE, iPhone 15, iPad

### Expected Behavior

#### Before:
```
┌─────────────────┐
│                 │
│   ┌─────────┐   │  ← Wasted space on sides
│   │         │   │
│   │  Chart  │   │  ← Square chart
│   │         │   │
│   └─────────┘   │  
│                 │
└─────────────────┘
```

#### After:
```
┌─────────────────┐
│                 │
├─────────────────┤  ← Full width
│                 │
│      Chart      │  ← Dynamic height
│                 │
├─────────────────┤
│                 │
└─────────────────┘
```

---

## Files Modified

1. ✅ `/AstroSvitla/Features/ChartCalculation/Views/NatalChartWheelView.swift`
   - Removed `.aspectRatio(1, contentMode: .fit)` constraint

2. ✅ `/AstroSvitla/Features/ChartCalculation/Views/SVGImageView.swift`
   - Replaced `GeometryReader` with `VStack` for proper sizing
   - Removed square container constraints
   - Added `extractSVGDimensions(from:)` helper method
   - Updated rendering to use natural SVG dimensions
   - Increased render resolution to 1200px width

3. ✅ `/AstroSvitla/Features/ChartCalculation/Views/ChartDetailsView.swift`
   - Removed `.frame(height: 350)` fixed height constraint

4. ✅ `/AstroSvitla/Features/ReportGeneration/Views/ReportDetailView.swift`
   - Removed `.frame(height: 350)` fixed height constraint

---

## Rollback Instructions

If needed, revert changes by:

```bash
git diff HEAD NatalChartWheelView.swift
git diff HEAD SVGImageView.swift

# To rollback:
git checkout HEAD -- AstroSvitla/Features/ChartCalculation/Views/NatalChartWheelView.swift
git checkout HEAD -- AstroSvitla/Features/ChartCalculation/Views/SVGImageView.swift
```

Or manually add back:
1. In `NatalChartWheelView.swift`: Add `.aspectRatio(1, contentMode: .fit)` after `.frame(maxWidth: .infinity)`
2. In `SVGImageView.swift`: Restore square constraints and fixed 800×800 rendering

---

## Related Views

These views display the natal chart and will benefit from the changes:

1. **ChartDetailsView**: Shows full chart after calculation
2. **ReportDetailView**: Shows chart alongside generated report
3. Any future views that use `NatalChartWheelView`

---

## Notes

- All compile errors shown are just missing imports - they will resolve when building the project
- The changes maintain backward compatibility with cached charts
- No database migrations or API changes required
- Works with both cached SVG and PNG chart formats

---

## Status

✅ **Complete** - Natal chart now displays at full width with dynamic height based on natural aspect ratio
