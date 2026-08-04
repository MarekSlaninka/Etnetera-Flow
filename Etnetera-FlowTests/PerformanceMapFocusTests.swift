import Foundation
import MapKit
import SwiftUI
import Testing
@testable import Etnetera_Flow

@MainActor
struct PerformanceMapFocusTests {
    private let bratislava = PerformanceCoordinate(latitude: 48.1486, longitude: 17.1077)

    @Test
    func centresOnTheFocusedPerformance() throws {
        // Arrange
        let performance = SportPerformance.stub(coordinate: bratislava)

        // Act
        let region = try #require(PerformanceMapFocus.region(focusing: performance))

        // Assert
        #expect(region.center.latitude == bratislava?.latitude)
        #expect(region.center.longitude == bratislava?.longitude)
    }

    @Test
    func zoomsInCloserThanTheWholeFeed() throws {
        // Arrange
        let performance = SportPerformance.stub(coordinate: bratislava)

        // Act
        let region = try #require(PerformanceMapFocus.region(focusing: performance))

        // Assert
        #expect(region.span.latitudeDelta == PerformanceMapFocus.span.latitudeDelta)
        #expect(region.span.longitudeDelta == PerformanceMapFocus.span.longitudeDelta)
    }

    @Test
    func hasNoRegionForAPerformanceWithoutAPlace() {
        // Arrange
        let performance = SportPerformance.stub(coordinate: nil)

        // Act
        let region = PerformanceMapFocus.region(focusing: performance)

        // Assert
        #expect(region == nil)
    }

    @Test
    func hasNoRegionWhenNothingIsFocused() {
        // Arrange
        let performance: SportPerformance? = nil

        // Act
        let region = PerformanceMapFocus.region(focusing: performance)

        // Assert
        #expect(region == nil)
    }

    @Test
    func fallsBackToAnAutomaticCameraWithoutAPlace() {
        // Arrange
        let performance = SportPerformance.stub(coordinate: nil)

        // Act
        let position = PerformanceMapFocus.position(focusing: performance)

        // Assert
        #expect(position == .automatic)
    }

    @Test
    func buildsARegionCameraForAFocusedPlace() {
        // Arrange
        let performance = SportPerformance.stub(coordinate: bratislava)

        // Act
        let position = PerformanceMapFocus.position(focusing: performance)

        // Assert
        #expect(position != .automatic)
        #expect(position.region?.center.latitude == bratislava?.latitude)
    }

    @Test
    func selectsTheFocusedPerformance() {
        // Arrange
        let performance = SportPerformance.stub(coordinate: bratislava)

        // Act
        let selection = PerformanceMapFocus.selection(focusing: performance)

        // Assert
        #expect(selection == performance.id)
    }

    @Test
    func selectsNothingForAPerformanceWithoutAPlace() {
        // Arrange
        let performance = SportPerformance.stub(coordinate: nil)

        // Act
        let selection = PerformanceMapFocus.selection(focusing: performance)

        // Assert
        #expect(selection == nil)
    }

    @Test
    func selectsNothingWhenNothingIsFocused() {
        // Arrange
        let performance: SportPerformance? = nil

        // Act
        let selection = PerformanceMapFocus.selection(focusing: performance)

        // Assert
        #expect(selection == nil)
    }

    @Test
    func selectsExactlyThePerformanceThatDrivesTheCamera() throws {
        // Arrange
        let performance = SportPerformance.stub(coordinate: bratislava)

        // Act
        let selection = PerformanceMapFocus.selection(focusing: performance)
        let region = try #require(PerformanceMapFocus.region(focusing: performance))

        // Assert
        #expect(selection == performance.id)
        #expect(region.center.latitude == performance.coordinate?.latitude)
    }

    @Test
    func derivesTheRegionFromTheCoordinateItself() throws {
        // Arrange
        let coordinate = try #require(bratislava)

        // Act
        let region = coordinate.region

        // Assert
        #expect(region.center.latitude == coordinate.latitude)
        #expect(region.center.longitude == coordinate.longitude)
    }
}
