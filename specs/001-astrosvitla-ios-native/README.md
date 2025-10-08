# Feature 001: AstroSvitla - iOS Natal Chart & AI Predictions App

> **Status**: Draft - Ready for Implementation
> **Created**: 2025-10-07
> **Branch**: `001-astrosvitla-ios-native`

---

## 📋 Quick Links

- **[Specification](./spec.md)** - Complete feature requirements (WHAT & WHY)
- **[Implementation Plan](./plan.md)** - Technical approach and architecture (HOW)
- **[Data Model](./data-model.md)** - SwiftData schema and domain models
- **[Tasks](./tasks.md)** - Detailed implementation task breakdown

---

## 🎯 Feature Overview

**AstroSvitla** is a native iOS astrology app that provides personalized natal chart calculations and AI-powered life area predictions using a pay-per-report business model.

### Core Value Proposition

Users pay only for specific life area reports they want ($5.99-$9.99), avoiding expensive subscriptions while receiving expert-quality astrological insights powered by AI.

### Key Features

✅ **Accurate Natal Charts** - NASA-level astronomical precision using SwissEphemeris
✅ **AI-Powered Reports** - Personalized predictions based on expert astrology rules
✅ **Pay-Per-Report** - Buy individual reports, no subscriptions
✅ **5 Life Areas** - Finances, Career, Relationships, Health, General Overview
✅ **Bilingual** - Full English and Ukrainian support
✅ **Offline-First** - Local storage, privacy-focused
✅ **Native iOS** - SwiftUI + SwiftData on iOS 17+

---

## 🏗️ Technical Stack

| Component | Technology |
|-----------|------------|
| **Platform** | iOS 17+ (iPhone only, portrait) |
| **UI Framework** | SwiftUI |
| **Persistence** | SwiftData |
| **Architecture** | MVVM + Clean Architecture |
| **Chart Calculations** | SwissEphemeris (SPM) |
| **AI Integration** | OpenAI GPT-4 API |
| **In-App Purchases** | StoreKit 2 |
| **Localization** | English + Ukrainian |
| **Geocoding** | CoreLocation |

---

## 📊 Project Structure

```
specs/001-astrosvitla-ios-native/
├── README.md              # This file
├── spec.md                # Feature specification (business requirements)
├── plan.md                # Implementation plan (technical approach)
├── data-model.md          # SwiftData schema documentation
└── tasks.md               # Detailed task breakdown (200+ tasks)
```

---

## 🚀 Getting Started

### Prerequisites

Before starting implementation, ensure you have:

1. **Development Environment**
   - macOS 14.0+ (Sonoma)
   - Xcode 15.0+
   - iOS 17.0+ SDK

