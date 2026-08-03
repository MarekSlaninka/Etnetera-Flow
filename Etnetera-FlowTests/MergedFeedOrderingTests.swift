import Foundation
import Testing
@testable import Etnetera_Flow

@MainActor
struct MergedFeedOrderingTests {
    private let local = StubSportPerformanceRepository()
    private let remote = StubSportPerformanceRepository()
    private let viewModel: PerformanceListViewModel

    private func performance(name: String, at seconds: TimeInterval, storage: StorageType) -> SportPerformance {
        .stub(
            name: name,
            storage: storage,
            createdAt: Date(timeIntervalSince1970: seconds)
        )
    }

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
        _ = await waitUntil { local.isObserving && remote.isObserving }
    }

    @Test
    func interleavesBothSourcesNewestFirst() async {
        await startObserving()

        local.emit([
            performance(name: "Local oldest", at: 1_000, storage: .local),
            performance(name: "Local newest", at: 4_000, storage: .local),
        ])
        remote.emit([
            performance(name: "Remote middle", at: 2_000, storage: .remote),
            performance(name: "Remote second", at: 3_000, storage: .remote),
        ])

        #expect(viewModel.performances.map(\.name) == [
            "Local newest",
            "Remote second",
            "Remote middle",
            "Local oldest",
        ])
    }

    @Test
    func keepsOrderWhenOnlyOneSourceChanges() async {
        await startObserving()

        remote.emit([performance(name: "Remote", at: 2_000, storage: .remote)])
        local.emit([performance(name: "Local", at: 3_000, storage: .local)])

        #expect(viewModel.performances.map(\.name) == ["Local", "Remote"])

        remote.emit([performance(name: "Remote newer", at: 5_000, storage: .remote)])

        #expect(viewModel.performances.map(\.name) == ["Remote newer", "Local"])
    }

    @Test
    func filteringPreservesOrderWithinASource() async {
        await startObserving()

        local.emit([
            performance(name: "Local old", at: 1_000, storage: .local),
            performance(name: "Local new", at: 5_000, storage: .local),
        ])
        remote.emit([performance(name: "Remote", at: 3_000, storage: .remote)])

        viewModel.filter = .local

        #expect(viewModel.performances.map(\.name) == ["Local new", "Local old"])
    }

    @Test
    func emptyingOneSourceLeavesTheOtherOrdered() async {
        await startObserving()

        local.emit([
            performance(name: "Local old", at: 1_000, storage: .local),
            performance(name: "Local new", at: 4_000, storage: .local),
        ])
        remote.emit([performance(name: "Remote", at: 2_000, storage: .remote)])
        remote.emit([])

        #expect(viewModel.performances.map(\.name) == ["Local new", "Local old"])
    }
}
