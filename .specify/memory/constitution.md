<!--
SYNC IMPACT REPORT
==================
Version: 0.0.0 → 1.0.0
Rationale: Initial constitution ratification for AstroSvitla project

Principles Added:
- I. Spec-Driven Development (NON-NEGOTIABLE)
- II. SwiftUI & Modern iOS Architecture
- III. Test-First Reliability
- IV. Secure Configuration & Secrets Hygiene
- V. Performance & User Experience Standards

Sections Added:
- Core Principles
- Development Workflow
- Governance

Templates Requiring Review:
⚠ /templates/plan-template.md - Verify constitution check section aligns
⚠ /templates/spec-template.md - Ensure mandatory sections match principles
⚠ /templates/tasks-template.md - Verify TDD task categorization

Follow-up TODOs:
- Review and update template files to reference new constitution principles
- Add constitution compliance check to PR review checklist
-->

# AstroSvitla Constitution

## Core Principles

### I. Spec-Driven Development (NON-NEGOTIABLE)

All features MUST begin with a complete specification before implementation:

- **Spec-First**: Every feature starts with `/specify` command generating `spec.md` in `specs/[###-feature-name]/`
- **Plan Follows Spec**: Implementation plan (`plan.md`) derived from locked spec via `/plan` command
- **Tasks From Plan**: Executable tasks (`tasks.md`) generated via `/tasks` command; tasks reference spec requirements
- **No Speculative Work**: Code changes without corresponding spec/plan/tasks artifacts are prohibited
- **Living Documentation**: Specs remain source of truth; code comments reference spec sections (e.g., `[Spec §FR-001]`)

**Rationale**: Eliminates scope creep, ensures shared understanding before coding, provides traceability from requirements to implementation.

### II. SwiftUI & Modern iOS Architecture

All code MUST follow modern iOS development standards:

- **Language & Platform**: Swift 5.9+ targeting iOS 17+ SDK minimum
- **UI Framework**: SwiftUI for all user interfaces; no UIKit unless absolutely required for platform gaps
- **Architecture**: MVVM pattern with clear separation:
  - Models: Domain entities (`Models/Domain/`), API DTOs (`Models/API/`)
  - Services: Business logic, API integration, caching (`Services/`)
  - ViewModels: UI state management, combine publishers
  - Views: SwiftUI views (`Features/[FeatureName]/Views/`)
- **Data Persistence**: SwiftData for all persistent storage (no CoreData)
- **Dependency Injection**: Protocol-based DI for services to enable testing
- **Code Organization**: Features grouped by capability with co-located tests

**Rationale**: Maintains codebase consistency, leverages modern iOS capabilities, ensures long-term maintainability.

### III. Test-First Reliability (NON-NEGOTIABLE)

Test-Driven Development is mandatory for all feature work:

- **Red-Green-Refactor**: Write failing tests → Implement → Pass tests → Refactor
- **Contract Tests**: API integrations MUST have contract tests validating expected payloads (e.g., `AstrologyAPIContractTests`)
- **Unit Tests**: Business logic MUST have unit test coverage with clear arrange/act/assert structure
- **Integration Tests**: Cross-service flows MUST have integration tests (e.g., cache + API + persistence)
- **Test Naming**: Use Swift Testing framework (`@Test`) with descriptive names: `testFeatureBehaviorUnderCondition()`
- **Fixtures**: Share test fixtures via `fixtures/` directory; use canonical sample data
- **Assertions**: Use `#expect()` assertions with failure messages

**Test Coverage Requirements**:
- New features: ≥80% line coverage
- Critical paths (auth, payments, data integrity): 100% coverage
- Bug fixes: Add regression test before fix

**Rationale**: Prevents regressions, documents expected behavior, enables confident refactoring, catches integration issues early.

### IV. Secure Configuration & Secrets Hygiene

Secrets and API keys MUST never be committed to version control:

- **Configuration Pattern**: Use `Config.swift` + `Config.swift.example` pattern
  - `Config.swift`: Contains actual secrets (gitignored)
  - `Config.swift.example`: Template with placeholder values (committed)
- **Secrets Management**:
  - API keys loaded from `Config.swift` at runtime
  - No hardcoded credentials in source files
  - Environment-specific configs (dev/staging/prod) clearly separated
- **Validation**: CI MUST fail if `Config.swift` detected in commits
- **Documentation**: `quickstart.md` MUST document all required config values
- **Defaults**: Provide sensible defaults or clear error messages for missing required config

**Rationale**: Prevents credential leaks, enables safe open-source sharing, protects user data and API quotas.

### V. Performance & User Experience Standards

App MUST maintain responsive, high-quality user experience:

- **Response Time Targets**:
  - UI interactions: <100ms perceived latency
  - API calls: <3s for critical operations (chart generation), <15s for report generation
  - Cache hits: <100ms retrieval time
