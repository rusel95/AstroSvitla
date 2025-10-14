# Implementation Plan: Integrate New Astrology API

**Branch**: `004-integrate-new-astrology` | **Date**: October 11, 2025 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-integrate-new-astrology/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Integrate api.astrology-api.io as the new primary astrology calculation service for natal chart generation, replacing current Free Astrology API while preserving existing domain models and caching infrastructure. The integration will use the /api/v3/charts/natal endpoint for calculations and /api/v3/svg/natal for chart visualizations, with existing API implementations commented out (not deleted) for potential rollback. All current functionality including caching, offline support, and user experience remains unchanged.

## Technical Context

**Language/Version**: Swift 5.9+ (iOS 17+ SDK)  
**Primary Dependencies**: 
- SwiftUI (UI framework)
- Foundation (networking via URLSession)
- SwiftData (persistence layer)
- Network (connectivity monitoring)

**Storage**: SwiftData for caching natal charts and metadata (existing models preserved)  
**Testing**: XCTest framework with `#expect` assertions for unit tests, XCUITest for UI automation  
**Target Platform**: iOS 17+ (iPhone and iPad)
**Project Type**: iOS mobile app following existing MVVM modular architecture  
**Performance Goals**: Chart generation under 3 seconds including API call and visualization  
**Constraints**: 
- Offline capability required (cached charts available without network)
- Rate limiting must respect API quotas
- Memory usage under 100MB for chart generation
- No breaking changes to existing domain models

**Scale/Scope**: 
- Single API provider integration (~5 new service files)
- Commenting out ~10 existing API implementation files
- No UI changes required
- Preserving ~25 existing domain model and caching files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Spec-Driven Delivery ✅
- Feature begins with approved `/specify` request with spec-kit folder
- All artifacts (`plan.md`, `research.md`, `data-model.md`, `quickstart.md`) will sync with branch
- Scope changes require spec updates to maintain alignment

### II. SwiftUI Modular Architecture ✅  
- New services go in `Services/AstrologyAPI/` following existing patterns
- DTOs in `Models/API/` alongside existing API models
- Mappers in `Services/AstrologyAPI/` co-located with service
- No changes to existing `Views`, `ViewModels` structure
- One primary type per file, naming follows directory structure

### III. Test-First Reliability ✅
- TDD approach: write failing tests before implementation
- Unit tests in `AstroSvitlaTests/Services/AstrologyAPI/` using `#expect`
- Integration tests verify end-to-end natal chart generation
- Existing tests preserved (commented out where they reference old APIs)
- `xcodebuild test -scheme AstroSvitla` must pass before merge

### IV. Secure Configuration & Secrets Hygiene ✅
- API credentials in `Config/Config.swift` with placeholder patterns
- New API key uses environment variable or placeholder approach
- No real credentials committed to repository
- Document required configuration in README updates

### V. Release Quality Discipline ✅
- Standard build command compatibility maintained
- Commits follow imperative, sentence-case format <72 chars
- PR links to `specs/004-integrate-new-astrology/` folder  
- Test evidence and manual validation documented
- No UI changes = no screenshot requirements

**Status**: All constitutional requirements satisfied. No violations requiring justification.

## Project Structure

### Documentation (this feature)

