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

    private func observe(into recorder: PerformanceRecorder) async throws -> any PerformanceObservation {
        try await repository.observePerformances(
            onUpdate: { recorder.record($0) },
            onError: { recorder.record($0) }
        )
    }

    @Test
    func routesLocalSaveToLocalRepository() async throws {
        // Arrange
        let performance = SportPerformance.stub(storage: .local)

        // Act
        try await repository.save(performance)

        // Assert
        #expect(local.savedPerformances == [performance])
        #expect(remote.savedPerformances.isEmpty)
    }

    @Test
    func routesRemoteSaveToRemoteRepository() async throws {
        // Arrange
        let performance = SportPerformance.stub(storage: .remote)

        // Act
        try await repository.save(performance)

        // Assert
        #expect(remote.savedPerformances == [performance])
        #expect(local.savedPerformances.isEmpty)
    }

    @Test
    func routesUpdateByStorage() async throws {
        // Arrange
        let localPerformance = SportPerformance.stub(storage: .local)
        let remotePerformance = SportPerformance.stub(storage: .remote)

        // Act
        try await repository.update(localPerformance)
        try await repository.update(remotePerformance)

        // Assert
        #expect(local.updatedPerformances == [localPerformance])
        #expect(remote.updatedPerformances == [remotePerformance])
    }

    @Test
    func routesDeleteByStorage() async throws {
        // Arrange
        let performance = SportPerformance.stub(storage: .remote)

        // Act
        try await repository.delete(performance)

        // Assert
        #expect(remote.deletedPerformances == [performance])
        #expect(local.deletedPerformances.isEmpty)
    }

    @Test
    func mergesBothSourcesIntoOneFeed() async throws {
        // Arrange
        let recorder = PerformanceRecorder()
        let localPerformance = SportPerformance.stub(name: "Run", storage: .local)
        let remotePerformance = SportPerformance.stub(name: "Swim", storage: .remote)
        _ = try await observe(into: recorder)

        // Act
        local.emit([localPerformance])
        remote.emit([remotePerformance])

        // Assert
        #expect(recorder.latest.count == 2)
        #expect(recorder.latest.contains(localPerformance))
        #expect(recorder.latest.contains(remotePerformance))
    }

    @Test
    func waitsForInitialRemoteUpdateBeforePublishingTheFeed() async throws {
        // Arrange
        let recorder = PerformanceRecorder()
        let localPerformance = SportPerformance.stub(name: "Run", storage: .local)
        let remotePerformance = SportPerformance.stub(name: "Swim", storage: .remote)
        _ = try await observe(into: recorder)

        // Act
        local.emit([localPerformance])

        // Assert
        #expect(recorder.updates.isEmpty)

        // Act
        remote.emit([remotePerformance])

        // Assert
        #expect(recorder.latest == [localPerformance, remotePerformance])
    }

    @Test
    func keepsLocalFeedWhenRemoteObservationFails() async throws {
        // Arrange
        let recorder = PerformanceRecorder()
        let performance = SportPerformance.stub(storage: .local)
        remote.observationError = StubSportPerformanceRepository.Failure.observation
        _ = try await observe(into: recorder)

        // Act
        local.emit([performance])

        // Assert
        #expect(recorder.errors.count == 1)
        #expect(local.isObserving)
        #expect(recorder.latest == [performance])
    }

    @Test
    func cancelsLocalObservationWhenRemoteObservationFails() async throws {
        // Arrange
        let recorder = PerformanceRecorder()
        remote.observationError = StubSportPerformanceRepository.Failure.observation
        let observation = try await observe(into: recorder)

        // Act
        observation.cancel()

        // Assert
        #expect(local.cancellationCount == 1)
        #expect(!local.isObserving)
    }

    @Test
    func cancelsBothObservations() async throws {
        // Arrange
        let recorder = PerformanceRecorder()
        let observation = try await observe(into: recorder)

        // Act
        observation.cancel()

        // Assert
        #expect(local.cancellationCount == 1)
        #expect(remote.cancellationCount == 1)
    }
}
