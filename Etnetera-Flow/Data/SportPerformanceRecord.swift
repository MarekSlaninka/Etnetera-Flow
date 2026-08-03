import Foundation
import SwiftData

@Model
final class SportPerformanceRecord {
    @Attribute(.unique) var identifier: UUID
    var name: String
    var location: String
    var duration: TimeInterval
    var createdAt: Date

    init(performance: SportPerformance) {
        identifier = performance.id
        name = performance.name
        location = performance.location
        duration = performance.duration
        createdAt = performance.createdAt
    }

    func update(from performance: SportPerformance) {
        name = performance.name
        location = performance.location
        duration = performance.duration
    }

    var domainModel: SportPerformance {
        SportPerformance(
            id: identifier,
            name: name,
            location: location,
            duration: duration,
            storage: .local,
            createdAt: createdAt
        )
    }
}
