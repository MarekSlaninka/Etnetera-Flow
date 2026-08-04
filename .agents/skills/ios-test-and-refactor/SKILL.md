---
name: ios-test-and-refactor
description: Choose focused iOS test coverage and safely refactor Etnetera Flow Swift code using Swift Testing, test doubles, and behavior-preserving checks. Use when writing or improving unit tests, deciding a test level, simplifying existing logic, extracting functions, or restructuring a view model, use case, repository, or mapper.
---

# iOS Test and Refactor

Protect observable behavior before changing structure. Prefer small deterministic tests at the lowest level that meaningfully proves the behavior.

## Choose the test level

- Use **unit tests** for domain entities, use cases, view models, filters, ordering, mappings, and error-state transitions.
- Use **integration tests** for a repository plus an in-memory SwiftData container or another real collaborator boundary.
- Use **UI tests** only when rendering, navigation, or accessibility behavior cannot be proven below the view layer.
- Keep Firebase, network access, and persistent device state out of unit tests through a stub, fake, or spy.

## Refactoring workflow

1. Read the target type, callers, and existing tests. List meaningful branches, errors, and edge cases.
2. Add focused Swift Testing coverage for unprotected behavior; use `@Test` and `#expect` for new tests.
3. Run the affected tests before the refactor when practical.
4. Make the smallest structural change that preserves the contract.
5. Run the same tests again and inspect the diff for accidental behavior changes.

## Test quality

- Name test files after the subject under test and keep each test independent and deterministic.
- Assert observable values and interactions rather than implementation details.
- Cover success, validation/error, empty, ordering, and filtering edges where they exist.
- Avoid `try!` and force unwraps in tests; make failures clear instead.

## Done criteria

- The selected test level validates the changed behavior without unnecessary infrastructure.
- A refactor is backed by passing targeted tests before and after the structural change.
- Production behavior is unchanged except for the explicitly requested outcome.
