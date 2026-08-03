# Flow

An iOS app for recording sport performances, where every entry is stored either **locally** (SwiftData) or **remotely** (Cloud Firestore). The list merges both sources into a single live feed and can be filtered by storage type.

## Features

- Add, edit and delete a sport performance (name, location, duration)
- Choose per entry whether it is saved locally or remotely
- Live list that merges local and remote entries and updates as either source changes
- Filter the list by all / local / remote
- Search by name or location, ignoring case and diacritics

## Requirements

- Xcode 26 or newer
- iOS 26 deployment target (also builds for macOS 26)
- Swift Package Manager resolves [firebase-ios-sdk](https://github.com/firebase/firebase-ios-sdk) on first open

## Running the app

```bash
git clone https://github.com/MarekSlaninka/Etnetera-Flow.git
cd Etnetera-Flow
```

The app needs a Firebase config file, which is not part of this repository. **I will send you `GoogleService-Info.plist` separately** — drop it in next to the template:

```
Etnetera-Flow/GoogleService-Info.plist
```

Then open the project, wait for Xcode to resolve the Firebase package, and build:

```bash
open Etnetera-Flow.xcodeproj
```

`GoogleService-Info.plist.example` in the repository root shows the expected structure if you would rather point the app at your own Firebase project. In that case create an iOS app with bundle ID `ms.sk.etnetera.flow`, enable **Anonymous** sign-in under Authentication, create a Firestore database, and deploy `firestore.rules`.

Remote entries are scoped to an anonymous Firebase Auth user, so each device gets its own private set of documents.

## Architecture

The project follows a Clean Architecture split, with dependencies pointing inwards towards `Domain`.

```
Domain/        Entities and use cases. No framework imports beyond Foundation.
Data/          Repository implementations for SwiftData and Firestore.
Presentation/  SwiftUI views and their view models.
```

The key seam is `SportPerformanceRepository`, defined in `Domain` and implemented three times:

| Implementation | Role |
| --- | --- |
| `SwiftDataSportPerformanceRepository` | Local persistence |
| `FirestoreSportPerformanceRepository` | Remote persistence |
| `StorageRoutingSportPerformanceRepository` | Routes writes by `StorageType` and merges both read streams |

Because view models depend only on the protocol, `PreviewData.swift` can supply an in-memory double for SwiftUI previews without touching either backing store.

Use cases (`SaveSportPerformanceUseCase`, `UpdateSportPerformanceUseCase`, `DeleteSportPerformanceUseCase`) name the write operations the app supports and are the only way the view models reach the repository. Input validation and trimming currently sit in the view models, so the use cases stay thin — they are a seam for rules that do not exist yet rather than a place where logic lives today.

The domain entity carries no serialization: `SportPerformanceRecord` is the SwiftData model and `SportPerformanceDocument` the Firestore one, each mapping to and from `SportPerformance` at the edge of `Data`.

## Tests

```bash
xcodebuild -project Etnetera-Flow.xcodeproj -scheme Etnetera-Flow -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

66 tests in 9 suites, written with Swift Testing. They cover the parts worth protecting: storage routing and the merged feed, ordering across both sources, search, filtering, SwiftData persistence against an in-memory container, and the form view models.

`StubSportPerformanceRepository` stands in for both backing stores, so nothing in the suite touches Firebase or the disk — the tests run without network access or a Firebase project.

## Scaling

The feed is capped at `PerformanceFeed.pageSize` (100) entries per source: `.limit(to:)` on the Firestore query, `fetchLimit` on the SwiftData descriptor. Snapshots are applied incrementally through `PerformanceSnapshotBuffer` using `snapshot.documentChanges`, so adding one document decodes one document rather than re-decoding the entire collection.

That covers the two costs that grow fastest — billed document reads on every cold start, and decoding work on the main actor for every change. What it does not do is page beyond the first 100, and the honest reason is that pagination conflicts with the rest of the design:

- **Search would silently narrow.** Filtering runs client-side over what is loaded. Paging in 100 at a time means a query only ever searches the loaded pages, and a matching entry from last year simply would not appear. Firestore has no substring operator either — only prefix ranges — so real full-text search needs a normalized search field or an external index.
- **Merging two paginated sources needs a cursor on each.** Interleaving by `createdAt` across a local and a remote page means tracking both cursors and always drawing from whichever side holds the newer record.

Given that, a partial implementation that quietly breaks search seemed worse than a documented limit. The next steps I would take, in order:

1. Move `SportPerformanceRepository` off `@MainActor` so decoding and mapping leave the main thread, hopping back only to publish results.
2. Replace the manual `publishChanges()` in the SwiftData repository with incremental change notifications, so a write stops re-fetching the page.
3. Add cursor-based paging on both sources, together with a server-side search field, so the two land as one change rather than one breaking the other.

## Firestore

Documents live under `users/{userId}/sportPerformances/{performanceId}`. The rules in `firestore.rules` restrict every read and write to the authenticated owner of that path:

```
allow read, write: if request.auth != null && request.auth.uid == userId;
```

Access control lives entirely in these rules rather than in the config file, so a client can only ever reach its own documents.
