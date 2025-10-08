# QuickStart Guide: AstroSvitla iOS Development

**Feature**: AstroSvitla - iOS Natal Chart & AI Predictions App
**Branch**: `001-astrosvitla-ios-native`
**Platform**: iOS 17.0+, Xcode 16+, Swift 6.0

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Dependencies](#dependencies)
4. [Configuration](#configuration)
5. [Running the App](#running-the-app)
6. [Development Workflow](#development-workflow)
7. [Testing](#testing)
8. [Common Issues](#common-issues)

---

## Prerequisites

### Required Software

| Tool | Version | Download |
|------|---------|----------|
| macOS | 14.0+ (Sonoma) | - |
| Xcode | 16.0+ | [App Store](https://apps.apple.com/app/xcode/id497799835) |
| Swift | 6.0+ | Included with Xcode |
| Git | 2.x+ | `brew install git` |

### Optional Tools

- **SwiftLint**: Code linting (recommended)
  ```bash
  brew install swiftlint
  ```

- **SwiftFormat**: Code formatting (recommended)
  ```bash
  brew install swiftformat
  ```

### Required Accounts

1. **Apple Developer Account** (for device testing & App Store)
   - Free account OK for development
   - Paid account ($99/year) required for distribution

2. **Google AI API Key** (for Gemini integration)
   - Sign up at: https://ai.google.dev/
   - Free tier: 15 RPM, 1M requests/day

3. **SwissEphemeris Commercial License** (for production)
   - Cost: CHF 750 (~$850 USD)
   - Purchase: https://www.astro.com/swisseph/swephprice_e.htm
   - Note: GPL license OK for development/testing

---

## Initial Setup

### 1. Clone Repository

```bash
git clone https://github.com/your-org/AstroSvitla.git
cd AstroSvitla
```

### 2. Checkout Feature Branch

```bash
git checkout 001-astrosvitla-ios-native
```

### 3. Open in Xcode

```bash
open AstroSvitla.xcodeproj
```

---

## Dependencies

### Swift Package Manager (SPM)

The project uses SPM for all dependencies. Xcode will automatically fetch them on first build.

**Current Dependencies**:

1. **SwissEphemeris** (Astronomical Calculations)
   - Repository: `https://github.com/vsmithers1087/SwissEphemeris`
   - Version: 0.0.99
   - License: GPL-2.0+ (commercial license required for production)

2. **GoogleGenerativeAI** (AI Report Generation)
   - Repository: `https://github.com/google/generative-ai-swift`
   - Version: Latest
   - License: Apache 2.0

### Manual Dependency Installation (if needed)

If SPM fails to fetch automatically:

1. In Xcode: File → Add Package Dependencies
2. Enter repository URL
3. Select version/branch
4. Add to target: AstroSvitla

---

## Configuration

### 1. API Keys Setup

Create a `.env` file in project root (gitignored):

```bash
# .env
GEMINI_API_KEY=your_gemini_api_key_here
```

**Get Gemini API Key**:
1. Visit https://makersuite.google.com/app/apikey
2. Click "Create API Key"
3. Copy key and paste into `.env`

### 2. Xcode Configuration

Create `Config.xcconfig` in project root:

```bash
# Config.xcconfig
GEMINI_API_KEY = $(GEMINI_API_KEY)
PRODUCT_BUNDLE_IDENTIFIER = com.astrosvitla.astroinsight
DEVELOPMENT_TEAM = YOUR_TEAM_ID
```

**Link Configuration**:
1. Open Xcode project settings
2. Select "AstroSvitla" project
3. Info tab → Configurations
4. Set `Config.xcconfig` for Debug and Release

### 3. Bundle Identifier & Team

Update in Xcode:
1. Select AstroSvitla target
2. Signing & Capabilities tab
3. Team: Select your Apple Developer account
4. Bundle Identifier: `com.astrosvitla.astroinsight`

### 4. SwissEphemeris Initialization

Already configured in `AstroSvitlaApp.swift`:

```swift
@main
struct AstroSvitlaApp: App {
    init() {
        // Set ephemeris path (required before calculations)
        JPLFileManager.setEphemerisPath()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [User.self, BirthChart.self, ReportPurchase.self])
    }
}
```

---

## Running the App

### Build & Run (Simulator)

1. Select simulator: iPhone 15 Pro (or newer)
2. Press `Cmd + R` or click ▶️ Play button
3. App launches in simulator

**Minimum iOS version**: iOS 17.0

### Build & Run (Physical Device)

1. Connect iPhone via USB
2. Trust computer on device
3. Select device in Xcode
4. Press `Cmd + R`
5. Trust developer certificate on device (Settings → General → Device Management)

**Note**: Free Apple Developer accounts limited to 3 devices, 7-day certificates.

---

## Development Workflow

### Project Structure

```
AstroSvitla/
├── AstroSvitla/                 # Main app target
│   ├── App/
│   │   └── AstroSvitlaApp.swift # App entry point
│   ├── Features/                # Feature modules
│   │   ├── Onboarding/
│   │   ├── BirthData/
│   │   ├── ChartCalculation/
│   │   ├── LifeAreaSelection/
│   │   ├── ReportPurchase/
│   │   ├── ReportViewing/
│   │   └── ChartManagement/
│   ├── Core/                    # Shared code
│   │   ├── Models/              # Domain models
│   │   ├── Services/            # Business logic
│   │   ├── Persistence/         # SwiftData
│   │   └── Utilities/
│   ├── UI/                      # Reusable UI
│   │   ├── Components/
│   │   └── Styles/
│   └── Resources/
│       ├── Localizable.xcstrings # Localization
│       ├── Assets.xcassets       # Images/colors
│       └── AstrologyRules.json   # Expert rules
│
├── AstroSvitlaTests/            # Unit tests
├── AstroSvitlaUITests/          # UI tests
└── specs/                       # Documentation
    └── 001-astrosvitla-ios-native/
        ├── spec.md
        ├── plan.md
        ├── research.md
        ├── data-model.md
        ├── quickstart.md
        └── contracts/
```

### Feature Development Pattern

**MVVM Architecture**:

```swift
// 1. Create View
struct ChartListView: View {
    @StateObject private var viewModel = ChartListViewModel()

    var body: some View {
        List(viewModel.charts) { chart in
            ChartRow(chart: chart)
        }
        .task {
            await viewModel.loadCharts()
        }
    }
}

// 2. Create ViewModel
@MainActor
class ChartListViewModel: ObservableObject {
    @Published var charts: [BirthChart] = []

    func loadCharts() async {
        // Business logic here
    }
}

// 3. Create Service (if needed)
actor ChartService {
    func calculateChart(...) async throws -> NatalChart {
        // Implementation
    }
}
```

---

## Testing

### Unit Tests

Run all tests: `Cmd + U`

**Test Structure**:
```swift
import XCTest
@testable import AstroSvitla

class ChartCalculatorTests: XCTestCase {
    var calculator: ChartCalculator!

    override func setUp() {
        super.setUp()
        calculator = ChartCalculator()
    }

    func testCalculatePlanetPositions() async throws {
        // Given
        let birthDate = Date(...)
        let location = (lat: 50.4501, lon: 30.5234)

        // When
        let chart = try await calculator.calculate(
            date: birthDate,
            location: location
        )

        // Then
        XCTAssertEqual(chart.planets.count, 10)
        XCTAssertNotNil(chart.ascendant)
    }
}
```

### UI Tests

**Test Critical Flows**:
```swift
import XCUITest

class OnboardingFlowTests: XCTestCase {
    func testCompleteOnboardingFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // Tap through onboarding
        app.buttons["Next"].tap()
        app.buttons["Next"].tap()
        app.buttons["Get Started"].tap()

        // Verify we reached birth data screen
        XCTAssertTrue(app.textFields["Birth Date"].exists)
    }
}
```

---

## Common Issues

### Issue: SwissEphemeris Bundle Not Found

**Error**: `Ephemeris path not set`

**Solution**:
```swift
// Ensure this is called in App init
JPLFileManager.setEphemerisPath()
```

### Issue: Gemini API Key Not Found

**Error**: `GEMINI_API_KEY not set in environment`

**Solution**:
1. Create `.env` file with API key
2. Or set in Xcode scheme: Edit Scheme → Run → Arguments → Environment Variables

### Issue: StoreKit Products Not Loading

**Error**: `Products array empty`

**Solution**:
1. Verify product IDs match App Store Connect exactly
2. Check internet connection (Sandbox requires network)
3. Sign in with sandbox tester account
4. Wait up to 1 hour for metadata to propagate

### Issue: SwiftData Migration Error

**Error**: `Failed to load persistent stores`

**Solution**:
```bash
# Delete app from simulator and rebuild
xcrun simctl uninstall booted com.astrosvitla.astroinsight
```

### Issue: Build Failed - Swift 6 Concurrency

**Error**: `Actor-isolated property cannot be referenced from non-isolated context`

**Solution**:
```swift
// Ensure async functions use await
await viewModel.loadData()

// Mark view models @MainActor
@MainActor
class ViewModel: ObservableObject { }
```

---

## Quick Commands Reference

```bash
# Build for simulator
xcodebuild -scheme AstroSvitla -sdk iphonesimulator

# Run tests
xcodebuild test -scheme AstroSvitla -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Clean build folder
xcodebuild clean

# Lint code
swiftlint

# Format code
swiftformat .

# Delete derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reset simulator
xcrun simctl erase all
```

---

## Next Steps

Once setup is complete:

1. **Review Architecture**: Read `plan.md` for technical design
2. **Check Data Model**: Review `data-model.md` for SwiftData schema
3. **Review Contracts**: Read API contracts in `contracts/`
4. **Run Example Chart Calculation**: Test SwissEphemeris integration
5. **Generate Test Report**: Test Gemini API integration
6. **Create First Chart**: Test full user flow

---

## Getting Help

**Documentation**:
- Project spec: `specs/001-astrosvitla-ios-native/spec.md`
- Implementation plan: `specs/001-astrosvitla-ios-native/plan.md`
- Research findings: `specs/001-astrosvitla-ios-native/research.md`

**External Resources**:
- SwissEphemeris: https://github.com/vsmithers1087/SwissEphemeris
- Gemini AI: https://ai.google.dev/gemini-api/docs
- StoreKit 2: https://developer.apple.com/documentation/storekit
- SwiftData: https://developer.apple.com/documentation/swiftdata

**Support**:
- Create GitHub issue for bugs
- Check #astrosvitla Slack channel for questions

---

**Status**: ✅ QuickStart guide complete
**Last Updated**: 2025-10-08
