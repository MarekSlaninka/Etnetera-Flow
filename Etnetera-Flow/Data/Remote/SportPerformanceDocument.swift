import Foundation

struct SportPerformanceDocument: Codable {
    static let createdAtField = "createdAt"

    let id: String
    let name: String
    let location: String
    let latitude: Double?
    let longitude: Double?
    let duration: TimeInterval
    let createdAt: Date

    init(_ performance: SportPerformance) {
        id = performance.id.uuidString
        name = performance.name
        location = performance.location
        latitude = performance.coordinate?.latitude
        longitude = performance.coordinate?.longitude
        duration = performance.duration
        createdAt = performance.createdAt
    }

    func domainModel() throws -> SportPerformance {
        guard let identifier = UUID(uuidString: id) else {
            throw SportPerformanceDocumentError.malformedIdentifier(id)
        }

        return SportPerformance(
            id: identifier,
            name: name,
            location: location,
            coordinate: PerformanceCoordinate.make(latitude: latitude, longitude: longitude),
            duration: duration,
            storage: .remote,
            createdAt: createdAt
        )
    }
}

enum SportPerformanceDocumentError: LocalizedError, Equatable {
    case malformedIdentifier(String)

    var errorDescription: String? {
        switch self {
        case let .malformedIdentifier(value):
            "Sport performance identifier is not a UUID: \(value)."
        }
    }
}
