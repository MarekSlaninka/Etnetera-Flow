# Flow

An iOS app for recording sport performances, where every entry is stored either **locally**
(SwiftData) or **remotely** (Cloud Firestore). The list merges both sources into a single live feed
and can be filtered by storage type.

## Features

- Add, edit and delete a sport performance (name, location, duration)
- Choose per entry whether it is saved locally or remotely
- Live list that merges local and remote entries and updates as either source changes
- Loading state while the initial merged feed is being prepared
- Filter the list by all / local / remote
- Search by name or location, ignoring case and diacritics
- Pick a place interactively when adding or editing, with autocomplete from MapKit
- Map of every entry that has a place, with a detail sheet behind each pin
- Tapping an entry in the list opens the map centred on it

## Requirements

- Xcode 26 or newer
- iOS 26 deployment target (also builds for macOS 26)
- Swift Package Manager resolves [firebase-ios-sdk](https://github.com/firebase/firebase-ios-sdk) on
  first open

## Running the app

```bash
git clone https://github.com/MarekSlaninka/Etnetera-Flow.git
cd Etnetera-Flow
```

The app needs a Firebase config file, which is not part of this repository. **I will send you
`GoogleService-Info.plist` separately** — drop it in next to the template:

```
Etnetera-Flow/GoogleService-Info.plist
```

Then open the project, wait for Xcode to resolve the Firebase package, and build:

```bash
open Etnetera-Flow.xcodeproj
```

`GoogleService-Info.plist.example` in the repository root shows the expected structure if you would
rather point the app at your own Firebase project. In that case create an iOS app with bundle ID
`ms.sk.etnetera.flow`, enable **Anonymous** sign-in under Authentication, create a Firestore
database, and deploy `firestore.rules`.

Remote entries are scoped to an anonymous Firebase Auth user, so each device gets its own private
set of documents.

## Architecture

The project follows a Clean Architecture split, with dependencies pointing inwards towards `Domain`.

```
Domain/
  Model/            SportPerformance and PerformanceCoordinate.
  Repositories/     The repository contract and the observation it hands back.
  UseCases/         Save, update and delete.
Data/
  Local/            SwiftData repository and its stored model.
  Remote/           Firestore repository, document, snapshot buffer, anonymous identity.
  Places/           MapKit place search.
  StorageRouting…   Composes both stores; sits above them rather than inside either.
Presentation/       SwiftUI views and their view models, grouped by screen.
```

The key seam is `SportPerformanceRepository`, defined in `Domain` and implemented three times:

| Implementation                             | Role                           |
| ------------------------------------------ | ------------------------------ |
| `SwiftDataSportPerformanceRepository`      | Local persistence              |
| `FirestoreSportPerformanceRepository`      | Remote persistence             |
| `StorageRoutingSportPerformanceRepository` | Routes writes and merges feeds |

The presentation layer uses MVVM: SwiftUI views render state and forward actions, while observable
view models own presentation state and call use cases. Because view models depend only on the
protocol, `PreviewData.swift` can supply an in-memory double for SwiftUI previews without touching
either backing store.

Use cases (`SaveSportPerformanceUseCase`, `UpdateSportPerformanceUseCase`,
`DeleteSportPerformanceUseCase`) name the write operations the app supports and are the only way the
view models reach the repository. Input validation and trimming currently sit in the view models, so
the use cases stay thin — they are a seam for rules that do not exist yet rather than a
place where logic lives today.

The domain entity carries no serialization: `SportPerformanceRecord` is the SwiftData model and
`SportPerformanceDocument` the Firestore one, each mapping to and from `SportPerformance` at the
edge of `Data`.

## Places and the map

A performance carries an optional `PerformanceCoordinate` alongside its free-text `location`. It is
optional because naming a place without pinning it stays valid — a run "in the park" needs no point
on a map. There is no `0, 0` sentinel: null island is a real coordinate in the Gulf of Guinea, so
absence is modelled as `nil`.

Tapping a row opens the map centred on that entry with its pin already selected. `PerformanceMapFocus`
owns both decisions — the camera and the initial selection — which keeps them testable and out of the
view. A performance with a coordinate yields a tight region around it and selects its marker; one
without falls back to the automatic camera framing every pin and selects nothing, so tapping an entry
that has no place still opens a useful map rather than dead-ending.

Both are seeded as initial `@State` in the view's initialiser rather than applied in `onAppear`. The
map is itself presented as a sheet, and setting selection after the sheet has begun animating in races
with that presentation; seeding it means the first render already shows the intended state.

`PerformanceCoordinate` has exactly one initialiser, and it validates. An earlier version also
offered a convenience initialiser taking a pair of optionals, which turned out to be a trap: with
two overloads, Swift picked the non-validating one whenever the arguments were non-optional, so
out-of-range values passed straight through. The optional pair is now a `make` factory that funnels
into the same failable initialiser, leaving one path in and no way to construct an invalid
coordinate.

`PlaceSearchService` wraps `MKLocalSearchCompleter` in two phases: completions stream in cheaply
while typing, debounced by 300ms through a cancellable task, and the full `MKLocalSearch` runs only
once a suggestion is chosen and real coordinates are needed. Tapping the map afterwards nudges the
pin — `MapReader` converts the tap point into a coordinate, so the pin lands where the finger did
rather than at some fixed location.

The app asks for no location permission at all. Nothing here needs the device's own position: places
are found by search, and the map frames the saved entries. That removes a permission prompt, an
Info.plist key and a denied-access path from the app entirely. Centring on the user would be the one
reason to add CoreLocation later.

## Tests

```bash
xcodebuild -project Etnetera-Flow.xcodeproj -scheme Etnetera-Flow \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

113 test definitions in 14 suites, written with Swift Testing. They cover the parts worth protecting:
storage routing and the merged feed, ordering across both sources, search, filtering, SwiftData
persistence against an in-memory container, coordinate mapping through both stores, the Firestore
document, the incremental snapshot buffer, the map's camera and selection, and the form view models.
Tests follow the Arrange–Act–Assert (AAA) structure to make their setup, action, and expected outcome
clear.

`StubSportPerformanceRepository` stands in for both backing stores, so nothing in the suite touches
Firebase or the disk — the tests run without network access or a Firebase project.

## Scaling

Both sources load in full, and search and filtering run client-side over the loaded entries. For the
volumes this app realistically holds that is the right trade-off: everything is searchable, and the
merged feed is always complete.

Snapshots are still applied incrementally. `PerformanceSnapshotBuffer` consumes
`snapshot.documentChanges` rather than re-reading `snapshot.documents`, so adding one entry decodes
one document instead of the whole collection — which matters because that work runs on the main
actor.

If the app were used more heavily, the part that has to change is **search**, not the loading.
Loading everything to filter it in memory stops being viable well before the UI does, and Firestore
bills per document read on every cold start. Search would have to move into both stores and the
results be merged:

- **SwiftData** can filter server-side through a `#Predicate` on the `FetchDescriptor`, so the query
  returns matches instead of everything.
- **Firestore** has no substring operator — only prefix ranges — so matching mid-word needs a
  normalized, tokenized search field written alongside each document, or an external index such as
  Algolia or Typesense.
- **Merging** the two result sets then needs a cursor on each side, drawing from whichever holds the
  newer record, so that paging by `createdAt` stays correct across sources.

Two smaller changes belong with that work: moving `SportPerformanceRepository` off `@MainActor` so
decoding leaves the main thread, and replacing the manual `publishChanges()` in the SwiftData
repository with incremental change notifications so a write stops re-fetching everything.

## Firestore

Documents live under `users/{userId}/sportPerformances/{performanceId}`. The rules in
`firestore.rules` restrict every read and write to the authenticated owner of that path:

```
allow read, write: if request.auth != null && request.auth.uid == userId;
```

Access control lives entirely in these rules rather than in the config file, so a client can only
ever reach its own documents.

## Implementation decisions and development notes

This project was developed with AI assistance. I used it to accelerate scaffolding, research and
iteration, but treated its proposals as reviewable drafts: I supplied the product constraints,
challenged initial choices and requested the revisions below. This section is included to make that
decision-making explicit.

The workflows themselves are in the repository: [AGENTS.md](AGENTS.md) holds the baseline rules and
`.agents/skills/` the task-specific ones, described in
[AI_ENGINEERING_PLAYBOOK.md](AI_ENGINEERING_PLAYBOOK.md). Global, machine-level skills configured
outside this repository were used as well; they carry no project context and are not vendored here.

### Requirements that shaped the result

- The app is native SwiftUI, without storyboards/XIBs, and records sport performances in either
  SwiftData or Firestore.
- The list supports Local/Remote/All filters; source information is communicated by colour as
  required, rather than duplicate icon and text. The coloured dot has an accessibility label for
  VoiceOver.
- Creation uses a navigation-bar `+` button and a sheet, not a `TabView`; the sheet closes after a
  successful save. Both create and edit sheets have an explicit close button.
- Performances can be edited and deleted. Deletion is a red/destructive action and needs
  confirmation. Read, write, delete and decoding errors are shown in the UI and logged with `OSLog`
  in both repositories. A failed read reports itself rather than returning an empty list, so an
  empty screen always means "nothing recorded" and never a swallowed failure.
- User-facing copy is in `Localizable.xcstrings` (Slovak, Czech and English). SwiftUI uses localisation
  keys/`LocalizedStringResource` directly; only formatted values are resolved to a concrete
  `String`.

### Architectural evolution

- The initial draft used Combine and `ObservableObject`. It was deliberately replaced with Swift
  Concurrency and `@Observable` from Observation, which is a better fit for the target platform and
  avoids an unnecessary reactive dependency.
- `AsyncThrowingStream` was evaluated as a bridge for Firestore snapshots. A leaked continuation
  exposed how easy it is to get stream termination wrong around a callback API, so the final design
  uses a callback registration that returns `PerformanceObservation` instead.
- `PerformanceObserver` is the layer between the list view model and the repository: it owns and
  cancels the current observation. The Firestore-specific observation owns `ListenerRegistration`
  and removes it on cancellation/deinit. Listener lifetime is therefore explicit without leaking
  Firebase implementation details to the view model.
- The merged feed treats remote observation as an enhancement. If it cannot start, local
  performances remain visible instead of failing the entire list.
- `storage` is routing/UI information, not duplicated persistence data. SwiftData records are mapped
  back as local and Firestore documents as remote, avoiding an inconsistent `storage` field stored
  in both databases.
- An earlier global offline-first sync/settings design was considered. It was intentionally
  superseded by the simpler per-performance Local/Firebase choice in the final assignment flow; it
  is not claimed as an implemented feature.

### Firebase decisions and safety

- Project: `etnetera-flow-prod`; bundle ID: `ms.sk.etnetera.flow`; Firestore: Native mode, default
  database `(default)`, region `eur3`. The irreversible region choice was confirmed before creation.
  No test documents were created or deleted.
- A locally persisted installation UUID was first considered to separate users. It was rejected as a
  security boundary: a client-controlled UUID is not authentication. The final implementation signs
  in with Firebase Anonymous Authentication and scopes data to `request.auth.uid`.
- Firebase is configured once, at application start and before Firestore is used. This was an
  explicit correction after encountering both duplicate configuration and "configure before using
  Firestore" runtime failures.
- Public Firestore rules such as `allow read, write: if true` were explicitly ruled out. The
  production rule is the owner check shown above.

### Deliberate limitations / next steps

- Anonymous Authentication isolates data per Firebase user but does not provide account recovery or
  a cross-device identity. A production product should add a real sign-in/account-linking flow and
  validation constraints in Firestore rules.
- The current SwiftData schema has no versioned migration. A shipped app needs a `VersionedSchema`
  migration plan for future model changes.
- The app and its test suite were run after changes, but the project does not claim that automated
  tests replace manual Firebase/security testing.
