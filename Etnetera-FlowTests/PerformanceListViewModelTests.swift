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
        await startObserving()

        repository.emit([localRun, remoteSwim])

        #expect(viewModel.performances.map(\.name) == ["Swim", "Run"])
    }

    @Test
    func localFilterHidesRemotePerformances() async {
        await startObserving()
        repository.emit([localRun, remoteSwim])

        viewModel.filter = .local

        #expect(viewModel.performances == [localRun])
    }

    @Test
    func remoteFilterHidesLocalPerformances() async {
        await startObserving()
        repository.emit([localRun, remoteSwim])

        viewModel.filter = .remote

        #expect(viewModel.performances == [remoteSwim])
    }

    @Test
    func allFilterKeepsEverything() async {
        await startObserving()
        repository.emit([localRun, remoteSwim])

        viewModel.filter = .local
        viewModel.filter = .all

        #expect(viewModel.performances.count == 2)
    }

    @Test
    func filterSurvivesLaterUpdates() async {
        await startObserving()
        viewModel.filter = .remote

        repository.emit([localRun, remoteSwim])

        #expect(viewModel.performances == [remoteSwim])
    }

    @Test
    func observationErrorSurfacesMessage() async {
        await startObserving()

        repository.emit(StubSportPerformanceRepository.Failure.observation)

        #expect(viewModel.errorMessage != nil)

        viewModel.dismissError()

        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func failingToStartObservationSurfacesMessage() async {
        repository.observationError = StubSportPerformanceRepository.Failure.observation

        viewModel.observePerformances()
        _ = await waitUntil { viewModel.errorMessage != nil }

        #expect(viewModel.errorMessage != nil)
    }

    @Test
    func deleteForwardsToRepository() async throws {
        try await viewModel.delete(localRun)

        #expect(repository.deletedPerformances == [localRun])
    }

    @Test
    func deletePropagatesFailure() async {
        repository.writeError = StubSportPerformanceRepository.Failure.write

        await #expect(throws: StubSportPerformanceRepository.Failure.write) {
            try await viewModel.delete(localRun)
        }
    }

    @Test
    func stopObservingCancelsTheObservation() async {
        await startObserving()

        viewModel.stopObserving()

        #expect(repository.cancellationCount == 1)
    }
}