2. **External Dependencies**
   - OpenAI API key ([get one here](https://platform.openai.com/api-keys))
   - Expert astrology rules content (JSON files)
   - App Store Connect account (for IAP products)

3. **Knowledge Requirements**
   - Swift 5.9+
   - SwiftUI
   - SwiftData (iOS 17+)
   - Async/await concurrency
   - StoreKit 2

### Installation Steps

1. **Clone repository and checkout feature branch**
   ```bash
   git checkout 001-astrosvitla-ios-native
   ```

2. **Create Xcode project** (see [plan.md](./plan.md) Phase 1.1)
   ```bash
   # Open Xcode > New Project > iOS App
   # Product Name: AstroSvitla
   # Organization: com.astrosvitla
   # Interface: SwiftUI
   # iOS Deployment: 17.0
   ```

3. **Add Swift Package Dependencies**
   - SwissEphemeris: `https://github.com/vsmithers1087/SwissEphemeris`

4. **Setup API keys**
   ```bash
   cp AstroSvitla/App/Config.swift.example AstroSvitla/App/Config.swift
   # Edit Config.swift and add your OpenAI API key
   ```

5. **Verify .gitignore**
   ```bash
   # Ensure Config.swift is gitignored
   git status  # Should NOT show Config.swift
   ```

---

## 📖 Implementation Guide

### Development Phases

Follow the implementation plan in sequential order:

| Phase | Duration | Focus |
|-------|----------|-------|
| **Phase 0** | 2 days | Research & Validation |
| **Phase 1** | 3 days | Core Foundation (Models, Setup) |
| **Phase 2** | 5 days | Chart Calculation Engine |
| **Phase 3** | 3 days | UI - Data Input |
| **Phase 4** | 2 days | Chart Visualization |
| **Phase 5** | 5 days | AI Report Generation |
| **Phase 6** | 5 days | Purchase Flow |
| **Phase 7** | 5 days | Report Display & Export |
| **Phase 8** | 5 days | Localization |
| **Phase 9** | 5 days | Testing & QA |
| **Phase 10** | 5 days | App Store Preparation |

**Total**: ~10 weeks to App Store launch

### Test-Driven Development

⚠️ **CRITICAL**: Follow TDD approach per [Constitution Article III](../../memory/constitution.md)

1. Write tests first (unit, integration, UI)
2. Verify tests fail (Red phase)
3. Implement feature
4. Verify tests pass (Green phase)
5. Refactor if needed

### Key Milestones

- ✅ **Week 1**: Foundation complete (models, structure)
- ✅ **Week 2**: Chart calculation working (verified against reference)
- ✅ **Week 3**: Basic UI complete (input, visualization)
- ✅ **Week 4**: AI integration complete (reports generating)
- ✅ **Week 5**: Purchase flow complete (StoreKit working)
- ✅ **Week 6**: Reports complete (display, export, list)
- ✅ **Week 7**: Localization complete (English + Ukrainian)
- ✅ **Week 8**: Testing complete (unit, integration, UI, accessibility)
- ✅ **Week 9**: App Store ready (assets, privacy, TestFlight)
- ✅ **Week 10**: Launch! 🚀

---

## 🧪 Testing Strategy

### Test Coverage Targets

- **Chart Calculations**: 90%+
- **Data Models**: 85%+
- **ViewModels**: 80%+
- **Services**: 85%+

### Test Types

1. **Unit Tests** - Business logic, calculations, models
2. **Integration Tests** - API calls, database operations
3. **UI Tests** - User flows, navigation
4. **Snapshot Tests** - Visual regression
5. **UI QA Checks** - Layout validation across devices and themes

### Performance Benchmarks

- App launch: <2 seconds
- Chart calculation: <3 seconds
- Report generation: <10 seconds
- UI interactions: 60 FPS
- Crash-free rate: >99%

---

## 📱 App Store Information

### Product Name
**AstroSvitla: Natal Chart**

### Category
- Primary: Lifestyle
- Secondary: Entertainment

### Target Audience
- Age: 25-44 (primary)
- Language: English speakers, Ukrainian speakers
- Interest: Astrology, self-improvement, wellness

### Pricing Model
**Pay-per-report** (non-consumable in-app purchases):
- General Overview: $9.99
- Finances: $6.99
- Career: $6.99
- Relationships: $5.99
- Health: $5.99

### Success Metrics

| Metric | Month 1 | Month 3 | Month 6 |
|--------|---------|---------|---------|
| Downloads | 100 | 1,000 | 5,000 |
| Revenue | $200-300 | $2,000-2,500 | $10,000-15,000 |
| Conversion | 30% | 35% | 40% |
| Rating | 4.5+ | 4.5+ | 4.5+ |

---

## 🔐 Privacy & Security

### Data Handling

- ✅ **Local storage only** - No cloud sync in MVP
- ✅ **No user accounts** - Anonymous usage
- ✅ **No analytics** - No tracking or telemetry
- ✅ **No PII collection** - Birth data not personally identifiable
- ✅ **GDPR compliant** - User controls all data

### API Key Security

⚠️ **CRITICAL**: Never commit API keys to git!

```swift
// Config.swift (GITIGNORED)
struct APIConfig {
    static let openAIKey = "sk-proj-..." // Your key here
}
```

---

## 📚 Additional Resources

### Documentation

- [SwissEphemeris Documentation](https://github.com/vsmithers1087/SwissEphemeris)
- [OpenAI API Documentation](https://platform.openai.com/docs)
- [StoreKit 2 Documentation](https://developer.apple.com/documentation/storekit)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)

### Reference Materials

- Professional astrology software for calculation verification
- Astrology interpretation rules from expert consultant
- OpenAI prompt engineering best practices

---

## 🐛 Known Issues & Limitations

### MVP Limitations

❌ Not included in initial release:
- Transits and predictions
- Synastry (compatibility) charts
- Progressions
- Social sharing features
- Cloud sync
- Android app
- User accounts

### Technical Constraints

- iOS 17+ only (SwiftData requirement)
- iPhone only, portrait orientation
- Requires internet for initial report generation
- Local storage only (no multi-device sync)

---

## 🤝 Contributing

### Code Review Checklist

Before submitting code:

- [ ] All tests pass (unit, integration, UI)
- [ ] Code follows Swift style guide
- [ ] SwiftUI best practices followed
- [ ] UI QA sweep completed (layout, dark mode, manual smoke tests)
- [ ] Localized strings added (English + Ukrainian)
- [ ] Performance benchmarks met
- [ ] No API keys in code
- [ ] Constitutional compliance verified

### Pull Request Template

```markdown
## Feature: [Brief description]

### Changes
- [List key changes]

### Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] UI tests pass
- [ ] Manual testing completed

### Constitutional Compliance
- [ ] Article II: SwiftUI/SwiftData native ✅
- [ ] Article III: TDD followed ✅
- [ ] Article IV: Performance targets met ✅
- [ ] Article V: UI polish complete ✅

### Screenshots
[Add before/after screenshots if UI changes]
```

---

## 📞 Support

### Questions or Issues?

1. Check [spec.md](./spec.md) for requirements clarification
2. Check [plan.md](./plan.md) for technical approach
3. Check [tasks.md](./tasks.md) for specific task details
4. Consult [Constitution](../../memory/constitution.md) for architectural guidance

---

## 📄 License

This project follows the AstroSvitla repository license.

---

## ✨ Acknowledgements

- **PRD Source**: Original product requirements document
- **Astrology Expertise**: Professional astrologer consultant
- **AI Technology**: OpenAI GPT-4
- **Astronomical Calculations**: SwissEphemeris library
- **Apple Frameworks**: SwiftUI, SwiftData, StoreKit 2

---

**Last Updated**: 2025-10-07
**Next Review**: Before Phase 1 implementation begins
