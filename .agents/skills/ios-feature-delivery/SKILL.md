---
name: ios-feature-delivery
description: Deliver focused user-facing features in Etnetera Flow across its Domain, Data, and Presentation layers with SwiftUI and Swift Testing. Use when adding or extending a capability such as a performance field, filter, storage behavior, screen, or repository operation; do not use for isolated bug fixes or pure refactors.
---

# iOS Feature Delivery

Implement the smallest complete vertical slice that satisfies the requested user behavior. Keep dependency direction and established project patterns intact.

## Workflow

1. Read `AGENTS.md`, target production files, related tests, and one neighboring implementation.
2. Restate the observable outcome and identify the smallest affected layers.
3. Keep dependencies pointing inward: entities and protocols in `Domain`; framework integrations in `Data`; views and view models in `Presentation`.
4. Reuse the `SportPerformanceRepository` seam and existing use cases for performance reads and writes. Do not let a view model reach Firebase or SwiftData directly.
5. Add deterministic Swift Testing coverage for new behavior and failure paths, using the existing stub repository for unit-level tests.
6. Run the narrowest relevant verification when available and report checks that could not be run.

## Design checks

- Preserve local and remote storage semantics; source is routing and presentation information, not duplicated persistence data.
- Keep validation near the interaction boundary unless it must apply to every caller, then place it in the domain operation.
- Localise user-facing copy, show recoverable errors, and add new files to the appropriate Xcode target.

## Done criteria

- The requested behavior works through the intended UI and storage path.
- The implementation adds no unnecessary architectural or dependency changes.
- Relevant domain, view-model, or data-routing behavior has focused test coverage.
