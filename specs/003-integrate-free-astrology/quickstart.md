# Quickstart Guide: Free Astrology API Integration

**Feature**: Integrate Free Astrology API
**Date**: 2025-10-10
**Purpose**: Manual testing and validation guide

## Prerequisites

1. **API Key**: Sign up at https://freeastrologyapi.com/signup to obtain API key
2. **Xcode 15+**: Required for building iOS app
3. **iOS 17+ Simulator** or device
4. **API Testing Tool**: HTTP client (curl, Postman, or VS Code REST Client extension)

## Setup Steps

### 1. Configure API Credentials

```bash
# Navigate to project root
cd /Users/Ruslan_Popesku/Desktop/AstroSvitla

# Update Config.swift with API key
# Edit: AstroSvitla/Config/Config.swift
```

Add to `Config.swift`:
```swift
static let freeAstrologyAPIKey = ProcessInfo.processInfo.environment["FREE_ASTROLOGY_API_KEY"] ?? "your-api-key-here"
static let freeAstrologyBaseURL = "https://json.freeastrologyapi.com"
```

Update `Config.swift.example`:
```swift
// Free Astrology API Configuration
static let freeAstrologyAPIKey = "your-api-key-here"
static let freeAstrologyBaseURL = "https://json.freeastrologyapi.com"
```

### 2. Verify API Access

Test the API using curl or HTTP client:

```bash
# Test planets endpoint
curl -X POST https://json.freeastrologyapi.com/western/planets \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{
    "year": 1990,
    "month": 5,
    "date": 15,
    "hours": 14,
    "minutes": 30,
    "seconds": 0,
    "latitude": 40.7128,
    "longitude": -74.0060,
    "timezone": -4.0,
    "observation_point": "topocentric",
    "ayanamsha": "tropical"
  }'
```

**Expected**: JSON response with `"status": "success"` and planets array

### 3. Build and Run Tests

