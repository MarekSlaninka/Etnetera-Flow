import Foundation
import SwiftData

@Model
final class SportPerformanceRecord {
    @Attribute(.unique) var identifier: UUID
    var name: String
    var location: String
    var latitude: Double?
    var longitude: Double?
    var duration: TimeInterval
    var createdAt: Date

    init(performance: SportPerformance) {
        identifier = performance.id
        name = performance.name
        location = performance.location
        latitude = performance.coordinate?.latitude
        longitude = performance.coordinate?.longitude
        duration = performance.duration
        createdAt = performance.createdAt
    }

    func update(from performance: SportPerformance) {
        name = performance.name
        location = performance.location
        latitude = performance.coordinate?.latitude
        longitude = performance.coordinate?.longitude
        duration = performance.duration
    }

    var domainModel: SportPerformance {
        SportPerformance(
            id: identifier,
            name: name,
            location: location,
            coordinate: PerformanceCoordinate.make(latitude: latitude, longitude: longitude),
            duration: duration,
            storage: .local,
            createdAt: createdAt
        )
    }
}
