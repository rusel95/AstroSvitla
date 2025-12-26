# Implementation Plan: In-App Purchase System for AI Astrological Reports

**Branch**: `008-implement-in-app` | **Date**: 2025-12-23 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/008-implement-in-app/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement a consumable in-app purchase system for the Zorya natal chart app that monetizes AI-generated astrological reports. Users can purchase individual report types (Personality Analysis, Career Insights, Relationship Compatibility, Wellness & Energy) at $4.99 per report, with each purchase providing one report generation credit. The system uses StoreKit 2 for platform purchase verification, stores all data locally using SwiftData (no server backend), supports multiple user profiles with global credit pool, and enables purchase restoration. The MVP targets Ukrainian-speaking users with a simplified 2-3 tap purchase flow designed for New Year launch.

## Technical Context

**Language/Version**: Swift 5.9+ (iOS 17+ SDK minimum per constitution)
**Primary Dependencies**:
- StoreKit 2 (native iOS framework for in-app purchases)
- SwiftUI (UI framework per constitution)
- SwiftData (local persistence per constitution)
- Combine (reactive state management for purchase transactions)

**Storage**: SwiftData for local persistence of:
- Purchase credits (consumable, tracked per report type)
- Purchase records (transaction history with platform transaction IDs)
- Report generation history (which profile generated which reports)

**Testing**: Swift Testing framework with XCTest compatibility
- Contract tests for StoreKit product configurations
- Unit tests for credit management service
- Integration tests for purchase → credit → generation flow
- UI tests for paywall and purchase flow

**Target Platform**: iOS 17+ (iPhone and iPad)

**Project Type**: Mobile (iOS native application)

**Performance Goals**:
- Purchase flow: 2-3 taps from paywall to purchase confirmation (FR-004)
- Report generation: <5 seconds after purchase completion (SC-007)
- Purchase restoration: <10 seconds for transaction sync (SC-003: 95% success rate)
- UI responsiveness: <100ms for all purchase UI interactions

**Constraints**:
- Local-only architecture: No server backend, all data stored on device
- Platform purchase verification: StoreKit 2 handles validation, no custom receipt validation
- Offline-capable: Credit tracking and paywall display work without network (purchase requires network)
- Localization: Ukrainian language support for MVP with future international expansion

**Scale/Scope**:
- 4 distinct report types (Personality Analysis, Career Insights, Relationship Compatibility, Wellness & Energy)
- Unlimited profiles per device (self, family, friends)
- Global credit pool shared across profiles
- Purchase history limited only by device storage
- MVP focus: Simple, reliable purchase flow without analytics dashboard

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Spec-Driven Development
✅ **PASS** - Complete specification exists at `specs/008-implement-in-app/spec.md` with clarified requirements, user stories, functional requirements, and success criteria.

### II. SwiftUI & Modern iOS Architecture
✅ **PASS** - Plan specifies:

- Swift 5.9+ targeting iOS 17+ SDK
- SwiftUI for all UI (paywall, purchase confirmation screens)
- MVVM architecture with protocol-based DI for services
- SwiftData for persistence (purchase credits, records)
- Features organized under `Features/Purchase/` with co-located views/viewmodels

### III. Test-First Reliability
✅ **PASS** - Testing strategy defined:

- Contract tests for StoreKit product configurations
- Unit tests for `PurchaseService`, `CreditManager`
- Integration tests for purchase → credit allocation → report generation flow
- UI tests for paywall and purchase UX
- Target: ≥80% coverage with 100% on critical payment paths (per constitution)

### IV. Secure Configuration & Secrets Hygiene
✅ **PASS** - No API keys or secrets required for MVP:

- StoreKit 2 uses platform-managed authentication
- Product IDs configured in App Store Connect (public identifiers)
- No server backend = no backend credentials
- Future: If analytics added, follow Config.swift pattern

### V. Performance & User Experience Standards
✅ **PASS** - Performance targets align with constitution:

