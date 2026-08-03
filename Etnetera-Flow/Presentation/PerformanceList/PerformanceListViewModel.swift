import Foundation
import Observation

@MainActor
@Observable
final class PerformanceListViewModel {
    var filter: PerformanceFilter = .all {
        didSet { applyFilter() }
    }
    private(set) var performances: [SportPerformance] = []
    private(set) var errorMessage: String?

    private var allPerformances: [SportPerformance] = [] {
        didSet { applyFilter() }
    }
    private let repository: SportPerformanceRepository
    private let observer: PerformanceObserver

    init(repository: SportPerformanceRepository) {
        self.repository = repository
        observer = PerformanceObserver(repository: repository)
    }

    func observePerformances() {
        observer.start(
            onUpdate: { [weak self] performances in
                self?.allPerformances = performances
            },
            onError: { [weak self] error in
                self?.errorMessage = error.localizedDescription
            }
        )
    }

    func stopObserving() {
        observer.stop()
    }

    func delete(_ performance: SportPerformance) async throws {
        try await repository.delete(performance)
    }

    func dismissError() {
        errorMessage = nil
    }

    private func applyFilter() {
        performances = allPerformances
            .filter(filter.includes)
            .sorted { $0.createdAt > $1.createdAt }
    }
}
