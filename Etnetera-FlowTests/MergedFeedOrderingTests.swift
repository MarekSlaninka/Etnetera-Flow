import Foundation
import Testing
@testable import Etnetera_Flow

@MainActor
struct MergedFeedOrderingTests {
    private let local = StubSportPerformanceRepository()
    private let remote = StubSportPerformanceRepository()
    private let viewModel: PerformanceListViewModel

    init() {
        viewModel = PerformanceListViewModel(
            repository: StorageRoutingSportPerformanceRepository(
                localRepository: local,
                remoteRepository: remote
            )
        )
    }

    private func performance(
        name: String,
        at seconds: TimeInterval,
        storage: StorageType
    ) -> SportPerformance {
        .stub(name: name, storage: storage, createdAt: Date(timeIntervalSince1970: seconds))
    }

    private func startObserving() async {
        viewModel.observePerformances()
        _ = await waitUntil { local.isObserving && remote.isObserving }
    }

    @Test
    func interleavesBothSourcesNewestFirst() async {
        // Arrange
        await startObserving()

        // Act
        local.emit([
            performance(name: "Local oldest", at: 1_000, storage: .local),
            performance(name: "Local newest", at: 4_000, storage: .local),
        ])
        remote.emit([
            performance(name: "Remote middle", at: 2_000, storage: .remote),
            performance(name: "Remote second", at: 3_000, storage: .remote),
        ])

        // Assert
        #expect(viewModel.performances.map(\.name) == [
            "Local newest",
            "Remote second",
            "Remote middle",
            "Local oldest",
        ])
    }

    @Test
    func keepsOrderWhenOnlyOneSourceChanges() async {
        // Arrange
        await startObserving()
        remote.emit([performance(name: "Remote", at: 2_000, storage: .remote)])
        local.emit([performance(name: "Local", at: 3_000, storage: .local)])
        #expect(viewModel.performances.map(\.name) == ["Local", "Remote"])

        // Act
        remote.emit([performance(name: "Remote newer", at: 5_000, storage: .remote)])

        // Assert
        #expect(viewModel.performances.map(\.name) == ["Remote newer", "Local"])
    }

    @Test
    func filteringPreservesOrderWithinASource() async {
        // Arrange
        await startObserving()
        local.emit([
            performance(name: "Local old", at: 1_000, storage: .local),
            performance(name: "Local new", at: 5_000, storage: .local),
        ])
        remote.emit([performance(name: "Remote", at: 3_000, storage: .remote)])

        // Act
        viewModel.filter = .local

        // Assert
        #expect(viewModel.performances.map(\.name) == ["Local new", "Local old"])
    }

    @Test
    func emptyingOneSourceLeavesTheOtherOrdered() async {
        // Arrange
        await startObserving()
        local.emit([
            performance(name: "Local old", at: 1_000, storage: .local),
            performance(name: "Local new", at: 4_000, storage: .local),
        ])
        remote.emit([performance(name: "Remote", at: 2_000, storage: .remote)])

        // Act
        remote.emit([])

        // Assert
        #expect(viewModel.performances.map(\.name) == ["Local new", "Local old"])
    }
}
