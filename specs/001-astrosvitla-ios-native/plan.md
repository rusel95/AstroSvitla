# Implementation Plan: Multi-User Support for AstroSvitla

**Branch**: `001-astrosvitla-ios-native` | **Date**: 2025-10-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-astrosvitla-ios-native/spec.md`

**Note**: This plan extends the existing AstroSvitla implementation with multi-user support functionality.

## Summary

This implementation adds multi-user profile management to AstroSvitla, allowing users to create and manage separate profiles for different people (self, partner, family members). Each user profile maintains its own natal chart and purchased reports. The main tab provides user selection and switching, while the reports tab organizes reports by user profile. This enables users to easily generate and view astrological insights for multiple individuals within a single app installation.

## Technical Context

**Language/Version**: Swift 6.0 / Swift 5.9 (Xcode 15+)
**Primary Dependencies**: SwiftUI, SwiftData, SwissEphemeris, OpenAI (MacPaw), StoreKit 2, MapKit
**Storage**: SwiftData (local-only, no cloud sync)
**Testing**: XCTest + XCUITest (using #expect for Swift Testing)
**Target Platform**: iOS 17.0+ (iPhone SE 2020+)
**Project Type**: Mobile (iOS native SwiftUI)
**Performance Goals**: 60 fps UI, <3s chart calculation, <10s report generation
**Constraints**: Portrait only, offline-capable (except report generation), <50MB bundle size
**Scale/Scope**: Single-device multi-user support, unlimited user profiles, 5 report types per user

### Key Technical Requirements for Multi-User Feature

- **Data Model Extension**: Introduce `UserProfile` entity between `User` (device owner) and `BirthChart`
- **State Management**: Maintain "active user profile" context across app session and app launches
- **UI Components**: User selector/picker on Main tab, grouped report list on Reports tab
- **Data Migration**: Update existing BirthChart → UserProfile relationship (if migrating from previous version)
- **Cascade Delete**: Handle deletion of user profiles with associated charts and reports
- **Validation**: Enforce unique user profile names within device installation

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Article I: Spec-Driven Delivery ✅
- ✅ Feature begins with updated spec.md (multi-user support requirements)
- ✅ This plan.md synchronized with active feature branch (001-astrosvitla-ios-native)
- ✅ data-model.md will be updated to reflect UserProfile entity
- ✅ Scope changes documented in spec before coding

### Article II: SwiftUI Modular Architecture ✅
- ✅ MVVM boundaries maintained: Views, ViewModels, Models, Services
- ✅ New components organized in Features/ directory structure
- ✅ One primary type per file (UserProfile.swift, UserProfileViewModel.swift, etc.)
- ✅ SwiftUI previews for new views
- ✅ Design tokens from Assets.xcassets for consistent styling

### Article III: Test-First Reliability ✅
- ✅ TDD approach: Write tests before implementation
- ✅ New UserProfile logic covered by AstroSvitlaTests unit tests
- ✅ User switching flow covered by AstroSvitlaUITests
- ✅ `xcodebuild test` must pass before merging
- ✅ Test coverage targets: >70% overall, >90% for critical paths

### Article IV: Secure Configuration & Secrets Hygiene ✅
- ✅ No new secrets introduced by multi-user feature
- ✅ Existing Config.swift patterns maintained
- ✅ User profile data stored locally, no external APIs

### Article V: Release Quality Discipline ✅
- ✅ Build reproducibility maintained via locked dependencies
- ✅ Commits follow imperative, sentence-case conventions
- ✅ PR will link specs/001-astrosvitla-ios-native/ folder
- ✅ UI screenshots for user selector and grouped reports list
- ✅ Test evidence: xcodebuild test results + manual validation

**Constitution Compliance**: PASS ✅
**No violations** - Feature aligns with all constitutional principles

## Project Structure

### Documentation (this feature)

```
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```
AstroSvitla/
├── App/
│   └── AstroSvitlaApp.swift
├── Core/
│   ├── Extensions/
│   ├── Navigation/
│   ├── Networking/
│   ├── Persistence/         # SwiftData container setup
│   └── Storage/
├── Models/
│   └── SwiftData/
│       ├── User.swift
│       ├── UserProfile.swift      # NEW: Multi-user profile entity
│       ├── BirthChart.swift       # MODIFIED: Add userProfile relationship
│       └── ReportPurchase.swift   # MODIFIED: Add userProfile relationship
├── Features/
│   ├── Main/
│   │   ├── Views/
│   │   │   ├── MainFlowView.swift          # MODIFIED: Add user selector
│   │   │   └── UserSelectorView.swift      # NEW: User picker UI
│   │   └── ViewModels/
│   │       └── MainFlowViewModel.swift     # MODIFIED: Manage active user
│   ├── UserManagement/                     # NEW: User profile management
│   │   ├── Views/
│   │   │   ├── UserProfileListView.swift
│   │   │   ├── UserProfileFormView.swift
│   │   │   └── UserProfileDetailView.swift
│   │   ├── ViewModels/
│   │   │   └── UserProfileViewModel.swift
│   │   └── Services/
│   │       └── UserProfileService.swift
│   ├── ChartInput/
│   │   └── ViewModels/
│   │       └── ChartInputViewModel.swift   # MODIFIED: Link to active user
│   ├── ReportGeneration/
│   │   └── Views/
│   │       └── ReportListView.swift        # MODIFIED: Group by user
│   └── [other features...]
├── Shared/
│   ├── AppPreferences.swift                # MODIFIED: Store active user ID
│   └── RepositoryContext.swift             # NEW: Manages active user context
└── Resources/
    ├── en.lproj/Localizable.strings        # MODIFIED: Add multi-user strings
    └── uk.lproj/Localizable.strings        # MODIFIED: Add multi-user strings

AstroSvitlaTests/
├── Models/
│   └── SwiftData/
│       ├── UserProfileModelTests.swift     # NEW: Test UserProfile model
│       └── UserProfileRelationshipTests.swift  # NEW: Test relationships
└── Features/
    └── UserManagement/
        └── UserProfileViewModelTests.swift # NEW: Test user switching logic

AstroSvitlaUITests/
└── UserManagement/
    ├── UserSelectionFlowTests.swift        # NEW: Test user picker interaction
    └── UserProfileCRUDTests.swift          # NEW: Test create/delete flows
```

