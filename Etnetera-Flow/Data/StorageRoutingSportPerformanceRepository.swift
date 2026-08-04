import Foundation

@MainActor
final class StorageRoutingSportPerformanceRepository: SportPerformanceRepository {
    private let localRepository: SportPerformanceRepository
    private let remoteRepository: SportPerformanceRepository

    init(
        localRepository: SportPerformanceRepository,
        remoteRepository: SportPerformanceRepository
    ) {
        self.localRepository = localRepository
        self.remoteRepository = remoteRepository
    }

    func observePerformances(
        onUpdate: @escaping ([SportPerformance]) -> Void,
        onError: @escaping (Error) -> Void
    ) async throws -> any PerformanceObservation {
        let merger = PerformanceMerger(onUpdate: onUpdate)
        let localObservation = try await localRepository.observePerformances(
            onUpdate: { merger.updateLocal($0) },
            onError: onError
        )

        do {
            let remoteObservation = try await remoteRepository.observePerformances(
                onUpdate: { merger.updateRemote($0) },
                onError: { error in
                    merger.finishInitialRemoteLoad()
                    onError(error)
                }
            )

            return CompositePerformanceObservation(
                observations: [localObservation, remoteObservation]
            )
        } catch {
            merger.finishInitialRemoteLoad()
            onError(error)
            return CompositePerformanceObservation(observations: [localObservation])
        }
    }

    func save(_ performance: SportPerformance) async throws {
        switch performance.storage {
        case .local:
            try await localRepository.save(performance)
        case .remote:
            try await remoteRepository.save(performance)
        }
    }

    func update(_ performance: SportPerformance) async throws {
        switch performance.storage {
        case .local:
            try await localRepository.update(performance)
        case .remote:
            try await remoteRepository.update(performance)
        }
    }

    func delete(_ performance: SportPerformance) async throws {
        switch performance.storage {
        case .local:
            try await localRepository.delete(performance)
        case .remote:
            try await remoteRepository.delete(performance)
        }
    }
}

@MainActor
private final class PerformanceMerger {
    private var local: [SportPerformance] = []
    private var remote: [SportPerformance] = []
    private var isAwaitingInitialRemoteUpdate = true
    private let onUpdate: ([SportPerformance]) -> Void

    init(onUpdate: @escaping ([SportPerformance]) -> Void) {
        self.onUpdate = onUpdate
    }

    func updateLocal(_ performances: [SportPerformance]) {
        local = performances
        publishIfReady()
    }

    func updateRemote(_ performances: [SportPerformance]) {
        remote = performances
        finishInitialRemoteLoad()
    }

    func finishInitialRemoteLoad() {
        isAwaitingInitialRemoteUpdate = false
        publishIfReady()
    }

    private func publishIfReady() {
        guard !isAwaitingInitialRemoteUpdate else { return }

        onUpdate(local + remote)
    }
}

@MainActor
private final class CompositePerformanceObservation: PerformanceObservation {
    private var observations: [any PerformanceObservation]

    init(observations: [any PerformanceObservation]) {
        self.observations = observations
    }

    func cancel() {
        observations.forEach { $0.cancel() }
        observations = []
    }

}
