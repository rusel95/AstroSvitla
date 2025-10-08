<!--
Sync Impact Report
Version change: n/a -> 1.0.0
Modified principles:
- n/a -> I. Spec-Driven Delivery
- n/a -> II. SwiftUI Modular Architecture
- n/a -> III. Test-First Reliability
- n/a -> IV. Secure Configuration & Secrets Hygiene
- n/a -> V. Release Quality Discipline
Added sections:
- Core Principles
- Operational Standards
- Development Workflow & Quality Gates
- Governance
Removed sections:
- None
Templates requiring updates:
- ✅ .specify/templates/spec-template.md (structure already enforces spec-first scenarios and edge-case coverage)
- ✅ .specify/templates/plan-template.md (Constitution Check references these principles; no edits required)
- ✅ .specify/templates/tasks-template.md (user story grouping matches independence rule)
- ✅ (no command templates present under .specify/templates/commands/)
Follow-up TODOs:
- None
-->

# AstroSvitla Constitution

## Core Principles

### I. Spec-Driven Delivery
All work MUST begin with a `/specify` request that generates the spec-kit folder, and each downstream artifact (`plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `tasks.md`) MUST stay synchronized with the active feature branch. Teams MUST gate coding work on an approved specification and keep the spec updated when scope changes so business, design, and engineering remain aligned on value.

### II. SwiftUI Modular Architecture
The `AstroSvitla/` project MUST follow MVVM boundaries: UI in `Views`, state in `ViewModels`, domain types in `Models`, integrations in `Services`, and shared helpers in `Utils`. Keep one primary type per file named after its directory entry, favor SwiftUI previews for fixtures, and source all design tokens from `Assets.xcassets` to ensure consistent styling and localization.

### III. Test-First Reliability (NON-NEGOTIABLE)
Implement features using strict TDD: write failing tests before implementation, then iterate Red -> Green -> Refactor. All new logic MUST be covered by targeted `AstroSvitlaTests` unit cases (using `#expect`) and relevant `AstroSvitlaUITests` flows. `xcodebuild test -scheme AstroSvitla` MUST pass locally before merging, and deliberate gaps require explicit documentation in specs and PRs.

### IV. Secure Configuration & Secrets Hygiene
`Config/Config.swift` MUST never contain real secrets in the repository; use `.example` files for placeholders and document required keys. Feature toggles default to safe/off states, sensitive assets live outside version control, and exposed credentials MUST be rotated immediately with the incident recorded in team runbooks.

### V. Release Quality Discipline
Builds MUST stay reproducible: use the documented CLI build target (`xcodebuild -scheme AstroSvitla -destination 'platform=iOS Simulator,name=iPhone 15' build`) and keep dependencies pinned. Commits follow imperative, sentence-case subjects under 72 characters, PRs link the corresponding `specs/NNN-*` folder, include test evidence (`xcodebuild test`, manual notes), and attach UI screenshots whenever the interface changes.

## Operational Standards

- **Toolchain**: macOS 14.0+, Xcode 15+, iOS 17 SDK, Swift 5.9. Keep Swift Package versions locked and verify StoreKit, SwissEphemeris, and OpenAI integrations compile via the standard build command.
- **Code Style**: Enforce four-space indentation, trailing commas for multiline literals, and default to `private` access. Types use PascalCase, members camelCase, and view models carry the `ViewModel` suffix.
- **Assets & Localization**: Centralize colors, typography, and imagery inside `Assets.xcassets`, and ship English and Ukrainian strings together so each release remains bilingual.
- **Documentation**: Specs, plans, research, data models, quickstarts, and task lists offered by spec-kit are living documents; update them at the same time as code so reviewers and stakeholders always reference current truth.

## Development Workflow & Quality Gates

- **Phase Discipline**: Follow the spec-kit phases sequentially (spec -> plan -> research -> data model -> quickstart -> tasks -> implementation) and require checkpoint sign-off before advancing to coding.
- **Constitution Check**: Each plan MUST document how the feature satisfies these principles; violations go into Complexity Tracking with explicit justification and mitigation.
- **Review Expectations**: Code reviews focus on catching behavioral regressions, ensuring tests exist for new rules, and confirming Config hygiene. Approval requires green builds, spec alignment, and documented manual validation for risky flows.

## Governance

This constitution supersedes other internal guidelines for the AstroSvitla iOS app. Amendments require consensus from product, design, and engineering leads, an updated version number, and a migration or rollout note in the affected spec-kit folder. Version bumps follow semantic rules (MAJOR for breaking principle changes, MINOR for new principles/sections, PATCH for clarifications), and `Last Amended` MUST update whenever edits occur.

**Version**: 1.0.0 | **Ratified**: 2025-10-08 | **Last Amended**: 2025-10-08
