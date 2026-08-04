import Foundation
import Testing
@testable import Etnetera_Flow

@MainActor
struct PerformanceSnapshotBufferTests {
    private let buffer = PerformanceSnapshotBuffer()

    private func performance(_ name: String, at seconds: TimeInterval) -> SportPerformance {
        .stub(name: name, storage: .remote, createdAt: Date(timeIntervalSince1970: seconds))
    }

    @Test
    func startsEmpty() {
        // Arrange
        let buffer = buffer

        // Act
        let ordered = buffer.ordered

        // Assert
        #expect(ordered.isEmpty)
    }

    @Test
    func ordersNewestFirst() {
        // Arrange
        buffer.insert(performance("Old", at: 1_000), for: "a")
        buffer.insert(performance("New", at: 3_000), for: "b")
        buffer.insert(performance("Middle", at: 2_000), for: "c")

        // Act
        let ordered = buffer.ordered

        // Assert
        #expect(ordered.map(\.name) == ["New", "Middle", "Old"])
    }

    @Test
    func insertingTheSameDocumentReplacesIt() {
        // Arrange
        buffer.insert(performance("Before", at: 1_000), for: "a")

        // Act
        buffer.insert(performance("After", at: 1_000), for: "a")

        // Assert
        #expect(buffer.ordered.map(\.name) == ["After"])
    }

    @Test
    func reinsertingWithANewDateReordersTheFeed() {
        // Arrange
        buffer.insert(performance("First", at: 3_000), for: "a")
        buffer.insert(performance("Second", at: 2_000), for: "b")

        // Act
        buffer.insert(performance("First", at: 1_000), for: "a")

        // Assert
        #expect(buffer.ordered.map(\.name) == ["Second", "First"])
    }

    @Test
    func removingDropsTheDocument() {
        // Arrange
        buffer.insert(performance("Kept", at: 2_000), for: "a")
        buffer.insert(performance("Dropped", at: 1_000), for: "b")

        // Act
        buffer.remove("b")

        // Assert
        #expect(buffer.ordered.map(\.name) == ["Kept"])
    }

    @Test
    func removingAnUnknownDocumentIsHarmless() {
        // Arrange
        buffer.insert(performance("Kept", at: 1_000), for: "a")

        // Act
        buffer.remove("missing")

        // Assert
        #expect(buffer.ordered.count == 1)
    }

    @Test
    func breaksTiesOnIdentifierSoOrderingIsStable() {
        // Arrange
        let earlier = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let later = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let sameMoment = Date(timeIntervalSince1970: 5_000)
        buffer.insert(.stub(id: later, name: "Later", createdAt: sameMoment), for: "b")
        buffer.insert(.stub(id: earlier, name: "Earlier", createdAt: sameMoment), for: "a")

        // Act
        let ordered = buffer.ordered

        // Assert
        #expect(ordered.map(\.name) == ["Earlier", "Later"])
    }
}
