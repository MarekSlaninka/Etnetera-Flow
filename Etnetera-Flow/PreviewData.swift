#if DEBUG
import Foundation

enum PreviewData {
    static let running = SportPerformance(
        id: UUID(),
        name: "Ranný beh",
        location: "Bratislava",
        duration: 2_700,
        storage: .local,
        createdAt: .now.addingTimeInterval(-86_400)
    )

    static let swimming = SportPerformance(
        id: UUID(),
        name: "Večerné plávanie",
        location: "Pasienky",
        duration: 3_600,
        storage: .remote,
        createdAt: .now.addingTimeInterval(-7_200)
    )

    static func makeRepository(
        performances: [SportPerformance] = [running, swimming]
    ) -> PreviewSportPerformanceRepository {
        PreviewSportPerformanceRepository(performances: performances)
    }
}

@MainActor
final class PreviewSportPerformanceRepository: SportPerformanceRepository {
    private var performances: [SportPerformance]
    private var observers: [UUID: ([SportPerformance]) -> Void] = [:]

    init(performances: [SportPerformance]) {
        self.performances = performances
    }

    func observePerformances(
        onUpdate: @escaping ([SportPerformance]) -> Void,
        onError: @escaping (Error) -> Void
    ) async throws -> any PerformanceObservation {
        let identifier = UUID()
        observers[identifier] = onUpdate
        onUpdate(performances)

        return BlockPerformanceObservation { [weak self] in
            self?.observers[identifier] = nil
        }
    }

    func save(_ performance: SportPerformance) async throws {
        performances.append(performance)
        publishChanges()
    }

    func update(_ performance: SportPerformance) async throws {
        guard let index = performances.firstIndex(where: { $0.id == performance.id }) else {
            return
        }

        performances[index] = performance
        publishChanges()
    }

    func delete(_ performance: SportPerformance) async throws {
        performances.removeAll { $0.id == performance.id }
        publishChanges()
    }

    private func publishChanges() {
        observers.values.forEach { $0(performances) }
    }
}
#endif
