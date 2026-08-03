import Foundation
import Testing
@testable import Etnetera_Flow

@MainActor
struct StorageRoutingSportPerformanceRepositoryTests {
    private let local = StubSportPerformanceRepository()
    private let remote = StubSportPerformanceRepository()
    private let repository: StorageRoutingSportPerformanceRepository

    init() {
        repository = StorageRoutingSportPerformanceRepository(
            localRepository: local,
            remoteRepository: remote
        )
    }

    @Test
    func routesLocalSaveToLocalRepository() async throws {
        let performance = SportPerformance.stub(storage: .local)

        try await repository.save(performance)

        #expect(local.savedPerformances == [performance])
        #expect(remote.savedPerformances.isEmpty)
    }

    @Test
    func routesRemoteSaveToRemoteRepository() async throws {
        let performance = SportPerformance.stub(storage: .remote)

        try await repository.save(performance)

        #expect(remote.savedPerformances == [performance])
        #expect(local.savedPerformances.isEmpty)
    }

    @Test
    func routesUpdateByStorage() async throws {
        try await repository.update(.stub(storage: .local))
        try await repository.update(.stub(storage: .remote))

        #expect(local.updatedPerformances.count == 1)
        #expect(remote.updatedPerformances.count == 1)
    }

    @Test
    func routesDeleteByStorage() async throws {
        try await repository.delete(.stub(storage: .remote))

        #expect(remote.deletedPerformances.count == 1)
        #expect(local.deletedPerformances.isEmpty)
    }

    @Test
    func mergesBothSourcesIntoOneFeed() async throws {
        let recorder = PerformanceRecorder()
        let localPerformance = SportPerformance.stub(name: "Run", storage: .local)
        let remotePerformance = SportPerformance.stub(name: "Swim", storage: .remote)

        _ = try await repository.observePerformances(
            onUpdate: { recorder.record($0) },
            onError: { recorder.record($0) }
        )

        local.emit([localPerformance])
        remote.emit([remotePerformance])

        #expect(recorder.latest.count == 2)
        #expect(recorder.latest.contains(localPerformance))
        #expect(recorder.latest.contains(remotePerformance))
    }

    @Test
    func keepsLocalFeedWhenRemoteObservationFails() async throws {
        let recorder = PerformanceRecorder()
        remote.observationError = StubSportPerformanceRepository.Failure.observation
        let performance = SportPerformance.stub(storage: .local)

        _ = try await repository.observePerformances(
            onUpdate: { recorder.record($0) },
            onError: { recorder.record($0) }
        )

        #expect(recorder.errors.count == 1)
        #expect(local.isObserving)

        local.emit([performance])

        #expect(recorder.latest == [performance])
    }

    @Test
    func cancelsLocalObservationWhenRemoteObservationFails() async throws {
        let recorder = PerformanceRecorder()
        remote.observationError = StubSportPerformanceRepository.Failure.observation

        let observation = try await repository.observePerformances(
            onUpdate: { recorder.record($0) },
            onError: { recorder.record($0) }
        )
        observation.cancel()

        #expect(local.cancellationCount == 1)
        #expect(!local.isObserving)
    }

    @Test
    func cancelsBothObservations() async throws {
        let recorder = PerformanceRecorder()

        let observation = try await repository.observePerformances(
            onUpdate: { recorder.record($0) },
            onError: { recorder.record($0) }
        )
        observation.cancel()

        #expect(local.cancellationCount == 1)
        #expect(remote.cancellationCount == 1)
    }
}
