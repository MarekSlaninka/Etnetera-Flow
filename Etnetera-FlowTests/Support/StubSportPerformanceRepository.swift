import Foundation
@testable import Etnetera_Flow

@MainActor
final class StubSportPerformanceRepository: SportPerformanceRepository {
    enum Failure: Error, Equatable {
        case observation
        case write
    }

    var observationError: Error?
    var writeError: Error?

    private(set) var savedPerformances: [SportPerformance] = []
    private(set) var updatedPerformances: [SportPerformance] = []
    private(set) var deletedPerformances: [SportPerformance] = []
    private(set) var isObserving = false
    private(set) var cancellationCount = 0

    private var onUpdate: (([SportPerformance]) -> Void)?
    private var onError: ((Error) -> Void)?

    func observePerformances(
        onUpdate: @escaping ([SportPerformance]) -> Void,
        onError: @escaping (Error) -> Void
    ) async throws -> any PerformanceObservation {
        if let observationError {
            throw observationError
        }

        self.onUpdate = onUpdate
        self.onError = onError
        isObserving = true

        return BlockPerformanceObservation { [weak self] in
            guard let self, isObserving else { return }

            isObserving = false
            cancellationCount += 1
        }
    }

    func emit(_ performances: [SportPerformance]) {
        onUpdate?(performances)
    }

    func emit(_ error: Error) {
        onError?(error)
    }

    func save(_ performance: SportPerformance) async throws {
        if let writeError {
            throw writeError
        }

        savedPerformances.append(performance)
    }

    func update(_ performance: SportPerformance) async throws {
        if let writeError {
            throw writeError
        }

        updatedPerformances.append(performance)
    }

    func delete(_ performance: SportPerformance) async throws {
        if let writeError {
            throw writeError
        }

        deletedPerformances.append(performance)
    }
}
