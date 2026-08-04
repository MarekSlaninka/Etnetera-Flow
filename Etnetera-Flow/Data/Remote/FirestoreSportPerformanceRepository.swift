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
        let buffer = PerformanceSnapshotBuffer()

        let listener = collection(for: userIdentifier)
            .order(by: SportPerformanceDocument.createdAtField, descending: true)
            .addSnapshotListener { snapshot, error in
                MainActor.assumeIsolated {
                    if let error {
                        Self.logger.error("Listening for performances failed: \(error.localizedDescription, privacy: .public)")
                        onError(error)
                        return
                    }

                    guard let snapshot else { return }

                    Self.apply(snapshot.documentChanges, to: buffer)
                    onUpdate(buffer.ordered)
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
            let document = try Firestore.Encoder().encode(SportPerformanceDocument(performance))

            try await collection(for: userIdentifier)
                .document(performance.id.uuidString)
                .setData(document)
        } catch {
            Self.logger.error("Saving performance failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    private static func apply(
        _ changes: [DocumentChange],
        to buffer: PerformanceSnapshotBuffer
    ) {
        for change in changes {
            let identifier = change.document.documentID

            guard change.type != .removed else {
                buffer.remove(identifier)
                continue
            }

            do {
                let document = try change.document.data(as: SportPerformanceDocument.self)
                buffer.insert(try document.domainModel(), for: identifier)
            } catch {
                logger.error("Skipping performance \(identifier, privacy: .public): \(error.localizedDescription, privacy: .public)")
                buffer.remove(identifier)
            }
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

    deinit {
        listener.remove()
    }
}
