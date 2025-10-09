# Implementation Plan: Migrate to Prokerala Astrology API

**Branch**: `002-migrate-natal-chart` | **Date**: 2025-10-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-migrate-natal-chart/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Replace the current SwissEphemeris-based local natal chart calculation system with Prokerala Astrology API for both astronomical calculations (planetary positions, houses, aspects) and chart wheel visualization (SVG/PNG). This migration provides a unified API-based solution that handles both computation and rendering, eliminating the need for local ephemeris data and custom chart drawing logic. The feature will maintain offline access to previously generated charts through local caching while requiring internet connectivity only for new chart generation.

## Technical Context

**Language/Version**: Swift 5.9+ (iOS 17+ SDK)
**Primary Dependencies**:
- SwiftUI (UI framework)
- SwiftData (local persistence for chart caching)
- Foundation URLSession (HTTP client for Prokerala API)
- Removing: SwissEphemeris library (current calculation engine)

**Storage**:
- SwiftData ModelContainer for cached natal chart data and metadata
- FileManager for cached chart wheel images (SVG/PNG files)
- UserDefaults for API usage tracking (rate limits, credit consumption)

**Testing**:
- XCTest framework with `#expect` assertions
- Unit tests in `AstroSvitlaTests/`
- UI tests in `AstroSvitlaUITests/`
- Contract tests for Prokerala API integration

**Target Platform**: iOS 17.0+, iPhone and iPad (UIUserInterfaceIdiom support)

**Project Type**: Mobile (iOS) - Single Xcode project with modular MVVM architecture

**Performance Goals**:
- Chart generation response within 5 seconds under normal network conditions
- 95% success rate for API requests
- API rate limit compliance: 5 requests/minute, 5000 credits/month
- Image caching to minimize redundant API calls

**Constraints**:
- Must handle offline scenarios gracefully (show cached charts, clear error for new generation)
- API credentials must remain in Config.swift (gitignored)
- Must comply with Prokerala API rate limits (5 req/min on free tier)
- Network latency dependent (no local fallback for calculations)
- Chart accuracy within 1 degree of expected values

**Scale/Scope**:
- Single user profiles with multiple cached charts per profile
- Estimated 5-20 chart generations per user per month
- Free tier supports ~250-500 users monthly (5000 credits)
- Features affected: ChartCalculation, ChartVisualization, potentially ChartInput
- Preserve existing UI flows, replace backend calculation logic

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Spec-Driven Delivery ✅

- Feature initiated via `/specify` with approved `specs/002-migrate-natal-chart/spec.md`
- This plan.md synchronized with feature branch `002-migrate-natal-chart`
- Will generate: research.md, data-model.md, contracts/, quickstart.md, tasks.md
- **Status**: PASS

### Principle II: SwiftUI Modular Architecture ✅

