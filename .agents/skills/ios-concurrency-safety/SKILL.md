---
name: ios-concurrency-safety
description: Design and review Swift Concurrency code in Etnetera Flow, including async repository operations, tasks, actor isolation, cancellation, Sendable types, and callback-based Firebase or MapKit integrations. Use when adding or changing async/await, Task usage, observation lifetime, data-race fixes, or concurrency warnings.
---

# Swift Concurrency Safety

Make ownership and isolation explicit before changing code. Prefer a correct model over compiler-silencing annotations.

## Workflow

1. Inspect the enclosing type, relevant call sites, and Swift language mode.
2. Name the isolation boundary: main actor for UI state, a dedicated actor for shared mutable background state, or no actor only for immutable/sendable values.
3. Prefer structured concurrency. Bind a `Task` to an owner and cancel it when a newer request supersedes it.
4. Treat callbacks and listener registrations as owned resources. Arrange cleanup in cancellation and deinitialisation paths.
5. Keep network, persistence, and search work off the main actor where safe; publish UI state back to the main actor.
6. Exercise success, failure, cancellation, and repeated-request behavior in focused tests where practical.

## Constraints

- Do not use `Task.detached`, `@unchecked Sendable`, `nonisolated(unsafe)`, or `@preconcurrency` merely to silence diagnostics. Explain and document an unavoidable exception.
- Do not mark an entire subsystem `@MainActor` solely to remove a race warning.
- Preserve the explicit observation lifecycle between `PerformanceObserver` and repository implementations.

## Done criteria

- Every mutable value has a justified isolation boundary.
- Long-running work and listener registrations have an explicit owner and cancellation path.
- The result does not conceal races behind unsafe annotations.
