import Foundation
import Testing
@testable import Etnetera_Flow

@MainActor
struct PerformanceCoordinateTests {
    @Test
    func buildsFromAPairOfValues() throws {
        let coordinate = try #require(
            PerformanceCoordinate(latitude: 48.1486, longitude: 17.1077)
        )

        #expect(coordinate.latitude == 48.1486)
        #expect(coordinate.longitude == 17.1077)
    }

    @Test(arguments: [
        (Double?.none, Double?.some(17.1077)),
        (Double?.some(48.1486), Double?.none),
        (Double?.none, Double?.none),
    ])
    func requiresBothValues(latitude: Double?, longitude: Double?) {
        #expect(PerformanceCoordinate.make(latitude: latitude, longitude: longitude) == nil)
    }

    @Test
    func makeValidatesTheRangeToo() {
        #expect(PerformanceCoordinate.make(latitude: 91, longitude: 17) == nil)
    }

    @Test(arguments: [
        (91.0, 17.0),
        (-91.0, 17.0),
        (48.0, 181.0),
        (48.0, -181.0),
    ])
    func rejectsValuesOutsideTheValidRange(latitude: Double, longitude: Double) {
        #expect(PerformanceCoordinate(latitude: latitude, longitude: longitude) == nil)
    }

    @Test
    func acceptsNullIslandAsARealCoordinate() {
        #expect(PerformanceCoordinate(latitude: 0, longitude: 0) != nil)
    }

    @Test
    func acceptsTheRangeBoundaries() {
        #expect(PerformanceCoordinate(latitude: 90, longitude: 180) != nil)
        #expect(PerformanceCoordinate(latitude: -90, longitude: -180) != nil)
    }
}
