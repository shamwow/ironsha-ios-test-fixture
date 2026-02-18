# Project: Zenith

## Quick Reference
- **Platform**: iOS 17+
- **Language**: Swift 5.0
- **UI Framework**: SwiftUI
- **Persistence**: SwiftData
- **Minimum Deployment**: iOS 17.0
- **Formatter**: SwiftFormat (run via Xcode build phase)

## Project Structure
```
Zenith/
├── ZenithApp.swift              # @main App entry point (SwiftData container)
├── ContentView.swift            # Root view: NavigationStack, bottom toolbar, sheet routing
├── Extensions/
│   └── ViewExtensions.swift
├── Models/
│   ├── FoodEntry.swift          # SwiftData model
│   └── UserSettings.swift       # SwiftData model
├── Networking/
│   ├── APIClient.swift          # Protocol
│   ├── LiveAPIClient.swift
│   ├── MockAPIClient.swift
│   └── DTOs/                    # Request/Response types
├── Services/
│   ├── PhotoRecognitionService.swift
│   └── SyncService.swift
├── Utilities/
│   ├── Color+Theme.swift        # App color palette
│   ├── Date+Extensions.swift
│   ├── FlowLayout.swift
│   ├── Font+Theme.swift         # Typography constants
│   └── Spacing+Theme.swift      # Spacing/padding constants
├── Views/
│   ├── AddEntry/                # Food entry creation + photo recognition
│   ├── Dashboard/               # Main screen: calorie ring, macros, recent entries
│   ├── History/                 # Historical entries by day
│   ├── Settings/                # User preferences
│   └── Shared/                  # Reusable view components
└── Assets.xcassets/
```

## Key Architecture Decisions
- **SwiftData** for persistence (not Core Data) — models use `@Model` macro
- **@Environment(\.modelContext)** for data access in views
- **Theme constants** consolidated in `Utilities/` (`Color+Theme`, `Font+Theme`, `Spacing+Theme`)
- **Networking** uses protocol-based abstraction (`APIClient` protocol with Live/Mock implementations)
- **Sheet-based navigation** for add entry, settings, and photo recognition flows
- **iOS 26+ liquid glass** effects with `@available` fallbacks to `.ultraThinMaterial`

## Coding Standards

### Swift Style
- Use `async/await` for all async operations
- Follow Apple's Swift API Design Guidelines
- Use `guard` for early exits
- Prefer value types (structs) over reference types (classes)
- Max line width: 120 characters (enforced by SwiftFormat)

### SwiftUI Patterns
- Use `@State` for local view state only
- Use `@Environment` for dependency injection
- Use `@Query` for SwiftData fetch requests in views
- Prefer `NavigationStack` over deprecated `NavigationView`
- Use `.modify {}` view extension for conditional modifiers

### Testing
- Use Swift Testing framework (`@Test`, `#expect`) for new tests
- Unit tests for all ViewModels and Services

## DO NOT
- Use deprecated APIs (UIKit when SwiftUI suffices)
- Create massive monolithic views (extract at ~100 lines)
- Use force unwrapping (`!`) without justification
- Skip `@available` checks when using iOS 26+ APIs
