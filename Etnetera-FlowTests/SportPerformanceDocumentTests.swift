import Foundation
import Testing
@testable import Etnetera_Flow

@MainActor
struct SportPerformanceDocumentTests {
    private let identifier = UUID(uuidString: "8A1B4C2D-0000-4000-8000-00000000ABCD")!
    private let createdAt = Date(timeIntervalSince1970: 1_767_225_600)
    private let bratislava = PerformanceCoordinate(latitude: 48.1486, longitude: 17.1077)

    private func decode(_ json: String) throws -> SportPerformanceDocument {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(SportPerformanceDocument.self, from: Data(json.utf8))
    }

    private func roundTrip(_ document: SportPerformanceDocument) throws -> SportPerformanceDocument {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(
            SportPerformanceDocument.self,
            from: try encoder.encode(document)
        )
    }

    @Test
    func flattensACoordinateIntoTwoFields() {
        // Arrange
        let performance = SportPerformance.stub(coordinate: bratislava)

        // Act
        let document = SportPerformanceDocument(performance)

        // Assert
        #expect(document.latitude == bratislava?.latitude)
        #expect(document.longitude == bratislava?.longitude)
    }

    @Test
    func leavesBothFieldsEmptyWithoutACoordinate() {
        // Arrange
        let performance = SportPerformance.stub(coordinate: nil)

        // Act
        let document = SportPerformanceDocument(performance)

        // Assert
        #expect(document.latitude == nil)
        #expect(document.longitude == nil)
    }

    @Test
    func returnsToTheDomainUnchanged() throws {
        // Arrange
        let performance = SportPerformance.stub(
            id: identifier,
            name: "Morning run",
            location: "Bratislava",
            coordinate: bratislava,
            duration: 2_700,
            storage: .remote,
            createdAt: createdAt
        )

        // Act
        let restored = try SportPerformanceDocument(performance).domainModel()

        // Assert
        #expect(restored == performance)
    }

    @Test
    func alwaysReportsRemoteStorage() throws {
        // Arrange
        let document = SportPerformanceDocument(.stub(storage: .local))

        // Act
        let restored = try document.domainModel()

        // Assert
        #expect(restored.storage == .remote)
    }

    @Test
    func survivesAnEncodingRoundTrip() throws {
        // Arrange
        let performance = SportPerformance.stub(
            id: identifier,
            coordinate: bratislava,
            storage: .remote,
            createdAt: createdAt
        )

        // Act
        let restored = try roundTrip(SportPerformanceDocument(performance)).domainModel()

        // Assert
        #expect(restored == performance)
    }

    @Test
    func survivesAnEncodingRoundTripWithoutACoordinate() throws {
        // Arrange
        let performance = SportPerformance.stub(
            id: identifier,
            coordinate: nil,
            storage: .remote,
            createdAt: createdAt
        )

        // Act
        let restored = try roundTrip(SportPerformanceDocument(performance)).domainModel()

        // Assert
        #expect(restored == performance)
        #expect(restored.coordinate == nil)
    }

    @Test
    func ignoresAStoredCoordinateOutsideTheValidRange() throws {
        // Arrange
        let document = try decode("""
        {
            "id": "\(identifier.uuidString)",
            "name": "Morning run",
            "location": "Bratislava",
            "latitude": 910.0,
            "longitude": 17.1077,
            "duration": 2700,
            "createdAt": "2026-01-01T00:00:00Z"
        }
        """)

        // Act
        let performance = try document.domainModel()

        // Assert
        #expect(performance.coordinate == nil)
        #expect(performance.name == "Morning run")
    }

    @Test
    func rejectsAnIdentifierThatIsNotAUUID() throws {
        // Arrange
        let document = try decode("""
        {
            "id": "not-a-uuid",
            "name": "Morning run",
            "location": "Bratislava",
            "duration": 2700,
            "createdAt": "2026-01-01T00:00:00Z"
        }
        """)

        // Act & Assert
        #expect(throws: SportPerformanceDocumentError.malformedIdentifier("not-a-uuid")) {
            try document.domainModel()
        }
    }
}
