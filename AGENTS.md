# Etnetera Flow – project instructions

- Preserve existing uncommitted user changes. Do not create, switch, or reset Git branches unless the user explicitly requests it.

## Engineering guardrails

- Keep changes focused on the requested outcome and match existing patterns.
- Preserve dependency direction: `Presentation` depends on `Domain`; `Data` implements `Domain` protocols; `Domain` has no UI or persistence dependencies.
- Prefer SwiftUI, Swift Concurrency, and Observation. Do not introduce a parallel pattern without a concrete reason.
- Keep UI state main-actor isolated, make cancellation and observation lifetimes explicit, and cover changed behavior with deterministic Swift Testing tests.
- Do not hard-code secrets or Firebase configuration. Preserve accessibility, localisation, and stable list identity in UI work.

## Local AI skills

Reusable, project-neutral workflows live in `.agents/skills/`: `ios-feature-delivery`, `ios-swiftui-state`, `ios-concurrency-safety`, and `ios-test-and-refactor`.
