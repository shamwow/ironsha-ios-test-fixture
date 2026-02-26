# Architecture

Zenith is a calorie-tracking iOS app built with SwiftUI and SwiftData targeting iOS 17+.

## High-Level Overview

```
┌──────────────────────────────────────────────────┐
│                   ZenithApp                       │
│          (SwiftData ModelContainer)               │
├──────────────────────────────────────────────────┤
│                  ContentView                      │
│        (NavigationStack + Sheet Routing)          │
├────────────┬─────────────┬───────────────────────┤
│ Dashboard  │  AddEntry   │  History / Settings    │
│  Views     │  Views      │  Views                 │
├────────────┴─────────────┴───────────────────────┤
│              Services Layer                       │
│    PhotoRecognitionService  ·  SyncService        │
├──────────────────────────────────────────────────┤
│             Networking Layer                      │
│  APIClient (protocol) → Live / Mock impls         │
├──────────────────────────────────────────────────┤
│             SwiftData Models                      │
│         FoodEntry  ·  UserSettings                │
└──────────────────────────────────────────────────┘
```

## Core Design Decisions

### SwiftData over Core Data

The app uses SwiftData's `@Model` macro for persistence. Views subscribe to data changes directly via `@Query`, eliminating the need for separate ViewModel classes. Write access goes through `@Environment(\.modelContext)`.

This keeps the data flow simple: views observe models, mutate them through the model context, and SwiftUI re-renders automatically.

### No ViewModels

State lives in two places:
- **Persistent state** in SwiftData models, accessed with `@Query`
- **Transient UI state** in `@State` properties local to each view

There are no `ObservableObject` ViewModel classes. This is intentional — SwiftData's `@Query` already provides reactive, auto-updating data subscriptions, making a separate observation layer unnecessary for this app's complexity.

### Sheet-Based Navigation

All navigation beyond the main dashboard uses sheets rather than `NavigationLink` push navigation. ContentView owns the presentation state via `@State` flags and routes to:
- Camera capture (`PhotoCaptureView`)
- Recognition results (`FoodRecognitionResultsView`)
- Manual food entry (`AddEntryView`)
- Settings (`SettingsView`)

This keeps the navigation graph flat and avoids deep NavigationStack hierarchies.

### Protocol-Based Networking

The `APIClient` protocol defines three operations:
- `recognizeFood(request:)` — AI-powered food photo recognition
- `uploadSync(request:)` — push unsynced entries to server
- `downloadSync(request:)` — pull remote changes

`LiveAPIClient` hits a real backend over HTTP. `MockAPIClient` returns hardcoded data with artificial delays for previews and testing. Services accept `APIClient` as a constructor parameter, making the implementation swappable.

### Services as Thin Wrappers

Services (`PhotoRecognitionService`, `SyncService`) wrap the `APIClient` with domain-specific logic:
- `PhotoRecognitionService` handles JPEG compression and base64 encoding before calling the API
- `SyncService` runs a two-phase upload-then-download sync, marks entries as synced, and updates the last sync timestamp

Both are structs with injected `APIClient` dependencies. `SyncService` is `@MainActor` since it mutates SwiftData models that drive the UI.

## Data Model

### FoodEntry

The primary data model. Stores food name, calories, macros (protein/fat/carbs), meal type, serving count, and sync metadata (`needsSync`, `syncedAt`). Computed properties (`totalCalories`, `totalProtein`, etc.) account for the servings multiplier.

### UserSettings

Stores daily nutrition goals (calories, protein, fat, carbs) and sync configuration. Bootstrapped with defaults on first launch if no instance exists.

## View Organization

### Dashboard (`Views/Dashboard/`)

The main screen. Composed of several focused subviews:
- **WeekStripView** — swipeable 7-day calendar with a three-week carousel and visual day-status indicators
- **CalorieRingView** — circular progress bar showing daily calorie consumption vs. goal
- **MacroSummaryView** — three ring visualizations for protein, fat, and carbs
- **RecentEntriesListView** — scrollable list of today's entries with edit/delete via context menus

The dashboard filters entries by the selected date using computed predicates against `@Query` results.

### AddEntry (`Views/AddEntry/`)

Handles three flows: manual entry, prefill from photo recognition, and editing an existing entry. Includes name autocomplete from entry history, inline validation, and a servings stepper.

### History (`Views/History/`)

Groups all entries by day. `HistoryView` shows a day-level summary list; `DayDetailView` drills into a single day's full breakdown.

### Shared (`Views/Shared/`)

Reusable components: `NutritionFormFields` (macro input section), `MacroLabel` (colored nutrient badge), and view extensions.

## Design System

All visual constants are consolidated as Swift extensions in `Utilities/`:

| File | Purpose |
|---|---|
| `Color+Theme.swift` | Brand colors, semantic colors, macro-specific colors |
| `Font+Theme.swift` | Typography scale from page titles to icon sizes |
| `Spacing+Theme.swift` | Spacing, padding, and component dimension constants |

These are accessed as static properties on `Color`, `Font`, and `CGFloat` respectively, keeping style definitions out of view bodies.

## Platform Compatibility

The app targets iOS 17 as its minimum deployment target. iOS 26 liquid glass effects are used where available behind `@available` checks, with `.ultraThinMaterial` as the fallback.

`FlowLayout` is a custom `Layout` implementation used for wrapping nutrient pill tags in entry cards.