```bash
# Build the project
xcodebuild -scheme AstroSvitla \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build

# Run all tests
xcodebuild test \
  -scheme AstroSvitla \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Expected**: All tests pass (existing tests may be skipped if they depend on commented implementations)

## Manual Test Scenarios

### Scenario 1: Generate Complete Natal Chart

**Objective**: Verify all 4 endpoints work and data maps correctly

**Steps**:
1. Launch app in simulator
2. Navigate to chart generation screen
3. Enter test birth data:
   - Date: May 15, 1990
   - Time: 14:30:00
   - Location: New York, NY (40.7128°N, 74.0060°W)
   - Timezone: UTC-4
4. Tap "Generate Chart"

**Expected Results**:
- ✅ Loading indicator appears
- ✅ Chart generates within 5 seconds
- ✅ Chart details screen shows:
  - At least 10 planets with positions
  - Exactly 12 houses with cusps
  - Multiple aspects listed
  - Chart wheel image displays correctly
- ✅ No error messages appear

**Validation**:
- Check planet positions against known ephemeris (e.g., astro.com)
- Verify house cusps match expected Placidus house system
- Confirm aspects make sense (e.g., Sun trine Moon should show ~120° angle)

---

### Scenario 2: Offline Behavior with Cached Chart

**Objective**: Verify cache works when API is unavailable

**Steps**:
1. Generate a chart (as in Scenario 1)
2. Enable Airplane Mode in simulator
3. Close and reopen app
4. Navigate to chart history
5. Select the previously generated chart

**Expected Results**:
- ✅ Chart loads from cache immediately
- ✅ All data displays correctly (planets, houses, aspects, image)
- ✅ No network error appears for cached chart
- ✅ Attempting to generate NEW chart shows appropriate offline message

---

### Scenario 3: Rate Limit Handling

**Objective**: Verify app handles rate limits gracefully

**Steps**:
1. Generate 13+ charts rapidly (exceeds free tier daily limit of 50 requests ÷ 4 per chart)
2. Observe behavior when limit is reached

**Expected Results**:
- ✅ First 12 charts generate successfully
- ✅ 13th chart shows rate limit error: "Request limit reached. Please wait [X] seconds"
- ✅ Retry timer displays countdown
- ✅ After timer expires, generation resumes

**Note**: This test consumes significant API quota. Run sparingly.

---

### Scenario 4: Invalid Input Handling

**Objective**: Verify validation and error handling

**Test Cases**:

**4a. Invalid Date**
- Input: February 30, 1990
- Expected: Validation error before API call

**4b. Invalid Coordinates**
- Input: Latitude 95° (out of range)
- Expected: Validation error or API 400 error with clear message

**4c. Missing API Key**
- Temporarily remove API key from Config.swift
- Expected: Authentication error: "Invalid or missing API key"

---

### Scenario 5: Chart Image Display

**Objective**: Verify SVG chart rendering

**Steps**:
1. Generate chart with default settings
2. Inspect chart wheel image

**Expected Results**:
- ✅ SVG image loads and displays
- ✅ Chart contains recognizable elements:
  - 12 house divisions
  - Zodiac symbols around outer ring
  - Planet glyphs in appropriate positions
  - Aspect lines connecting planets
- ✅ Image is clear and legible
- ✅ Tapping image shows full-screen view

---

### Scenario 6: Different House Systems

**Objective**: Verify house system configuration works

**Steps**:
1. Generate chart with Placidus system (default)
2. Note house cusp degrees
3. Generate same chart with Whole Signs system
4. Compare house cusps

**Expected Results**:
- ✅ Placidus and Whole Signs produce different house cusps
- ✅ Whole Signs cusps align with sign boundaries (0°, 30°, 60°, etc.)
- ✅ No crashes or errors when switching house systems

---

## Validation Checklist

### API Integration
- [ ] All 4 endpoints callable and return valid responses
- [ ] Authentication works with API key header
- [ ] Request parameters correctly formatted
- [ ] Response parsing handles all expected fields

### Data Accuracy
- [ ] Planet positions match reference ephemeris (within 0.1°)
- [ ] House cusps reasonable for given location and time
- [ ] Aspects calculated correctly (angles match aspect types)
- [ ] Retrograde status correct for known retrograde periods

### Error Handling
- [ ] Network errors show user-friendly messages
- [ ] Rate limits enforced and communicated clearly
- [ ] Invalid inputs validated before API calls
- [ ] API errors parsed and displayed appropriately

### Performance
- [ ] Chart generation completes within 5 seconds
- [ ] App remains responsive during API calls
- [ ] Cached charts load instantly
- [ ] No memory leaks or crashes

### UI/UX
- [ ] Loading states clear and informative
- [ ] Chart visualization displays correctly
- [ ] Offline mode degrades gracefully
- [ ] Error messages actionable

## Troubleshooting

### Problem: API returns 401 Unauthorized

**Solution**:
- Verify API key is correct in Config.swift
- Check x-api-key header is being sent
- Ensure API key is active (not expired)

### Problem: Rate limit exceeded

**Solution**:
- Wait until daily limit resets (midnight UTC)
- Upgrade to paid tier if testing extensively
- Use cached charts to avoid redundant API calls

### Problem: Chart image not displaying

**Solution**:
- Check SVG URL is valid and accessible
- Verify image download and caching logic
- Ensure ImageCacheService has write permissions

### Problem: Incorrect planet positions

**Solution**:
- Verify timezone offset is correct (UTC offset, not DST-adjusted)
- Check coordinates are in decimal degrees (not DMS)
- Confirm observation point (topocentric vs geocentric)

## Testing Data

### Test Birth Data 1: John F. Kennedy
- Date: May 29, 1917
- Time: 15:00:00
- Location: Brookline, MA (42.3318°N, 71.1211°W)
- Timezone: UTC-5

### Test Birth Data 2: Princess Diana
- Date: July 1, 1961
- Time: 19:45:00
- Location: Sandringham, UK (52.8304°N, 0.5084°E)
- Timezone: UTC+1

### Test Birth Data 3: Midnight Birth
- Date: January 1, 2000
- Time: 00:00:00
- Location: Sydney, Australia (33.8688°S, 151.2093°E)
- Timezone: UTC+11

## Success Criteria

✅ **Integration Complete**: All manual test scenarios pass
✅ **Data Accurate**: Positions match reference sources within 0.1°
✅ **Performance Met**: Chart generation < 5 seconds
✅ **Errors Handled**: All error scenarios show appropriate messages
✅ **Cache Works**: Offline access to previously generated charts

## Next Steps

After manual testing validation:
1. Run automated test suite: `xcodebuild test -scheme AstroSvitla`
2. Review test coverage: Should cover all critical paths
3. Document any discrepancies between Free Astrology API and Prokerala API
4. Decide whether to proceed with Free Astrology API or revert to previous implementation
5. If proceeding, create implementation tasks with `/tasks` command