- UI interactions: <100ms (FR-004: 2-3 taps)
- Purchase completion: <5 seconds (SC-007)
- Offline support: Credit display and paywall work offline (purchase requires network)
- Error handling: User-friendly messages for purchase failures (FR-016)
- Graceful degradation: Show cached credit balance when offline

**Overall Status**: ✅ **ALL GATES PASS** - Ready to proceed to Phase 0 research.

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

```
AstroSvitla/
├── App/
│   └── AstroSvitlaApp.swift                    # App entry point, environment setup
│
├── Features/
│   ├── Purchase/                                # NEW: In-app purchase feature
│   │   ├── Models/
│   │   │   ├── PurchaseCredit.swift           # SwiftData model for credits
│   │   │   ├── PurchaseRecord.swift           # SwiftData model for transactions
│   │   │   └── ProductIdentifier.swift        # Enum for StoreKit product IDs
│   │   ├── Services/
│   │   │   ├── PurchaseService.swift          # StoreKit 2 transaction handling
│   │   │   ├── CreditManager.swift            # Credit allocation/consumption logic
│   │   │   └── ProductConfigurationService.swift # Load/validate products
│   │   ├── ViewModels/
│   │   │   ├── PaywallViewModel.swift         # Paywall presentation logic
│   │   │   └── PurchaseFlowViewModel.swift    # Purchase state management
│   │   └── Views/
│   │       ├── PaywallView.swift              # Report purchase paywall
│   │       ├── PurchaseConfirmationView.swift # Post-purchase confirmation
│   │       └── CreditBalanceView.swift        # Display available credits
│   │
│   ├── ReportGeneration/                       # EXISTING: Report generation
│   │   └── [integrate with credit consumption]
│   │
│   └── UserManagement/                         # EXISTING: Profile management
│       └── [credit tracking per profile]
│
├── Models/
│   ├── Domain/
│   │   └── ReportArea.swift                   # EXISTING: Report type enum
│   └── SwiftData/
│       ├── ReportPurchase.swift               # EXISTING: May need updates
│       ├── PurchaseCredit.swift               # NEW: From Features/Purchase/Models
│       └── PurchaseRecord.swift               # NEW: From Features/Purchase/Models
│
├── Services/                                   # Shared services
│   └── [Existing services remain unchanged]
│
├── Utils/
│   └── LocalizationKeys.swift                 # NEW: Ukrainian purchase strings
│
└── Config/
    └── Config.swift                           # No changes needed (no secrets)

AstroSvitlaTests/
├── Features/
│   └── Purchase/
│       ├── Contract/
│       │   └── StoreKitProductContractTests.swift  # Validate product configs
│       ├── Unit/
│       │   ├── PurchaseServiceTests.swift          # Purchase flow logic
│       │   ├── CreditManagerTests.swift            # Credit allocation/consumption
│       │   └── ProductConfigurationServiceTests.swift
│       ├── Integration/
│       │   └── PurchaseToReportFlowTests.swift     # End-to-end purchase → generation
│       └── UI/
│           ├── PaywallViewTests.swift              # Paywall UI behavior
│           └── PurchaseFlowUITests.swift           # 2-3 tap flow verification
│
└── Fixtures/
    └── StoreKitTestConfiguration.storekit      # Local StoreKit test config
```

**Structure Decision**: iOS mobile structure per constitution. Features organized by capability with co-located views/viewmodels/services. Purchase feature is self-contained under `Features/Purchase/` with clear boundaries to existing report generation and user management features. SwiftData models consolidated in `Models/SwiftData/` for app-wide access. Testing follows TDD requirement with contract/unit/integration/UI test separation.

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

No violations. All constitution gates passed.

## Phase 0: Research (Complete)

**Status**: ✅ Complete

**Output**: [research.md](research.md)

