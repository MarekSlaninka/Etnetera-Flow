import Foundation
import SwiftData
import Testing
@testable import Etnetera_Flow

@MainActor
struct CoordinatePersistenceTests {
    private let container: ModelContainer
    private let repository: SwiftDataSportPerformanceRepository
    private let bratislava = PerformanceCoordinate(latitude: 48.1486, longitude: 17.1077)
    private let kosice = PerformanceCoordinate(latitude: 48.7164, longitude: 21.2611)

    init() throws {
        container = try ModelContainer(
            for: SportPerformanceRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        repository = SwiftDataSportPerformanceRepository(modelContext: container.mainContext)
    }

    private func observe() async throws -> PerformanceRecorder {
        let recorder = PerformanceRecorder()

        _ = try await repository.observePerformances(
            onUpdate: { recorder.record($0) },
            onError: { recorder.record($0) }
        )

        return recorder
    }

    @Test
    func roundTripsACoordinateThroughSwiftData() async throws {
        // Arrange
        let recorder = try await observe()

        // Act
        try await repository.save(.stub(coordinate: bratislava))

        // Assert
        #expect(recorder.latest.first?.coordinate == bratislava)
    }

    @Test
    func keepsPerformancesWithoutACoordinate() async throws {
        // Arrange
        let recorder = try await observe()

        // Act
        try await repository.save(.stub(coordinate: nil))

        // Assert
        #expect(recorder.latest.count == 1)
        #expect(recorder.latest.first?.coordinate == nil)
    }

    @Test
    func updatingReplacesTheCoordinate() async throws {
        // Arrange
        let recorder = try await observe()
        let original = SportPerformance.stub(coordinate: bratislava)
        try await repository.save(original)

        // Act
        try await repository.update(.stub(id: original.id, coordinate: kosice))

        // Assert
        #expect(recorder.latest.first?.coordinate == kosice)
    }

    @Test
    func updatingCanRemoveTheCoordinate() async throws {
        // Arrange
        let recorder = try await observe()
        let original = SportPerformance.stub(coordinate: bratislava)
        try await repository.save(original)

        // Act
        try await repository.update(.stub(id: original.id, coordinate: nil))

        // Assert
        #expect(recorder.latest.first?.coordinate == nil)
    }

    @Test
    func recordMapsBothDirections() {
        // Arrange
        let performance = SportPerformance.stub(coordinate: bratislava)

        // Act
        let record = SportPerformanceRecord(performance: performance)

        // Assert
        #expect(record.latitude == bratislava?.latitude)
        #expect(record.longitude == bratislava?.longitude)
        #expect(record.domainModel.coordinate == bratislava)
    }

    @Test
    func recordWithOnlyOneStoredValueYieldsNoCoordinate() {
        // Arrange
        let record = SportPerformanceRecord(performance: .stub(coordinate: bratislava))

        // Act
        record.longitude = nil

        // Assert
        #expect(record.domainModel.coordinate == nil)
    }
}
