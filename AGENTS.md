# Repository Guidelines

## Project Structure & Module Organization
- `AstroSvitla/` contains the SwiftUI app; keep UI in `Views`, state in `ViewModels`, domain types in `Models`, integrations in `Services`, and shared helpers in `Utils`.
- `Config/Config.swift` holds local secrets and flags; keep real keys out of commits and document expected placeholders.
- `Assets.xcassets` houses design tokens; tests live under `AstroSvitlaTests/` + `AstroSvitlaUITests/`, and `scripts/` supports Spec-Driven workflows.

## Build, Test, and Development Commands
- `open AstroSvitla.xcodeproj` opens the default `AstroSvitla` scheme inside Xcode.
- `xcodebuild -scheme AstroSvitla -destination 'platform=iOS Simulator,name=iPhone 15' build` performs a CLI build; swap the simulator target as needed.
- `xcodebuild test -scheme AstroSvitla -only-testing:AstroSvitlaTests` runs unit tests; remove the filter to include UI automation. `scripts/check-prerequisites.sh --json` validates feature folders before delivery.

## Coding Style & Naming Conventions
- Stick to Swift 5.9 defaults: four-space indentation, trailing commas for multiline collections, and `private` access unless broader scope is required.
- Types use PascalCase, members camelCase; suffix view models with `ViewModel` and keep one primary type per file mirroring its directory.
- Mark sections with `// MARK:` and add `///` docs when APIs cross modules; prefer preview fixtures for `#Preview`.

## Testing Guidelines
- Add focused `@Test func testScenario_whenCondition_thenOutcome()` cases in `AstroSvitlaTests`, using `#expect` and async APIs for concurrency.
- Mirror UI flows in `AstroSvitlaUITests` with `XCUIApplication()` and wrap performance checks in `measure {}` when it matters.
- Cover every new rule or transformation; call out deliberate gaps in the PR if something stays untested.

## Commit & Pull Request Guidelines
- Follow history: imperative, sentence-case subjects under 72 characters (e.g., `Add onboarding timeline model`), optional body after a blank line.
- Reference specs or issues with `#ID`, and note migrations or scripts in the body for future rollbacks.
- PRs need a concise summary, test checklist (`xcodebuild test`, manual notes), screenshots for UI tweaks, and a link to the matching `specs/NNN-*` folder.

## Security & Configuration Tips
- Keep `Config.swift` local by replacing real API keys with placeholders before pushing and rotating any exposed values immediately.
- Add feature toggles or secrets through `Config` structs, default them to safe states, and document dependencies in team runbooks.
