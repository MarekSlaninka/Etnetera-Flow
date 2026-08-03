import FirebaseFirestore
import Foundation
import OSLog

@MainActor
final class FirestoreSportPerformanceRepository: SportPerformanceRepository {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Flow",
        category: "FirestoreSportPerformanceRepository"
    )

    private let database: Firestore
    private let userIdentifierProvider: UserIdentifierProviding

    init(
        database: Firestore = .firestore(),
        userIdentifierProvider: UserIdentifierProviding
    ) {
        self.database = database
        self.userIdentifierProvider = userIdentifierProvider
    }

    private func collection(for userIdentifier: String) -> CollectionReference {
        database
            .collection("users")
            .document(userIdentifier)
            .collection("sportPerformances")
    }

    func observePerformances(
        onUpdate: @escaping ([SportPerformance]) -> Void,
        onError: @escaping (Error) -> Void
    ) async throws -> any PerformanceObservation {
        let userIdentifier = try await userIdentifierProvider.identifier()
        let listener = collection(for: userIdentifier)
            .order(by: SportPerformanceDocument.createdAtField, descending: true)
            .addSnapshotListener { snapshot, error in
                // Firestore dispatches callbacks on the main queue unless
                // `FirestoreSettings.dispatchQueue` says otherwise. Asserting that
                // here keeps snapshots in order — hopping through `Task { @MainActor }`
                // would let two rapid snapshots be applied out of sequence.
                MainActor.assumeIsolated {
                    if let error {
                        Self.logger.error("Listening for performances failed: \(error.localizedDescription, privacy: .public)")
                        onError(error)
                        return
                    }

                    onUpdate(Self.performances(from: snapshot))
                }
            }

        return FirestorePerformanceObservation(listener: listener)
    }

    func save(_ performance: SportPerformance) async throws {
        try await write(performance)
    }

    func update(_ performance: SportPerformance) async throws {
        try await write(performance)
    }

    func delete(_ performance: SportPerformance) async throws {
        let userIdentifier = try await userIdentifierProvider.identifier()

        do {
            try await collection(for: userIdentifier)
                .document(performance.id.uuidString)
                .delete()
        } catch {
            Self.logger.error("Deleting performance failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    private func write(_ performance: SportPerformance) async throws {
        let userIdentifier = try await userIdentifierProvider.identifier()

        do {
            // `setData(from:)` is synchronous and returns as soon as the write is
            // queued locally, so encoding by hand is what lets the caller await
            // the acknowledged write and see a real failure.
            let document = try Firestore.Encoder().encode(SportPerformanceDocument(performance))

            try await collection(for: userIdentifier)
                .document(performance.id.uuidString)
                .setData(document)
        } catch {
            Self.logger.error("Saving performance failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    /// Decodes a snapshot, skipping individual malformed documents.
    ///
    /// Mapping with a throwing transform would drop the whole feed because of a
    /// single bad document, so unreadable ones are logged and left out instead.
    private static func performances(from snapshot: QuerySnapshot?) -> [SportPerformance] {
        guard let snapshot else { return [] }

        return snapshot.documents.compactMap { document in
            do {
                return try document.data(as: SportPerformanceDocument.self).domainModel()
            } catch {
                Self.logger.error("Skipping performance \(document.documentID, privacy: .public): \(error.localizedDescription, privacy: .public)")
                return nil
            }
        }
    }
}

/// Firestore's wire representation of a sport performance.
///
/// The domain entity deliberately stays free of serialization concerns, and
/// `storage` is not persisted at all — a document living in this collection is
/// remote by definition.
private struct SportPerformanceDocument: Codable {
    static let createdAtField = "createdAt"

    let id: String
    let name: String
    let location: String
    let duration: TimeInterval
    let createdAt: Date

    init(_ performance: SportPerformance) {
        id = performance.id.uuidString
        name = performance.name
        location = performance.location
        duration = performance.duration
        createdAt = performance.createdAt
    }

    func domainModel() throws -> SportPerformance {
        guard let identifier = UUID(uuidString: id) else {
            throw SportPerformanceDocumentError.malformedIdentifier(id)
        }

        return SportPerformance(
            id: identifier,
            name: name,
            location: location,
            duration: duration,
            storage: .remote,
            createdAt: createdAt
        )
    }
}

private enum SportPerformanceDocumentError: LocalizedError {
    case malformedIdentifier(String)

    var errorDescription: String? {
        switch self {
        case let .malformedIdentifier(value):
            "Sport performance identifier is not a UUID: \(value)."
        }
    }
}

@MainActor
private final class FirestorePerformanceObservation: PerformanceObservation {
    private let listener: ListenerRegistration

    init(listener: ListenerRegistration) {
        self.listener = listener
    }

    func cancel() {
        listener.remove()
    }

    /// `remove()` is idempotent and thread-safe, and `listener` is immutable, so
    /// this is safe to run from a nonisolated `deinit`. Holding the registration
    /// in a `var` and nilling it out here would instead touch main-actor state
    /// from whatever thread happens to release the object.
    deinit {
        listener.remove()
    }
}
