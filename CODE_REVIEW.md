# Code Review Guide for Zenith (iOS / SwiftUI)

This guide is for agents and developers reviewing code submitted to the Zenith project. It covers what to look for, common pitfalls, and project-specific conventions derived from [AGENTS.md](./AGENTS.md).

---

## 1. State Management

State management bugs are the most common source of SwiftUI issues. Verify:

- **`@State` is used only for local, view-owned value types.** If state is shared across views or is a reference type, it's wrong.
- **`@Binding` is used to pass writable state down** from a parent — never created out of thin air.
- **`@Environment(\.modelContext)` is used for SwiftData writes**, not passed around manually.
- **`@Query` is used for SwiftData reads in views** — check that sort descriptors and predicates are correct. Avoid fetching more data than the view needs.
- **No duplicate sources of truth.** If the same piece of data lives in `@State` and also in a `@Query`, one of them is wrong.
- **`@FocusState`** should only be used for keyboard/focus management — not as general-purpose state.

### Red flags
- `@State` on a reference type (class) — should be `@StateObject` or refactored.
- `@ObservedObject` used where the view owns the object — should be `@StateObject`.
- State mutations inside `body` (outside of closures/actions) — causes infinite re-render loops.

---

## 2. View Complexity

Per project convention, views should be **~100 lines or fewer**. When reviewing:

- **Count the lines.** If a view's `body` exceeds ~100 lines, request extraction into child views.
- **Check nesting depth.** More than 3-4 levels of indentation usually means a subview should be extracted.
- **Look for repeated patterns.** If the same layout appears 2+ times with different data, it should be a reusable component (placed in `Views/Shared/`).
- **Verify modifiers aren't doing too much.** Long modifier chains (10+) are a sign the view is handling too many concerns.

---

## 3. Performance

SwiftUI re-evaluates `body` whenever state changes. Subtle mistakes cause excessive redraws.

- **Isolate state to the smallest possible view.** A `@State` property on a parent causes the entire subtree to re-evaluate. Push state down.
- **Use `LazyVStack` / `LazyHStack` for scrollable lists** — not `VStack` inside `ScrollView` with many items.
- **Avoid expensive work in `body`.** Filtering, sorting, and date formatting should happen in computed properties or be cached, not recalculated on every render.
- **Check `@Query` filters.** An unfiltered `@Query` that fetches all records and then filters in a computed property is wasteful — use a predicate instead when possible.
- **Watch for `onChange` / `onAppear` that trigger state changes** leading to cascading re-renders.

### Debugging tip
`let _ = Self._printChanges()` inside `body` reveals what triggered a re-render.

---

## 4. SwiftData

SwiftData is powerful but has sharp edges. Check for:

- **Models use `@Model` macro** and properties use appropriate `@Attribute` annotations (e.g., `.unique` for IDs).
- **All relationships are optional.** SwiftData is unreliable with non-optional relationships. Insert the parent first, then attach children.
- **No model subclassing.** SwiftData does not support class inheritance on `@Model` types.
- **Predicates are simple.** Complex `#Predicate` expressions with local variables or multi-branch logic can crash the compiler. Keep them flat.
- **Concurrency is handled correctly.** `ModelContext` is not `Sendable`. If background work is needed, use `@ModelActor`. Only `PersistentIdentifier` and `ModelContainer` cross actor boundaries safely.
- **Initializers exist** even if all properties have defaults — SwiftData requires them.
- **Deletions handle relationships.** Verify cascade rules or manual cleanup when deleting objects that have relationships.

---

## 5. Navigation and Sheets

Zenith uses sheet-based navigation. Verify:

- **`NavigationStack` is used**, not the deprecated `NavigationView`.
- **Sheet state is clean.** `isPresented` bindings reset properly on dismiss. `item`-based sheets use `Identifiable` types.
- **No nested `NavigationStack`s.** A sheet that contains its own `NavigationStack` is fine, but a `NavigationStack` inside another `NavigationStack` is a bug.
- **`onDismiss` callbacks clean up state** so sheets don't reappear unexpectedly.
- **`.interactiveDismissDisabled()`** is applied to sheets with unsaved data (like entry forms).

---

## 6. Theme and Styling Consistency

Zenith consolidates design tokens in `Utilities/`. During review, check:

- **Colors use `Color.<name>` from `Color+Theme.swift`** — no raw hex/RGB values inline.
- **Fonts use `Font.<name>` from `Font+Theme.swift`** — no ad-hoc `.font(.system(size: 14))` calls.
- **Spacing/padding use `CGFloat.<name>` from `Spacing+Theme.swift`** — no magic numbers for padding or spacing.
- **The `.modify {}` view extension** is used for conditional modifiers (e.g., `@available` checks) instead of ternary expressions or `if/else` in `body`.

