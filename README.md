# Flow

An iOS app for recording sport performances, where every entry is stored either **locally** (SwiftData) or **remotely** (Cloud Firestore). The list merges both sources into a single live feed and can be filtered by storage type.

## Features

- Add, edit and delete a sport performance (name, location, duration)
- Choose per entry whether it is saved locally or remotely
- Live list that merges local and remote entries and updates as either source changes
- Filter the list by all / local / remote

## Requirements

- Xcode 26 or newer
- iOS 27 deployment target (also builds for macOS 26.6)
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

`Etnetera-Flow/GoogleService-Info.plist.example` shows the expected structure if you would rather point the app at your own Firebase project. In that case create an iOS app with bundle ID `ms.sk.etnetera.flow`, enable **Anonymous** sign-in under Authentication, create a Firestore database, and deploy `firestore.rules`.

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

Use cases (`SaveSportPerformanceUseCase`, `UpdateSportPerformanceUseCase`, `DeleteSportPerformanceUseCase`) hold the validation rules, keeping the view models limited to presentation state.

## Firestore

Documents live under `users/{userId}/sportPerformances/{performanceId}`. The rules in `firestore.rules` restrict every read and write to the authenticated owner of that path:

```
allow read, write: if request.auth != null && request.auth.uid == userId;
```

Access control lives entirely in these rules rather than in the config file, so a client can only ever reach its own documents.
