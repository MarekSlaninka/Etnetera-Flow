import Foundation
import Testing
@testable import Etnetera_Flow

@MainActor
struct PerformanceListViewModelTests {
    private let repository = StubSportPerformanceRepository()
    private let viewModel: PerformanceListViewModel

    private let localRun = SportPerformance.stub(
        name: "Run",
        storage: .local,
        createdAt: Date(timeIntervalSince1970: 1_000)
    )
    private let remoteSwim = SportPerformance.stub(
        name: "Swim",
        storage: .remote,
        createdAt: Date(timeIntervalSince1970: 3_000)
    )

    init() {
        viewModel = PerformanceListViewModel(repository: repository)
    }

    private func startObserving() async {
        viewModel.observePerformances()
        _ = await waitUntil { repository.isObserving }
    }

    @Test
    func sortsPerformancesNewestFirst() async {
        // Arrange
        await startObserving()

        // Act
        repository.emit([localRun, remoteSwim])

        // Assert
        #expect(viewModel.performances.map(\.name) == ["Swim", "Run"])
    }

    @Test
    func stopsLoadingAfterFirstPerformanceUpdate() async {
        // Arrange
        await startObserving()
        #expect(viewModel.isLoading)

        // Act
        repository.emit([])

        // Assert
        #expect(!viewModel.isLoading)
    }

    @Test
    func localFilterHidesRemotePerformances() async {
        // Arrange
        await startObserving()
        repository.emit([localRun, remoteSwim])

        // Act
        viewModel.filter = .local

        // Assert
        #expect(viewModel.performances == [localRun])
    }

    @Test
    func remoteFilterHidesLocalPerformances() async {
        // Arrange
        await startObserving()
        repository.emit([localRun, remoteSwim])

        // Act
        viewModel.filter = .remote

        // Assert
        #expect(viewModel.performances == [remoteSwim])
    }

    @Test
    func allFilterKeepsEverything() async {
        // Arrange
        await startObserving()
        repository.emit([localRun, remoteSwim])

        // Act
        viewModel.filter = .local
        viewModel.filter = .all

        // Assert
        #expect(viewModel.performances.count == 2)
    }

    @Test
    func filterSurvivesLaterUpdates() async {
        // Arrange
        await startObserving()
        viewModel.filter = .remote

        // Act
        repository.emit([localRun, remoteSwim])

        // Assert
        #expect(viewModel.performances == [remoteSwim])
    }

    @Test
    func observationErrorSurfacesMessage() async {
        // Arrange
        await startObserving()

        // Act
        repository.emit(StubSportPerformanceRepository.Failure.observation)

        // Assert
        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.isLoading)
    }

    @Test
    func dismissingAnErrorClearsTheMessage() async {
        // Arrange
        await startObserving()
        repository.emit(StubSportPerformanceRepository.Failure.observation)

        // Act
        viewModel.dismissError()

        // Assert
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func failingToStartObservationSurfacesMessage() async {
        // Arrange
        repository.observationError = StubSportPerformanceRepository.Failure.observation

        // Act
        viewModel.observePerformances()
        _ = await waitUntil { viewModel.errorMessage != nil }

        // Assert
        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.isLoading)
    }

    @Test
    func deleteForwardsToRepository() async throws {
        // Arrange
        let performance = localRun

        // Act
        try await viewModel.delete(performance)

        // Assert
        #expect(repository.deletedPerformances == [performance])
    }

    @Test
    func deletePropagatesFailure() async {
        // Arrange
        repository.writeError = StubSportPerformanceRepository.Failure.write

        // Act & Assert
        await #expect(throws: StubSportPerformanceRepository.Failure.write) {
            try await viewModel.delete(localRun)
        }
    }

    @Test
    func stopObservingCancelsTheObservation() async {
        // Arrange
        await startObserving()

        // Act
        viewModel.stopObserving()

        // Assert
        #expect(repository.cancellationCount == 1)
    }
}