### Common violations
- Hardcoded `Color(.systemGray)` instead of a named theme color.
- `.padding(16)` instead of `.padding(.paddingMedium)`.
- `.font(.headline)` instead of the project's `Font.headlineRegular`.

---

## 7. iOS Version Compatibility

Zenith targets iOS 17+ but uses iOS 26 APIs behind availability checks.

- **Every iOS 26+ API call must be wrapped in `#available(iOS 26.0, *)`** with a fallback.
- **Use the `.modify {}` pattern** for availability-gated view modifiers (e.g., `.glassEffect` with `.ultraThinMaterial` fallback).
- **Don't use deprecated APIs.** `NavigationView`, `UIViewRepresentable` when a SwiftUI equivalent exists, `onChange(of:perform:)` (single-parameter form), etc.
- **Test on iOS 17 simulator** as the minimum target — not just the latest OS.

---

## 8. Swift Style

Enforce the project's Swift conventions:

- **`async/await` for all async work** — no completion handlers or raw `DispatchQueue` calls.
- **`guard` for early exits** — not deeply nested `if let` chains.
- **Value types (structs) preferred** over classes unless reference semantics are specifically needed (SwiftData models are the exception).
- **Max line width: 120 characters** (enforced by SwiftFormat, but verify in review).
- **No force unwraps (`!`) without justification.** Acceptable for: compile-time string literal URLs, Calendar operations with controlled inputs. Unacceptable for: optional chaining avoidance, API response parsing.

---

## 9. Memory Management

Swift's ARC handles most memory, but closures and reference types introduce risks.

- **Use `[weak self]` in escaping closures** that capture `self` (network callbacks, timers, Combine subscribers). Omitting this on a class-based object creates a retain cycle.
- **`unowned` is only safe when the captured object's lifetime is guaranteed** to outlast the closure. When in doubt, use `weak`.
- **Combine subscriptions must be stored** in a `Set<AnyCancellable>` or cancelled explicitly. Orphaned subscriptions leak.
- **Timers must be invalidated** in cleanup (e.g., `onDisappear` or `deinit`).
- **Check closures on `sheet`, `onChange`, `task`, `onAppear`** — if they capture a reference type strongly and that type holds the view's state, you may have a cycle.

---

## 10. Networking

Zenith uses a protocol-based networking layer (`APIClient` with `LiveAPIClient` / `MockAPIClient`).

- **New API calls must be added to the `APIClient` protocol** first, then implemented in both Live and Mock.
- **Response status codes should be checked.** Discarding the response (e.g., `let (data, _) = try await session.data(...)`) without checking for HTTP errors is a bug in production code.
- **Request/response types belong in `Networking/DTOs/`** — not inline in views or services.
- **Error handling must be user-facing.** Network calls should surface failures to the UI, not silently fail.
- **No hardcoded URLs in views or services** — they belong in the API client.

---

## 11. Security

Even for a client-side iOS app, security matters.

- **No secrets in source code.** API keys, tokens, and credentials must not be hardcoded. Use Keychain or environment-based configuration.
- **Validate external input.** Data from APIs, user text fields, and deep links should be validated before use.
- **Use HTTPS exclusively.** No `http://` URLs in production code (local development URLs are acceptable in mock/debug configurations only).
- **Check Info.plist.** Ensure no sensitive configuration is exposed, and that `NSAppTransportSecurity` exceptions are justified.
- **Avoid logging sensitive data.** `print()` and `os_log` calls should never include tokens, passwords, or PII.

---

## 12. Testing

- **New ViewModels and Services require unit tests** using the Swift Testing framework (`@Test`, `#expect`).
- **Use `MockAPIClient`** for tests that involve networking — never hit real endpoints in tests.
- **Test edge cases:** empty states, maximum values, invalid input, date boundaries.
- **SwiftData tests should use an in-memory container** to avoid polluting the on-disk store.

---

## Quick Reference Checklist

Use this as a final pass before approving:

| Area | Check |
|------|-------|
| State | Correct property wrapper for the use case |
| View size | `body` is ~100 lines or fewer |
| Performance | No expensive work in `body`; lazy stacks for lists |
| SwiftData | `@Model` used correctly; relationships optional; no subclassing |
| Navigation | `NavigationStack` only; sheets clean up state |
| Theme | All colors, fonts, spacing use theme constants |
| Compatibility | iOS 26 APIs gated behind `#available` with fallback |
| Swift style | `async/await`; `guard`; no unjustified force unwraps; 120 char lines |
| Memory | `[weak self]` in escaping closures; subscriptions stored |
| Networking | Protocol-first; status codes checked; errors surfaced |
| Security | No hardcoded secrets; HTTPS only; no sensitive logs |
| Testing | Unit tests for new logic; mock API client used |
