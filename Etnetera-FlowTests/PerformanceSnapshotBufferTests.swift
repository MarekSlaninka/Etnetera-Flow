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
        #expect(buffer.ordered.isEmpty)
    }

    @Test
    func ordersNewestFirst() {
        buffer.insert(performance("Old", at: 1_000), for: "a")
        buffer.insert(performance("New", at: 3_000), for: "b")
        buffer.insert(performance("Middle", at: 2_000), for: "c")

        #expect(buffer.ordered.map(\.name) == ["New", "Middle", "Old"])
    }

    @Test
    func insertingTheSameDocumentReplacesIt() {
        buffer.insert(performance("Before", at: 1_000), for: "a")
        buffer.insert(performance("After", at: 1_000), for: "a")

        #expect(buffer.ordered.map(\.name) == ["After"])
    }

    @Test
    func reinsertingWithANewDateReordersTheFeed() {
        buffer.insert(performance("First", at: 3_000), for: "a")
        buffer.insert(performance("Second", at: 2_000), for: "b")
        buffer.insert(performance("First", at: 1_000), for: "a")

        #expect(buffer.ordered.map(\.name) == ["Second", "First"])
    }

    @Test
    func removingDropsTheDocument() {
        buffer.insert(performance("Kept", at: 2_000), for: "a")
        buffer.insert(performance("Dropped", at: 1_000), for: "b")

        buffer.remove("b")

        #expect(buffer.ordered.map(\.name) == ["Kept"])
    }

    @Test
    func removingAnUnknownDocumentIsHarmless() {
        buffer.insert(performance("Kept", at: 1_000), for: "a")

        buffer.remove("missing")

        #expect(buffer.ordered.count == 1)
    }

    @Test
    func breaksTiesOnIdentifierSoOrderingIsStable() {
        let earlier = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let later = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let sameMoment = Date(timeIntervalSince1970: 5_000)

        buffer.insert(.stub(id: later, name: "Later", createdAt: sameMoment), for: "b")
        buffer.insert(.stub(id: earlier, name: "Earlier", createdAt: sameMoment), for: "a")

        #expect(buffer.ordered.map(\.name) == ["Earlier", "Later"])
    }
}
