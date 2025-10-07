# AstroSvitla Constitution

## Core Principles

### I. Observation-Backed Value
Every feature starts with a clearly articulated user problem tied to astronomy exploration or sky-watching workflows. Hypotheses and success metrics are documented before any code is written, and each release must trace back to an approved scenario.

### II. SwiftUI & SwiftData Native
We prioritize modern Apple platform patterns: SwiftUI for UI, SwiftData for persistence, and structured concurrency for async work. UIKit or third-party frameworks are introduced only when they materially reduce risk and are justified in the technical plan.

### III. Test-Driven Reliability (NON-NEGOTIABLE)
Acceptance criteria become automated tests before implementation begins. Unit, snapshot, and integration tests must fail prior to feature work, then pass before code review. Regressions require a reproducing test before fixes merge.

### IV. Performance & Battery Stewardship
Animations, data refresh, and background tasks must respect the constraints of iOS devices. Performance budgets are defined per screen, energy diagnostics are run on representative devices, and optimizations never sacrifice correctness or clarity.

### V. Accessible Astronomy for All
UI flows are built and verified for VoiceOver, Dynamic Type, and high-contrast modes. Localizable strings, inclusive content, and color-safe palettes are mandatory. Accessibility regressions block releases.

## Platform Standards & Constraints
The app targets iOS 17+ and macOS 14+ with universal SwiftUI code where viable. Networking must use URLSession with async/await, and all remote data must be cached securely with SwiftData. Third-party services require documented data-handling reviews and can only be introduced through dependency proposals.

## Workflow & Quality Gates
Work begins with a concise spec reviewed against this constitution. Implementation plans identify architecture decisions, test strategy, and observability hooks. Pull requests require:
- Passing CI for linting, tests, and bundle size checks.
- Accessibility verification notes.
- Release notes drafted in Markdown for user-facing changes.

## Governance
This constitution supersedes ad-hoc practices. Amendments require a written proposal, approval from product, engineering, and design leads, and a migration plan for in-flight work. Code reviews explicitly confirm alignment with each principle.

**Version**: 1.0.0 | **Ratified**: 2025-09-21 | **Last Amended**: 2025-09-21
