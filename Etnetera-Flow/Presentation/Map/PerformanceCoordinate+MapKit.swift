import MapKit
import SwiftUI

extension PerformanceCoordinate {
    var mapCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var region: MKCoordinateRegion {
        MKCoordinateRegion(center: mapCoordinate, span: PerformanceMapFocus.span)
    }
}

enum PerformanceMapFocus {
    static let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)

    static func region(focusing performance: SportPerformance?) -> MKCoordinateRegion? {
        performance?.coordinate?.region
    }

    static func position(focusing performance: SportPerformance?) -> MapCameraPosition {
        guard let region = region(focusing: performance) else { return .automatic }

        return .region(region)
    }

    static func selection(focusing performance: SportPerformance?) -> UUID? {
        guard let performance, performance.coordinate != nil else { return nil }

        return performance.id
    }
}
