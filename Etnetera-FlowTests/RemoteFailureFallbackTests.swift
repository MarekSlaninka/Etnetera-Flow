import Foundation
import Testing
@testable import Etnetera_Flow

@MainActor
struct RemoteFailureFallbackTests {
    private let local = StubSportPerformanceRepository()
    private let remote = StubSportPerformanceRepository()
    private let viewModel: PerformanceListViewModel

    private let localRun = SportPerformance.stub(
        name: "Local run",
        storage: .local,
        createdAt: Date(timeIntervalSince1970: 1_000)
    )
    private let remoteSwim = SportPerformance.stub(
        name: "Remote swim",
        storage: .remote,
        createdAt: Date(timeIntervalSince1970: 2_000)
    )

    init() {
        viewModel = PerformanceListViewModel(
            repository: StorageRoutingSportPerformanceRepository(
                localRepository: local,
                remoteRepository: remote
            )
        )
    }

    private func startObserving() async {
        viewModel.observePerformances()
        _ = await waitUntil { local.isObserving }
    }

    @Test
    func showsLocalPerformancesWhenRemoteCannotStart() async {
        // Arrange
        remote.observationError = StubSportPerformanceRepository.Failure.observation
        await startObserving()

        // Act
        local.emit([localRun])

        // Assert
        #expect(viewModel.performances == [localRun])
    }

    @Test
    func reportsTheRemoteErrorWhenRemoteCannotStart() async {
        // Arrange
        remote.observationError = StubSportPerformanceRepository.Failure.observation

        // Act
        await startObserving()

        // Assert
        #expect(viewModel.errorMessage != nil)
    }

    @Test
    func stopsLoadingWhenRemoteCannotStart() async {
        // Arrange
        remote.observationError = StubSportPerformanceRepository.Failure.observation

        // Act
        await startObserving()

        // Assert
        #expect(!viewModel.isLoading)
    }

    @Test
    func showsLocalPerformancesWhenRemoteFailsAfterAttaching() async {
        // Arrange
        await startObserving()
        local.emit([localRun])

        // Act
        remote.emit(StubSportPerformanceRepository.Failure.observation)

        // Assert
        #expect(viewModel.performances == [localRun])
        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.isLoading)
    }

    @Test
    func dismissingTheErrorLeavesLocalPerformancesOnScreen() async {
        // Arrange
        remote.observationError = StubSportPerformanceRepository.Failure.observation
        await startObserving()
        local.emit([localRun])

        // Act
        viewModel.dismissError()

        // Assert
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.performances == [localRun])
    }

    @Test
    func keepsBothSourcesWhenRemoteRecovers() async {
        // Arrange
        await startObserving()
        local.emit([localRun])

        // Act
        remote.emit([remoteSwim])

        // Assert
        #expect(viewModel.performances == [remoteSwim, localRun])
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func localPerformancesStillArriveAfterAFailedRemoteStart() async {
        // Arrange
        remote.observationError = StubSportPerformanceRepository.Failure.observation
        await startObserving()

        // Act
        local.emit([localRun])
        local.emit([localRun, .stub(name: "Later", storage: .local, createdAt: Date(timeIntervalSince1970: 3_000))])

        // Assert
        #expect(viewModel.performances.map(\.name) == ["Later", "Local run"])
    }
}