**Key Decisions**:
1. **Consumable IAP**: Use consumable products (not non-consumable) for 1 purchase = 1 report model
2. **StoreKit 2**: Modern async/await APIs with automatic cryptographic verification
3. **Global Credit Pool**: Credits usable for any profile (not profile-locked)
4. **Product Configuration**: Single $4.99 product for MVP, credit packs deferred post-MVP
5. **Local Verification**: StoreKit 2 automatic JWS verification, no server backend
6. **SwiftData Models**: Two models (PurchaseCredit, PurchaseRecord) with cascade delete relationship

**Research Topics Resolved**:
- ✅ StoreKit 2 consumable purchase patterns
- ✅ Local credit tracking with SwiftData
- ✅ Purchase verification without server
- ✅ Restore purchases for consumables
- ✅ Transaction monitoring lifecycle
- ✅ Product configuration in App Store Connect
- ✅ Error handling strategies
- ✅ Testing approach (sandbox + local StoreKit config)

## Phase 1: Design & Contracts (Complete)

**Status**: ✅ Complete

**Outputs**:
- [data-model.md](data-model.md) - SwiftData schema with PurchaseCredit and PurchaseRecord models
- [contracts/storekit-products.md](contracts/storekit-products.md) - Product configuration contract
- [quickstart.md](quickstart.md) - Implementation guide with TDD workflow

**Data Model Summary**:
```swift
@Model PurchaseCredit {
    - id: UUID (unique)
    - reportArea: String
    - purchaseDate: Date
    - consumed: Bool
    - consumedDate: Date?
    - transactionID: String (unique)
    - userProfileID: UUID?
    - purchaseRecord: PurchaseRecord?
}

@Model PurchaseRecord {
    - id: UUID (unique)
    - productID: String
    - transactionID: String (unique)
    - purchaseDate: Date
    - priceUSD: Decimal
    - localizedPrice: String
    - currencyCode: String
    - creditAmount: Int
    - restoredDate: Date?
    - credits: [PurchaseCredit]
}
```

**Contract Summary**:
- **Product ID**: `com.astrosvitla.report.credit.single`
- **Type**: Consumable
- **Price**: Tier 5 ($4.99 USD, ₴199 UAH)
- **Credits**: 1 per purchase
- **Localizations**: English + Ukrainian

## Phase 2: Implementation

**Status**: ⏸️ Pending - Use `/speckit.tasks` to generate task breakdown

**Next Command**: `/speckit.tasks` to create ordered implementation tasks

## Implementation Readiness

**Prerequisites Complete**:
- ✅ Specification finalized with clarifications
- ✅ Constitution check passed (all gates)
- ✅ Research complete with all technical decisions made
- ✅ Data model designed and documented
- ✅ StoreKit contract defined
- ✅ Testing strategy defined (contract/unit/integration/UI)
- ✅ Quickstart guide created for developers
- ✅ Agent context updated (CLAUDE.md)

**Ready For**:
- Task generation (`/speckit.tasks`)
- Implementation (`/speckit.implement`)

## Key Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Product not loading from App Store | Medium | High | StoreKit config file for local testing |
| Duplicate credit delivery | Low | High | Transaction ID uniqueness constraint in SwiftData |
| Purchase interruption (app crash) | Medium | Medium | Transaction listener recovers unfinished purchases |
| User confusion about consumable model | Medium | Medium | Clear paywall copy + "Restore only recovers interrupted purchases" |
| Sandbox testing issues | High | Low | Documented troubleshooting in quickstart.md |

## Success Metrics (From Spec)

**Performance Targets**:
- ⏱️ Purchase flow: 2-3 taps (FR-004)
- ⏱️ Report generation: <5s after purchase (SC-007)
- ⏱️ UI responsiveness: <100ms (constitution)
- ⏱️ Restore purchases: <10s (SC-003)

**Quality Targets**:
- 📊 Transaction integrity: 100% (SC-004)
- 📊 Restore success rate: 95% (SC-003)
- 📊 First-time purchase success: 95% (SC-009)
- 📊 Test coverage: ≥80% (constitution)