```
specs/004-integrate-new-astrology/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
AstroSvitla/
├── Models/
│   └── API/
│       ├── AstrologyAPIModels.swift    # NEW: DTOs for api.astrology-api.io
│       ├── FreeAstrologyModels.swift   # COMMENT OUT: Existing Free Astrology DTOs
│       └── ProkralaModels.swift        # COMMENT OUT: Existing Prokerala DTOs
├── Services/
│   ├── AstrologyAPI/                   # NEW: Directory for new API service
│   │   ├── AstrologyAPIService.swift   # NEW: HTTP client for api.astrology-api.io
│   │   └── AstrologyAPIDTOMapper.swift # NEW: Maps API responses to domain models
│   ├── FreeAstrology/                  # COMMENT OUT: Existing service files
│   │   ├── FreeAstrologyAPIService.swift
│   │   └── FreeAstrologyDTOMapper.swift
│   ├── Prokerala/                      # COMMENT OUT: Existing service files
│   │   ├── ProkralaAPIService.swift
│   │   └── DTOMapper.swift
│   ├── ChartCacheService.swift         # PRESERVE: No changes
│   ├── ImageCacheService.swift         # PRESERVE: No changes
│   ├── NatalChartService.swift         # UPDATE: Switch to new API service
│   └── RateLimiter.swift              # PRESERVE: Reuse for new API
├── Config/
│   └── Config.swift                    # UPDATE: Add new API credentials
└── [All other existing directories preserved unchanged]

AstroSvitlaTests/
├── Services/
│   ├── AstrologyAPI/                   # NEW: Tests for new API service
│   │   ├── AstrologyAPIServiceTests.swift
│   │   └── AstrologyAPIDTOMapperTests.swift
│   ├── FreeAstrology/                  # COMMENT OUT: Existing test files
│   └── Prokerala/                      # COMMENT OUT: Existing test files
├── IntegrationTests/
│   └── NatalChartGenerationTests.swift # UPDATE: Switch to new API
└── [All other existing test directories preserved]
```

**Structure Decision**: iOS mobile app following existing MVVM modular architecture. This feature:
1. **Adds new service layer**: `Services/AstrologyAPI/` with HTTP client and mapper
2. **Adds new DTOs**: `Models/API/AstrologyAPIModels.swift` for api.astrology-api.io responses
3. **Comments existing services**: FreeAstrology and Prokerala services remain in codebase but inactive
4. **Updates orchestration**: `NatalChartService` configured to use `AstrologyAPIService`
5. **Preserves all existing domain models and caching infrastructure**

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

No constitutional violations identified. This feature:
- Follows existing architectural patterns
- Maintains all quality gates
- Preserves existing modular structure
- Uses standard Swift/iOS development practices
- Requires no special exceptions or complexity justifications

---

## Phase 0: Research

**Prerequisites**: Constitution Check passed

### Research Tasks

1. **API Authentication & Rate Limiting**: Research api.astrology-api.io authentication requirements, rate limits, and best practices for iOS HTTP clients
   
2. **API Response Mapping**: Analyze api.astrology-api.io response structure for `/api/v3/charts/natal` and `/api/v3/svg/natal` to design optimal DTO mapping strategy

3. **Error Handling Patterns**: Research robust error handling for network failures, API downtime, and rate limiting specific to astrology calculation services

4. **Configuration Management**: Determine best practices for storing API credentials securely in iOS apps without exposing them in source control

### Expected Deliverables
- `research.md` with decisions, rationales, and alternatives for each research area
- Technical approach validation
- Risk mitigation strategies identified

---

## Phase 1: Design & Contracts ✅ COMPLETED

**Prerequisites**: `research.md` complete ✅

### Design Tasks ✅ ALL COMPLETED

1. **Data Model Design**: Extract entities from feature requirements and design DTOs for api.astrology-api.io integration ✅ **COMPLETED** - `data-model.md` created with comprehensive DTO structures and domain mapping logic

2. **API Contract Definition**: Define HTTP contract specifications for natal chart generation and SVG visualization endpoints ✅ **COMPLETED** - `contracts/astrology-api-openapi.json` and `contracts/astrology-api-examples.http` created with full specifications

3. **Service Architecture**: Design service layer interfaces that maintain compatibility with existing domain models ✅ **COMPLETED** - Architecture defined in `quickstart.md` with clear service integration patterns

4. **Testing Strategy**: Define comprehensive testing approach including unit, integration, and contract tests ✅ **COMPLETED** - Comprehensive testing strategy documented in `quickstart.md`

### Expected Deliverables ✅ ALL DELIVERED
- `data-model.md` with entity definitions and relationships ✅ **COMPLETE**
- `contracts/` directory with HTTP API specifications ✅ **COMPLETE** 
- `quickstart.md` with integration examples ✅ **COMPLETE**
- Updated agent context (CLAUDE.md) with new technology stack additions ✅ **COMPLETE**

**PHASE 1 STATUS**: ✅ **COMPLETED SUCCESSFULLY** - All design artifacts created and validated. Ready to proceed to implementation phase.

---

**Ready for Phase 0 Research**: All planning prerequisites met. Constitution check passed. Technical context defined.
