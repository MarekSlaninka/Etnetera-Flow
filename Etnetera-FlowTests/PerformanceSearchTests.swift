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
        await startObserving()

        #expect(!viewModel.isSearching)
        #expect(viewModel.performances.count == 2)
    }

    @Test
    func whitespaceOnlySearchIsNotTreatedAsAQuery() async {
        await startObserving()

        viewModel.searchText = "   \n"

        #expect(!viewModel.isSearching)
        #expect(viewModel.performances.count == 2)
    }

    @Test
    func matchesOnName() async {
        await startObserving()

        viewModel.searchText = "beh"

        #expect(viewModel.performances == [morningRun])
    }

    @Test
    func matchesOnLocation() async {
        await startObserving()

        viewModel.searchText = "Košice"

        #expect(viewModel.performances == [eveningSwim])
    }

    @Test(arguments: ["RANNÝ", "ranný", "RaNnÝ"])
    func ignoresCase(query: String) async {
        await startObserving()

        viewModel.searchText = query

        #expect(viewModel.performances == [morningRun])
    }

    @Test(arguments: ["Kosice", "kosice", "KOSICE"])
    func ignoresDiacritics(query: String) async {
        await startObserving()

        viewModel.searchText = query

        #expect(viewModel.performances == [eveningSwim])
    }

    @Test
    func trimsSurroundingWhitespaceFromTheQuery() async {
        await startObserving()

        viewModel.searchText = "  beh  "

        #expect(viewModel.performances == [morningRun])
    }

    @Test
    func nonMatchingQueryYieldsNothing() async {
        await startObserving()

        viewModel.searchText = "cyklistika"

        #expect(viewModel.performances.isEmpty)
        #expect(viewModel.isSearching)
    }

    @Test
    func combinesWithTheStorageFilter() async {
        await startObserving()

        viewModel.searchText = "a"
        viewModel.filter = .remote

        #expect(viewModel.performances == [eveningSwim])
    }

    @Test
    func searchAppliesToLaterUpdates() async {
        await startObserving()
        viewModel.searchText = "beh"

        let anotherRun = SportPerformance.stub(
            name: "Nočný beh",
            location: "Žilina",
            storage: .local,
            createdAt: Date(timeIntervalSince1970: 5_000)
        )
        repository.emit([morningRun, eveningSwim, anotherRun])

        #expect(viewModel.performances.map(\.name) == ["Nočný beh", "Ranný beh"])
    }

    @Test
    func clearingTheQueryRestoresTheFullList() async {
        await startObserving()

        viewModel.searchText = "beh"
        viewModel.searchText = ""

        #expect(!viewModel.isSearching)
        #expect(viewModel.performances.count == 2)
    }

    @Test
    func resultsStayNewestFirst() async {
        await startObserving()

        viewModel.searchText = "a"

        #expect(viewModel.performances.map(\.name) == ["Večerné plávanie", "Ranný beh"])
    }
}
