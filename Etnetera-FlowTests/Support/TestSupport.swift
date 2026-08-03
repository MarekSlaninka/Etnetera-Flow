import Foundation
@testable import Etnetera_Flow

extension SportPerformance {
    static func stub(
        id: UUID = UUID(),
        name: String = "Morning run",
        location: String = "Bratislava",
        duration: TimeInterval = 1_800,
        storage: StorageType = .local,
        createdAt: Date = Date(timeIntervalSince1970: 1_000_000)
    ) -> SportPerformance {
        SportPerformance(
            id: id,
            name: name,
            location: location,
            duration: duration,
            storage: storage,
            createdAt: createdAt
        )
    }
}

@MainActor
final class PerformanceRecorder {
    private(set) var updates: [[SportPerformance]] = []
    private(set) var errors: [Error] = []

    var latest: [SportPerformance] { updates.last ?? [] }

    func record(_ performances: [SportPerformance]) {
        updates.append(performances)
    }

    func record(_ error: Error) {
        errors.append(error)
    }
}

@MainActor
func waitUntil(_ condition: () -> Bool, iterations: Int = 500) async -> Bool {
    for _ in 0 ..< iterations {
        if condition() {
            return true
        }
        await Task.yield()
    }

    return condition()
}
