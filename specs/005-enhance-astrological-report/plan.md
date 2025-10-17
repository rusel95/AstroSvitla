# Implementation Plan: Enhance Astrological Report Completeness & Source Transparency

**Branch**: `005-enhance-astrological-report` | **Date**: October 17, 2025 | **Spec**: `specs/005-enhance-astrological-report/spec.md`
**Input**: Feature specification from `/specs/005-enhance-astrological-report/spec.md`

## Summary

Sunset legacy providers (FreeAstrology, Prokerala) and rebuild the natal chart pipeline around `api.astrology-api.io`. Refresh DTOs, mappers, and orchestration so North/South Node, Lilith, house rulers, and expanded aspects flow end-to-end without compile breaks. Preserve offline expectations (cache services, SVG storage, rate limiting) and prepare the knowledge transparency layer to work without vector-store integration until it is explicitly greenlit.

## Technical Context

**Language/Version**: Swift 5.9 (Xcode 15 toolchain)  
**Primary Dependencies**: SwiftUI, SwiftData, Combine, URLSession, Network, OpenAI Swift SDK (vector usage deferred)  
**Storage**: SwiftData for cached natal charts, filesystem image cache via `ImageCacheService`  
**Testing**: XCTest with `#expect`; async unit + integration suites under `AstroSvitlaTests`  
**Target Platform**: iOS 17+, iPhone 15 simulator baseline  
**Project Type**: Native iOS SwiftUI app with MVVM separation  
**Performance Goals**: Report generation < 15s, node accuracy within 1°, 20+ aspects sorted by orb  
**Constraints**: Single astrology API provider, offline-friendly caching, no secrets in repo, output budget ~1800 tokens  
**Scale/Scope**: Touches ~15 Swift files across Models/API, Services, Tests, plus spec-kit artifacts

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| Spec-Driven Delivery | ✅ | Working inside `specs/005-...`; plan keeps artifacts aligned before coding |
| SwiftUI Modular Architecture | ✅ | Changes remain within `Models`, `Services`, `Utils`, `ViewModels` per MVVM | 
| Test-First Reliability | ⚠️ | Existing contract tests red after provider removal; plan schedules new failing tests before implementation |
| Secure Configuration & Secrets Hygiene | ✅ | `Config.swift` retains placeholders; ensure `.example` documents astrology API key |
| Release Quality Discipline | ⚠️ | Build currently broken; plan mandates restoring green build via `xcodebuild` before merge |

**Gate Result**: Continue to Phase 0 with explicit tasks to re-establish failing tests (contracts + service) so TDD flow resumes and to document config placeholders.

## Project Structure

### Documentation (this feature)

```
specs/005-enhance-astrological-report/
├── plan.md              # Planning artifact (this file)
├── research.md          # Phase 0 research (updated in this run)
├── data-model.md        # Phase 1 design (updated in this run)
├── quickstart.md        # Phase 1 developer handoff (updated in this run)
├── contracts/           # HTTP + payload contracts (updated in this run)
└── tasks.md             # Phase 2 TDD backlog (unchanged by /speckit.plan)
```

### Source Code (repository root)

```
AstroSvitla/
├── Models/
│   ├── Domain/             # BirthDetails, NatalChart, Aspect, House, etc.
│   └── API/
│       └── AstrologyAPI/   # DTOs + mappers for api.astrology-api.io
├── Services/
│   ├── AstrologyAPI/       # Primary remote service layer
│   ├── ChartCacheService.swift
│   ├── ImageCacheService.swift
│   └── RateLimiter.swift
├── Shared/
├── Utils/                  # NetworkMonitor, logging utilities
├── ViewModels/
└── Views/

AstroSvitlaTests/
├── Features/
│   └── ChartCalculation/   # Contract + mapper tests for chart generation
├── IntegrationTests/
│   └── NatalChartGenerationTests.swift
└── Core/Storage/           # Cache persistence tests
```

**Structure Decision**: All changes live inside the existing SwiftUI app module. Key touchpoints: `Models/API/AstrologyAPI` (new DTOs), `Services/AstrologyAPI/AstrologyAPIService.swift` (network orchestration), `Services/NatalChartService.swift` (high-level use case), caching utilities, and matching tests under `AstroSvitlaTests/Features/ChartCalculation`.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| _None_ | - | - |
