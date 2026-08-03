import Foundation

struct PerformanceCoordinate: Equatable, Sendable {
    static let validLatitudes = -90.0 ... 90.0
    static let validLongitudes = -180.0 ... 180.0

    let latitude: Double
    let longitude: Double

    init?(latitude: Double, longitude: Double) {
        guard
            Self.validLatitudes.contains(latitude),
            Self.validLongitudes.contains(longitude)
        else {
            return nil
        }

        self.latitude = latitude
        self.longitude = longitude
    }

    static func make(latitude: Double?, longitude: Double?) -> PerformanceCoordinate? {
        guard let latitude, let longitude else { return nil }

        return PerformanceCoordinate(latitude: latitude, longitude: longitude)
    }
}
