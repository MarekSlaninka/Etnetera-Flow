import Foundation

@MainActor
final class PerformanceSnapshotBuffer {
    private var performancesByDocument: [String: SportPerformance] = [:]

    var ordered: [SportPerformance] {
        performancesByDocument.values.sorted { lhs, rhs in
            guard lhs.createdAt == rhs.createdAt else {
                return lhs.createdAt > rhs.createdAt
            }

            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    func insert(_ performance: SportPerformance, for documentIdentifier: String) {
        performancesByDocument[documentIdentifier] = performance
    }

    func remove(_ documentIdentifier: String) {
        performancesByDocument.removeValue(forKey: documentIdentifier)
    }
}
