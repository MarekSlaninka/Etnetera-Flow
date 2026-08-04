# AI-Assisted iOS Engineering Playbook

This repository includes a small, reusable set of AI workflows for delivering and reviewing native iOS work. They are project-neutral: they contain no client data, internal infrastructure details, or proprietary release processes.

## What the playbook demonstrates

- Intentional Clean Architecture across domain, persistence, and SwiftUI presentation.
- Modern iOS development with SwiftUI, Observation, Swift Concurrency, SwiftData, and Swift Testing.
- Controlled AI collaboration: clarify behavior, make the smallest useful change, and verify the result.
- Practical quality gates for testing, async-resource ownership, accessibility, and localisation.

## Included workflows

| Workflow | Typical prompt | Outcome |
| --- | --- | --- |
| `ios-feature-delivery` | “Add a new way to filter performances.” | A minimal vertical slice across domain, data, presentation, and tests. |
| `ios-swiftui-state` | “Review this SwiftUI form.” | Correct state ownership, composable views, accessibility, and efficient rendering. |
| `ios-concurrency-safety` | “Make this repository call async.” | Clear isolation boundaries, structured tasks, and cancellation without unsafe escape hatches. |
| `ios-test-and-refactor` | “Simplify this view model safely.” | A test-first refactor with focused regression coverage. |

## How it is used

The repository-level [AGENTS.md](AGENTS.md) defines baseline rules. A task then loads only its relevant skill, which keeps guidance precise without carrying unrelated process into the task.

The goal is not code generation for its own sake. It is a repeatable engineering conversation: clarify the behavior, choose the smallest appropriate design, make the change, and verify the observable result.
