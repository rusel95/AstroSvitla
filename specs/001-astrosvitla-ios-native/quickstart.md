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

2. **OpenAI API Key**
   - Create at: https://platform.openai.com/api-keys
   - Developer tier includes free credit for new accounts; production scales with usage

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

2. **OpenAI Swift SDK** (AI Report Generation)
   - Repository: `https://github.com/openai/openai-swift`
   - Version: Latest
   - License: MIT

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
OPENAI_API_KEY=your_openai_api_key_here
```

**Get OpenAI API Key**:
1. Visit https://platform.openai.com/api-keys
2. Click "Create new secret key"
3. Copy key and paste into `.env`

### 2. Xcode Configuration

Create `Config.xcconfig` in project root:

```bash
# Config.xcconfig
OPENAI_API_KEY = $(OPENAI_API_KEY)
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

## Multi-User Profile Management

### Overview

AstroSvitla supports multiple user profiles, allowing users to create and manage natal charts for different people (self, partner, family members) within a single app installation.

### Key Concepts

- **Device Owner (User)**: Represents the app installation (one per device)
- **User Profile**: Represents an individual person with birth data and charts
- **Active Profile**: Currently selected user profile (maintained across sessions)
- **Profile Switching**: Users can switch between profiles from the Main tab

### Creating a New User Profile

**From UI**:
1. Open Main tab
2. Tap "Add New User" button
3. Enter profile name (must be unique)
4. Enter birth date, time, and location
5. System validates and creates profile
6. Profile becomes active automatically

**Programmatically**:
```swift
class UserProfileService {
    let context: ModelContext

    func createProfile(
        name: String,
        birthDate: Date,
        birthTime: Date,
        locationName: String,
        latitude: Double,
        longitude: Double,
        timezone: String
    ) async throws -> UserProfile {
        // Validate name uniqueness
        guard isProfileNameUnique(name, context: context) else {
            throw UserProfileError.duplicateName
        }

        // Create profile
        let profile = UserProfile(
            name: name,
            birthDate: birthDate,
            birthTime: birthTime,
            locationName: locationName,
            latitude: latitude,
            longitude: longitude,
            timezone: timezone
        )

        // Insert into context
        context.insert(profile)

        // Calculate natal chart
        let chartService = ChartCalculator()
        let natalChart = try await chartService.calculate(
            birthDate: birthDate,
            birthTime: birthTime,
            latitude: latitude,
            longitude: longitude
        )

        // Create and link birth chart
        let chartData = try JSONEncoder().encode(natalChart)
        let birthChart = BirthChart(
            chartDataJSON: String(data: chartData, encoding: .utf8) ?? ""
        )
        birthChart.profile = profile
        context.insert(birthChart)

        // Save
        try context.save()

        return profile
    }
}
```

### Switching Active User Profile

**From UI**:
1. Open Main tab
2. Tap user selector dropdown
3. Select different user profile
4. System updates active profile reference
5. All views update to show new user's data

**Programmatically**:
```swift
class RepositoryContext: ObservableObject {
    @Published var activeProfile: UserProfile?
    private let context: ModelContext

    func setActiveProfile(_ profile: UserProfile) {
        // Update User.activeProfileId
        if let user = fetchDeviceOwner() {
            user.setActiveProfile(profile)
            try? context.save()
        }

        // Update published property
        self.activeProfile = profile
    }

    func loadActiveProfile() {
        guard let user = fetchDeviceOwner(),
              let activeId = user.activeProfileId else {
            return
        }

        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.id == activeId }
        )
        self.activeProfile = try? context.fetch(descriptor).first
    }
}
```

### Viewing Reports Grouped by User

**ReportListView with Grouping**:
```swift
struct ReportListView: View {
    @Query(sort: \UserProfile.name) var profiles: [UserProfile]
    @Environment(\.modelContext) private var context

    var body: some View {
        List {
            ForEach(profiles) { profile in
                Section(header: Text(profile.name)) {
                    ForEach(profile.reports) { report in
                        ReportRow(report: report)
                    }
                }
            }
        }
        .navigationTitle("My Reports")
    }
}
```

### Deleting a User Profile

**With Cascade Delete Warning**:
```swift
func deleteProfile(_ profile: UserProfile) {
    // Check for associated data
    let reportCount = profile.reports.count
    let hasChart = profile.chart != nil

    // Show warning alert to user
    let message = """
    This will delete:
    • Profile: \(profile.name)
    • Birth Chart: \(hasChart ? "Yes" : "None")
    • Reports: \(reportCount)

    This action cannot be undone.
    """

    // If confirmed, delete (cascade deletes chart and reports)
    context.delete(profile)
    try? context.save()

    // If this was active profile, select another or set to nil
    updateActiveProfileAfterDeletion()
}
```

### Validation Rules

**Profile Name Uniqueness**:
```swift
func isProfileNameUnique(_ name: String, excluding profileId: UUID? = nil) -> Bool {
    let descriptor = FetchDescriptor<UserProfile>(
        predicate: #Predicate { profile in
            profile.name == name && (profileId == nil || profile.id != profileId!)
        }
    )
    let results = try? context.fetch(descriptor)
    return results?.isEmpty ?? true
}
```

### Best Practices

1. **Always validate profile name uniqueness** before creating/updating
2. **Maintain active profile context** across app sessions (persist in User.activeProfileId)
3. **Show confirmation dialog** before deleting profiles with reports
4. **Update UI reactively** when active profile changes (use @Published in RepositoryContext)
5. **Handle edge cases**:
   - No profiles exist (first launch)
   - Active profile is deleted
   - Multiple profiles with same birth data

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

### Issue: OpenAI API Key Not Found

**Error**: `OPENAI_API_KEY not set in environment`

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
5. **Generate Test Report**: Test OpenAI integration
6. **Create First Chart**: Test full user flow

---

## Getting Help

**Documentation**:
- Project spec: `specs/001-astrosvitla-ios-native/spec.md`
- Implementation plan: `specs/001-astrosvitla-ios-native/plan.md`
- Research findings: `specs/001-astrosvitla-ios-native/research.md`

**External Resources**:
- SwissEphemeris: https://github.com/vsmithers1087/SwissEphemeris
- OpenAI Swift SDK: https://github.com/openai/openai-swift
- StoreKit 2: https://developer.apple.com/documentation/storekit
- SwiftData: https://developer.apple.com/documentation/swiftdata

**Support**:
- Create GitHub issue for bugs
- Check #astrosvitla Slack channel for questions

---

**Status**: ✅ QuickStart guide complete
**Last Updated**: 2025-10-08