**Structure Decision**: iOS mobile app using Feature Modules pattern. Multi-user support implemented as:
1. **New Models**: `UserProfile.swift` entity
2. **New Feature Module**: `UserManagement/` for profile CRUD operations
3. **Modified Existing**: Main tab, report list, chart input to support active user context
4. **Shared State**: `RepositoryContext` manages active user throughout app

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

**No violations to track** - Multi-user feature aligns with all constitutional principles.

---

## Implementation Phases

### Phase 0: Research ✅
**Status**: Complete (see research.md)
- All technology decisions made
- SwiftData chosen for persistence
- Native SwiftUI chart visualization completed
- OpenAI integration for reports established

### Phase 1: Data Model & Contracts

#### 1.1 Update Data Model
- **File**: `data-model.md`
- **Changes**:
  - Add `UserProfile` entity documentation
  - Update `BirthChart` relationship (belongs to UserProfile)
  - Update `ReportPurchase` relationship (belongs to UserProfile)
  - Document cascade delete behavior
  - Add validation rules for unique profile names

#### 1.2 Define Service Contracts
- **Directory**: `contracts/`
- **Files**:
  - `UserProfileService.md`: CRUD operations for user profiles
  - `ActiveUserManager.md`: State management for active user context
  - Update existing service contracts as needed

#### 1.3 Update Quickstart Guide
- **File**: `quickstart.md`
- **Changes**:
  - Add "Managing Multiple Users" section
  - Document user switching workflow
  - Update report viewing workflow (grouped by user)

### Phase 2: Implementation Tasks
**Status**: Pending (will be generated by /tasks command)
- Task breakdown will be created in `tasks.md`
- Estimated: 15-20 tasks
- Priority order: Data models → Services → ViewModels → Views → Tests

---

## Progress Tracking

### Phase 0: Research ✅
- [x] Technology decisions documented in research.md
- [x] SwiftData chosen for persistence
- [x] Native SwiftUI chart visualization
- [x] OpenAI integration established

### Phase 1: Data Model & Contracts ✅
- [x] data-model.md updated with UserProfile entity
- [x] Entity relationships defined (User → UserProfile → BirthChart/Reports)
- [x] Cascade delete behavior documented
- [x] Validation rules specified
- [x] quickstart.md updated with multi-user workflows
- [ ] Service contracts created in contracts/ directory

### Phase 2: Implementation Tasks
- [ ] tasks.md generated (run /tasks command)
- [ ] Task breakdown completed
- [ ] Implementation priority determined

---

## Next Steps

1. **Create Service Contracts** (Phase 1.2):
   - `contracts/UserProfileService.md`
   - `contracts/ActiveUserManager.md`

2. **Generate Tasks** (Phase 2):
   ```bash
   /tasks
   ```

3. **Begin Implementation**:
   - Follow TDD approach (tests first)
   - Implement in priority order: Models → Services → ViewModels → Views
   - Run tests after each component

---

## Summary

**Planning Status**: Phase 1 Complete ✅

**Artifacts Generated**:
- ✅ plan.md (this file)
- ✅ data-model.md (updated with UserProfile)
- ✅ quickstart.md (updated with multi-user workflows)
- ⏳ contracts/ (pending)
- ⏳ tasks.md (pending - run /tasks)

**Key Decisions**:
- UserProfile entity introduced between User and BirthChart
- 1:1 relationship between UserProfile and BirthChart
- Active profile tracked in User.activeProfileId
- RepositoryContext manages active profile state
- Reports grouped by user profile in UI

**Ready for**: Task generation (/tasks) and implementation

