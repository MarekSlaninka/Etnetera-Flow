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

Both sources load in full, and search and filtering run client-side over the loaded entries. For the volumes this app realistically holds that is the right trade-off: everything is searchable, and the merged feed is always complete.

Snapshots are still applied incrementally. `PerformanceSnapshotBuffer` consumes `snapshot.documentChanges` rather than re-reading `snapshot.documents`, so adding one entry decodes one document instead of the whole collection — which matters because that work runs on the main actor.

If the app were used more heavily, the part that has to change is **search**, not the loading. Loading everything to filter it in memory stops being viable well before the UI does, and Firestore bills per document read on every cold start. Search would have to move into both stores and the results be merged:

- **SwiftData** can filter server-side through a `#Predicate` on the `FetchDescriptor`, so the query returns matches instead of everything.
- **Firestore** has no substring operator — only prefix ranges — so matching mid-word needs a normalized, tokenized search field written alongside each document, or an external index such as Algolia or Typesense.
- **Merging** the two result sets then needs a cursor on each side, drawing from whichever holds the newer record, so that paging by `createdAt` stays correct across sources.

Two smaller changes belong with that work: moving `SportPerformanceRepository` off `@MainActor` so decoding leaves the main thread, and replacing the manual `publishChanges()` in the SwiftData repository with incremental change notifications so a write stops re-fetching everything.

## Firestore

Documents live under `users/{userId}/sportPerformances/{performanceId}`. The rules in `firestore.rules` restrict every read and write to the authenticated owner of that path:

```
allow read, write: if request.auth != null && request.auth.uid == userId;
```

Access control lives entirely in these rules rather than in the config file, so a client can only ever reach its own documents.