- Current structure follows MVVM:
  - Models: `AstroSvitla/Models/` (NatalChart, Planet, House, Aspect, BirthData)
  - Services: `AstroSvitla/Services/` (will add ProkralaAPIService)
  - Features: `AstroSvitla/Features/ChartCalculation/`, `ChartVisualization/`
  - ViewModels: Feature-specific view models
  - Views: SwiftUI views in Features/*/Views/
- One primary type per file, SwiftUI previews for fixtures
- Config.swift for API keys (already gitignored)
- **Status**: PASS - existing patterns maintained

### Principle III: Test-First Reliability (NON-NEGOTIABLE) ⚠️

- **Current state**: TDD required but not yet implemented for this feature
- **Plan**:
  - Write unit tests for ProkralaAPIService before implementation
  - Write unit tests for response parsing and error handling
  - Write unit tests for caching logic
  - Write integration tests for API contract validation
  - Write UI tests for chart generation flows
- **Commitment**: All new API client, parsing, and caching logic will be TDD
- Tests must pass via `xcodebuild test -scheme AstroSvitla` before merge
- **Status**: CONDITIONAL PASS - TDD commitment documented in tasks

### Principle IV: Secure Configuration & Secrets Hygiene ✅

- API credentials will be stored in `Config.swift` (gitignored)
- `Config.swift.example` will document required keys:
  - `prokralaAPIKey` or `prokralaClientID` + `prokralaClientSecret`
  - `prokralaBaseURL` (default: documented API endpoint)
- No secrets in version control
- **Status**: PASS

### Principle V: Release Quality Discipline ✅

- Build target: `xcodebuild -scheme AstroSvitla -destination 'platform=iOS Simulator,name=iPhone 15' build`
- Tests: `xcodebuild test -scheme AstroSvitla`
- PR will link to `specs/002-migrate-natal-chart/` folder
- UI changes (chart visualization) will include screenshots
- Commit messages will follow convention
- **Status**: PASS

## Project Structure

### Documentation (this feature)

```
specs/002-migrate-natal-chart/
├── spec.md              # Feature specification
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── prokerala-natal-chart.http     # Natal chart data endpoint
│   ├── prokerala-chart-wheel.http     # Chart wheel image endpoint
│   └── response-schemas.json          # API response type definitions
├── checklists/
│   └── requirements.md  # Spec quality checklist (already complete)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
AstroSvitla/                           # iOS app target
├── App/
│   └── AstroSvitlaApp.swift           # App entry point
├── Config/
│   ├── Config.swift                   # Gitignored secrets (will add Prokerala keys)
│   └── Config.swift.example           # Template (will update with Prokerala config)
├── Models/                            # Domain entities
│   ├── NatalChart.swift               # Natal chart aggregate
│   ├── Planet.swift                   # Planet position model
│   ├── House.swift                    # House cusp model
│   ├── Aspect.swift                   # Aspect model
│   ├── BirthData.swift                # Birth information input
│   ├── ChartVisualization.swift       # NEW: Chart image metadata model
│   └── ProkralaModels.swift           # NEW: API response DTOs
├── Services/                          # Business logic & integrations
│   ├── ProkralaAPIService.swift       # NEW: HTTP client for Prokerala API
│   ├── ChartCacheService.swift        # NEW: Local persistence for charts & images
│   └── [SwissEphemerisService.swift]  # DEPRECATED: Will be removed/archived
├── Features/
│   ├── ChartCalculation/
│   │   ├── Services/
│   │   │   ├── ChartCalculator.swift          # REFACTOR: Adapt to use ProkralaAPIService
│   │   │   └── [SwissEphemerisService.swift]  # MOVE to archive/deprecated
│   │   └── Views/
│   │       ├── ChartDetailsView.swift         # UPDATE: Handle API loading states
│   │       └── NatalChartWheelView.swift      # REFACTOR: Display cached/API images
│   ├── ChartVisualization/
│   │   └── [TBD]                              # May need updates for image display
│   ├── ChartInput/                            # May need updates for validation
│   └── [Other features unchanged]
├── ViewModels/                        # Feature-specific view models
│   └── ChartCalculationViewModel.swift        # REFACTOR: Integrate ProkralaAPIService
└── Utils/                             # Shared helpers
    ├── NetworkMonitor.swift           # NEW: Reachability/connectivity checks
    └── ImageCache.swift               # NEW: Image file management helpers

AstroSvitlaTests/                      # Unit tests
├── Services/
│   ├── ProkralaAPIServiceTests.swift  # NEW: API client tests (TDD)
│   ├── ChartCacheServiceTests.swift   # NEW: Caching logic tests (TDD)
│   └── ChartCalculatorTests.swift     # UPDATE: Test API integration
├── Models/
│   └── ProkralaModelsTests.swift      # NEW: DTO parsing tests
└── Mocks/
    ├── MockProkralaAPIService.swift   # NEW: Test doubles
    └── MockURLSession.swift           # NEW: Network mocking

AstroSvitlaUITests/                    # UI/E2E tests
└── ChartGenerationUITests.swift       # UPDATE: Test full chart generation flow
```

**Structure Decision**: iOS mobile app following existing MVVM modular architecture. The migration primarily affects:
1. **Services layer**: New `ProkralaAPIService` replaces `SwissEphemerisService`
2. **Models layer**: Add API response DTOs and chart visualization metadata
3. **Features/ChartCalculation**: Refactor to use API-based calculation
4. **Features/ChartVisualization**: Adapt to display API-provided chart images
5. **Storage**: Add caching services for offline chart access

The existing structure (`Features/`, `Models/`, `Services/`, `ViewModels/`, `Views/`) is preserved. SwissEphemeris dependency will be removed from Package.swift or project dependencies.

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | All constitutional principles satisfied | N/A |

## Progress Tracking

- [x] Phase -1: Technical Context filled
- [x] Phase -1: Constitution Check completed
- [x] Phase -1: Project Structure documented
- [x] Phase 0: Research & unknowns resolution
- [x] Phase 1: Data model design
- [x] Phase 1: API contracts definition
- [x] Phase 1: Quickstart guide
- [x] Phase 1: Agent context update
- [x] Phase 2: Tasks generation (separate `/speckit.tasks` command)
