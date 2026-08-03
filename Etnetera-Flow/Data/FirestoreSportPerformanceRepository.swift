import FirebaseFirestore
import Foundation

@MainActor
final class FirestoreSportPerformanceRepository: SportPerformanceRepository {
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
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error {
                    Task { @MainActor in
                        Self.log(error, operation: "listening for performances")
                        onError(error)
                    }
                    return
                }

                Task { @MainActor in
                    do {
                        let performances = try snapshot?.documents.map {
                            try self.performance(from: $0)
                        } ?? []
                        onUpdate(performances)
                    } catch {
                        Self.log(error, operation: "decoding performances")
                        onError(error)
                    }
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

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            collection(for: userIdentifier)
                .document(performance.id.uuidString)
                .delete { error in
                    if let error {
                        Self.log(error, operation: "saving performance")
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
        }
    }

    private func write(_ performance: SportPerformance) async throws {
        let userIdentifier = try await userIdentifierProvider.identifier()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                var data = try Firestore.Encoder().encode(performance)
                data.removeValue(forKey: "storage")

                collection(for: userIdentifier)
                    .document(performance.id.uuidString)
                    .setData(data) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            } catch {
                Self.log(error, operation: "encoding performance")
                continuation.resume(throwing: error)
            }
        }
    }

    private func performance(from document: QueryDocumentSnapshot) throws -> SportPerformance {
        var data = document.data()
        data["storage"] = StorageType.remote.rawValue
        return try Firestore.Decoder().decode(SportPerformance.self, from: data)
    }

    nonisolated fileprivate static func log(_ error: Error, operation: String) {
        print("[Firebase Firestore] Error \(operation): \(error.localizedDescription)")
    }
}

@MainActor
private final class FirestorePerformanceObservation: PerformanceObservation {
    private var listener: ListenerRegistration?

    init(listener: ListenerRegistration) {
        self.listener = listener
    }

    func cancel() {
        listener?.remove()
        listener = nil
    }

    deinit {
        listener?.remove()
    }
}
