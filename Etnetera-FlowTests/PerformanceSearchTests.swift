import Foundation
import Testing
@testable import Etnetera_Flow

@MainActor
struct PerformanceSearchTests {
    private let repository = StubSportPerformanceRepository()
    private let viewModel: PerformanceListViewModel

    private let morningRun = SportPerformance.stub(
        name: "Ranný beh",
        location: "Bratislava",
        storage: .local,
        createdAt: Date(timeIntervalSince1970: 1_000)
    )
    private let eveningSwim = SportPerformance.stub(
        name: "Večerné plávanie",
        location: "Košice",
        storage: .remote,
        createdAt: Date(timeIntervalSince1970: 3_000)
    )

    init() {
        viewModel = PerformanceListViewModel(repository: repository)
    }

    private func startObserving() async {
        viewModel.observePerformances()
        _ = await waitUntil { repository.isObserving }
        repository.emit([morningRun, eveningSwim])
    }

    @Test
    func emptySearchKeepsEverything() async {
        // Arrange
        await startObserving()

        // Act
        let performances = viewModel.performances

        // Assert
        #expect(!viewModel.isSearching)
        #expect(performances.count == 2)
    }

    @Test
    func whitespaceOnlySearchIsNotTreatedAsAQuery() async {
        // Arrange
        await startObserving()

        // Act
        viewModel.searchText = "   \n"

        // Assert
        #expect(!viewModel.isSearching)
        #expect(viewModel.performances.count == 2)
    }

    @Test
    func matchesOnName() async {
        // Arrange
        await startObserving()

        // Act
        viewModel.searchText = "beh"

        // Assert
        #expect(viewModel.performances == [morningRun])
    }

    @Test
    func matchesOnLocation() async {
        // Arrange
        await startObserving()

        // Act
        viewModel.searchText = "Košice"

        // Assert
        #expect(viewModel.performances == [eveningSwim])
    }

    @Test(arguments: ["RANNÝ", "ranný", "RaNnÝ"])
    func ignoresCase(query: String) async {
        // Arrange
        await startObserving()

        // Act
        viewModel.searchText = query

        // Assert
        #expect(viewModel.performances == [morningRun])
    }

    @Test(arguments: ["Kosice", "kosice", "KOSICE"])
    func ignoresDiacritics(query: String) async {
        // Arrange
        await startObserving()

        // Act
        viewModel.searchText = query

        // Assert
        #expect(viewModel.performances == [eveningSwim])
    }

    @Test
    func trimsSurroundingWhitespaceFromTheQuery() async {
        // Arrange
        await startObserving()

        // Act
        viewModel.searchText = "  beh  "

        // Assert
        #expect(viewModel.performances == [morningRun])
    }

    @Test
    func nonMatchingQueryYieldsNothing() async {
        // Arrange
        await startObserving()

        // Act
        viewModel.searchText = "cyklistika"

        // Assert
        #expect(viewModel.performances.isEmpty)
        #expect(viewModel.isSearching)
    }

    @Test
    func combinesWithTheStorageFilter() async {
        // Arrange
        await startObserving()
        viewModel.searchText = "a"

        // Act
        viewModel.filter = .remote

        // Assert
        #expect(viewModel.performances == [eveningSwim])
    }

    @Test
    func searchAppliesToLaterUpdates() async {
        // Arrange
        await startObserving()
        viewModel.searchText = "beh"
        let anotherRun = SportPerformance.stub(
            name: "Nočný beh",
            location: "Žilina",
            storage: .local,
            createdAt: Date(timeIntervalSince1970: 5_000)
        )

        // Act
        repository.emit([morningRun, eveningSwim, anotherRun])

        // Assert
        #expect(viewModel.performances.map(\.name) == ["Nočný beh", "Ranný beh"])
    }

    @Test
    func clearingTheQueryRestoresTheFullList() async {
        // Arrange
        await startObserving()
        viewModel.searchText = "beh"

        // Act
        viewModel.searchText = ""

        // Assert
        #expect(!viewModel.isSearching)
        #expect(viewModel.performances.count == 2)
    }

    @Test
    func resultsStayNewestFirst() async {
        // Arrange
        await startObserving()

        // Act
        viewModel.searchText = "a"

        // Assert
        #expect(viewModel.performances.map(\.name) == ["Večerné plávanie", "Ranný beh"])
    }
}