- **Offline Support**:
  - Charts MUST be cached and available offline
  - Graceful degradation when network unavailable
- **Error Handling**:
  - User-friendly error messages (no technical jargon)
  - Retry mechanisms for transient failures
  - Comprehensive logging for debugging
- **Data Accuracy**:
  - Astrological calculations accurate within 1° (compared to Swiss Ephemeris)
  - All planetary positions, houses, aspects validated against reference data
- **Asset Optimization**:
  - Chart images cached to filesystem via `ImageCacheService`
  - Vector database queries cached when applicable

**Rationale**: Professional astrology users expect accuracy and reliability; poor performance damages trust and credibility.

## Development Workflow

### Feature Development Process

1. **Specification Phase** (`/specify`):
   - Gather requirements and user stories
   - Define acceptance criteria with measurable outcomes
   - Document edge cases, constraints, and assumptions
   - Output: `specs/[###-feature-name]/spec.md`

2. **Planning Phase** (`/plan`):
   - Design technical architecture and data models
   - Identify dependencies and integration points
   - Define test strategy and acceptance tests
   - Output: `specs/[###-feature-name]/plan.md`, `data-model.md`, `contracts/`

3. **Task Breakdown** (`/tasks`):
   - Create ordered, testable task list with dependencies
   - Map tasks to spec requirements for traceability
   - Identify parallel execution opportunities
   - Output: `specs/[###-feature-name]/tasks.md`

4. **Implementation Phase** (`/implement`):
   - Follow TDD: write test → implement → verify
   - Reference spec sections in code comments
   - Update `CLAUDE.md` with technology changes
   - Commit atomic changes with descriptive messages

5. **Quality Gates**:
   - All tests pass (`swift test` or `xcodebuild test`)
   - No compiler warnings (treat warnings as errors)
   - Code review approval
   - Spec/code consistency verified

### Branching & Commits

- **Branch Naming**: `[###-feature-name]` matching spec directory
- **Commit Messages**: Follow conventional commits format:
  - `feat:` new functionality
  - `fix:` bug fixes
  - `test:` adding tests
  - `refactor:` code restructuring
  - `docs:` documentation updates
- **Atomic Commits**: Each commit MUST build and pass tests
- **Reference Issues**: Link to spec in commit body (e.g., `Implements specs/005-enhance-astrological-report/spec.md §FR-001`)

### Code Review Requirements

All changes MUST be reviewed before merging:

- **Constitution Compliance**: Verify adherence to all principles
- **Test Coverage**: Ensure adequate test coverage added
- **Spec Traceability**: Confirm code implements documented requirements
- **Architecture Alignment**: Check MVVM separation and DI usage
- **No Secrets**: Verify no credentials committed
- **Documentation**: Ensure code comments and README updates present

## Governance

### Amendment Process

Constitution changes require:

1. **Proposal**: Document proposed change with rationale in issue or PR
2. **Review**: Team discussion and consensus
3. **Version Bump**: Increment `CONSTITUTION_VERSION` per semantic versioning:
   - **MAJOR**: Backward-incompatible principle removals or redefinitions
   - **MINOR**: New principles added or significant expansions
   - **PATCH**: Clarifications, wording improvements, typo fixes
4. **Propagation**: Update all dependent templates and documentation
5. **Announcement**: Communicate changes to team with migration guidance if needed

### Compliance & Enforcement

- **PR Gate**: Constitution compliance checked in every pull request review
- **Principle Violations**: Violations of NON-NEGOTIABLE principles block merge
- **Retrospectives**: Constitution reviewed quarterly for relevance and clarity
- **Flexibility**: Principles represent ideals; temporary deviations allowed with:
  - Explicit justification documented in spec or plan
  - Timeline for returning to compliance
  - Team agreement on exception

### Versioning & History

Constitution versioning follows semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR**: Breaks existing compliance (e.g., changing test framework requirement)
- **MINOR**: Adds new requirements without breaking existing code
- **PATCH**: Clarifications that don't change meaning

All changes MUST update the Sync Impact Report at file top.

### Authority & Scope

This constitution governs:

- ✅ Feature development methodology (spec → plan → tasks → implement)
- ✅ Code architecture and technology choices
- ✅ Testing requirements and quality standards
- ✅ Security and configuration practices
- ✅ Performance and UX expectations

This constitution does NOT govern:

- ❌ Project management and scheduling
- ❌ Business requirements and product decisions
- ❌ Team size or organizational structure
- ❌ Budget or resource allocation

For guidance on runtime development (choosing implementations, debugging, etc.), refer to active feature's `quickstart.md` and `CLAUDE.md`.

---

**Version**: 1.0.0 | **Ratified**: 2025-10-17 | **Last Amended**: 2025-10-17
