import Foundation
import Observation

@MainActor
@Observable
final class PerformanceListViewModel {
    var filter: PerformanceFilter = .all {
        didSet { applyFilter() }
    }
    var searchText = "" {
        didSet { applyFilter() }
    }
    private(set) var performances: [SportPerformance] = []
    private(set) var errorMessage: String?
    private(set) var isLoading = true

    var isSearching: Bool {
        !searchQuery.isEmpty
    }

    private var searchQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var allPerformances: [SportPerformance] = [] {
        didSet { applyFilter() }
    }
    private let deleteUseCase: DeleteSportPerformanceUseCase
    private let observer: PerformanceObserver

    init(repository: SportPerformanceRepository) {
        deleteUseCase = DeleteSportPerformanceUseCase(repository: repository)
        observer = PerformanceObserver(repository: repository)
    }

    func observePerformances() {
        isLoading = true

        observer.start(
            onUpdate: { [weak self] performances in
                self?.allPerformances = performances
                self?.isLoading = false
            },
            onError: { [weak self] error in
                self?.errorMessage = error.localizedDescription
                self?.isLoading = false
            }
        )
    }

    func stopObserving() {
        observer.stop()
    }

    func delete(_ performance: SportPerformance) async throws {
        try await deleteUseCase.execute(performance)
    }

    func dismissError() {
        errorMessage = nil
    }

    private func applyFilter() {
        performances = allPerformances
            .filter(filter.includes)
            .filter(matchesSearch)
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func matchesSearch(_ performance: SportPerformance) -> Bool {
        let query = searchQuery

        guard !query.isEmpty else { return true }

        return performance.name.localizedStandardContains(query)
            || performance.location.localizedStandardContains(query)
    }
}
