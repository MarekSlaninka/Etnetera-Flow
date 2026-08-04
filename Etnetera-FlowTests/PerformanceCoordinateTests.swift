import Foundation
import Testing
@testable import Etnetera_Flow

@MainActor
struct PerformanceCoordinateTests {
    @Test
    func buildsFromAPairOfValues() throws {
        // Arrange
        let latitude = 48.1486
        let longitude = 17.1077

        // Act
        let coordinate = try #require(
            PerformanceCoordinate(latitude: latitude, longitude: longitude)
        )

        // Assert
        #expect(coordinate.latitude == latitude)
        #expect(coordinate.longitude == longitude)
    }

    @Test(arguments: [
        (Double?.none, Double?.some(17.1077)),
        (Double?.some(48.1486), Double?.none),
        (Double?.none, Double?.none),
    ])
    func requiresBothValues(latitude: Double?, longitude: Double?) {
        // Arrange
        let pair = (latitude, longitude)

        // Act
        let coordinate = PerformanceCoordinate.make(latitude: pair.0, longitude: pair.1)

        // Assert
        #expect(coordinate == nil)
    }

    @Test(arguments: [
        (91.0, 17.0),
        (-91.0, 17.0),
        (48.0, 181.0),
        (48.0, -181.0),
    ])
    func rejectsValuesOutsideTheValidRange(latitude: Double, longitude: Double) {
        // Arrange
        let pair = (latitude, longitude)

        // Act
        let coordinate = PerformanceCoordinate(latitude: pair.0, longitude: pair.1)

        // Assert
        #expect(coordinate == nil)
    }

    @Test
    func makeValidatesTheRangeToo() {
        // Arrange
        let outOfRange = 91.0

        // Act
        let coordinate = PerformanceCoordinate.make(latitude: outOfRange, longitude: 17)

        // Assert
        #expect(coordinate == nil)
    }

    @Test
    func acceptsNullIslandAsARealCoordinate() {
        // Arrange
        let nullIsland = (latitude: 0.0, longitude: 0.0)

        // Act
        let coordinate = PerformanceCoordinate(
            latitude: nullIsland.latitude,
            longitude: nullIsland.longitude
        )

        // Assert
        #expect(coordinate != nil)
    }

    @Test(arguments: [
        (90.0, 180.0),
        (-90.0, -180.0),
    ])
    func acceptsTheRangeBoundaries(latitude: Double, longitude: Double) {
        // Arrange
        let pair = (latitude, longitude)

        // Act
        let coordinate = PerformanceCoordinate(latitude: pair.0, longitude: pair.1)

        // Assert
        #expect(coordinate != nil)
    }
}
