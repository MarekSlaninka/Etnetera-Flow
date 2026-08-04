---
name: ios-swiftui-state
description: Build, review, and improve SwiftUI views in Etnetera Flow with correct Observation state ownership, composition, accessibility, localisation, and efficient list rendering. Use for new or modified SwiftUI screens, forms, lists, maps, sheets, navigation, or view-model bindings.
---

# SwiftUI State and Composition

Use the project’s Observation-based approach and keep views declarative. A view renders state and sends intent; business and persistence work belongs outside it.

## Review workflow

1. Read the view, its view model, and the nearest similar screen before changing state ownership.
2. Classify each value as input, local view state, derived display state, or externally owned state.
3. Prefer `@Observable` view models and bindable access only where editing a model property is required. Do not introduce `ObservableObject` or Combine without a compatibility need.
4. Keep UI-state view models `@MainActor`; start asynchronous work from explicit lifecycle or user actions and make cancellation visible.
5. Extract a subview only when it has a coherent visual responsibility or materially improves readability.
6. Verify stable list identity and avoid needlessly recomputing expensive derived values during rendering.

## Product checks

- Use localisation keys or `LocalizedStringResource` for user-facing copy.
- Label controls, source indicators, and destructive actions for VoiceOver.
- Support Dynamic Type and do not use colour as the sole carrier of meaning.
- Confirm destructive deletion and clearly expose loading, empty, and error states.

## Done criteria

- State ownership is explicit and fits the view lifecycle.
- The screen is accessible, localised, and composable.
- The change does not add redundant rendering work.
