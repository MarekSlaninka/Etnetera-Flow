import Foundation
import SwiftData
import Testing
@testable import Etnetera_Flow

@MainActor
struct SwiftDataSportPerformanceRepositoryTests {
    private let container: ModelContainer
    private let repository: SwiftDataSportPerformanceRepository

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
    func savedPerformanceReachesObservers() async throws {
        // Arrange
        let recorder = try await observe()
        let performance = SportPerformance.stub(name: "Run")

        // Act
        try await repository.save(performance)

        // Assert
        #expect(recorder.latest == [performance])
    }

    @Test
    func observationEmitsNewestFirst() async throws {
        // Arrange
        let recorder = try await observe()
        let older = SportPerformance.stub(
            name: "Older",
            createdAt: Date(timeIntervalSince1970: 1_000)
        )
        let newer = SportPerformance.stub(
            name: "Newer",
            createdAt: Date(timeIntervalSince1970: 2_000)
        )

        // Act
        try await repository.save(older)
        try await repository.save(newer)

        // Assert
        #expect(recorder.latest.map(\.name) == ["Newer", "Older"])
    }

    @Test
    func updateChangesEditableFieldsAndKeepsCreationDate() async throws {
        // Arrange
        let recorder = try await observe()
        let original = SportPerformance.stub(name: "Run", location: "Bratislava")
        try await repository.save(original)
        let edited = SportPerformance.stub(
            id: original.id,
            name: "Evening run",
            location: "Košice",
            duration: 3_600,
            createdAt: Date(timeIntervalSince1970: 9_999)
        )

        // Act
        try await repository.update(edited)

        // Assert
        let stored = try #require(recorder.latest.first)
        #expect(stored.name == "Evening run")
        #expect(stored.location == "Košice")
        #expect(stored.duration == 3_600)
        #expect(stored.createdAt == original.createdAt)
    }

    @Test
    func updatingUnknownPerformanceIsIgnored() async throws {
        // Arrange
        let recorder = try await observe()

        // Act
        try await repository.update(.stub(name: "Never saved"))

        // Assert
        #expect(recorder.latest.isEmpty)
    }

    @Test
    func deleteRemovesPerformance() async throws {
        // Arrange
        let recorder = try await observe()
        let performance = SportPerformance.stub()
        try await repository.save(performance)

        // Act
        try await repository.delete(performance)

        // Assert
        #expect(recorder.latest.isEmpty)
    }

    @Test
    func cancelledObservationStopsReceivingUpdates() async throws {
        // Arrange
        let recorder = PerformanceRecorder()
        let observation = try await repository.observePerformances(
            onUpdate: { recorder.record($0) },
            onError: { recorder.record($0) }
        )
        observation.cancel()
        let updatesBeforeSave = recorder.updates.count

        // Act
        try await repository.save(.stub())

        // Assert
        #expect(recorder.updates.count == updatesBeforeSave)
    }

    @Test
    func returnsEveryStoredPerformanceNewestFirst() async throws {
        // Arrange
        let recorder = try await observe()
        let count = 250

        // Act
        for index in 0 ..< count {
            try await repository.save(
                .stub(
                    name: "Performance \(index)",
                    createdAt: Date(timeIntervalSince1970: TimeInterval(index))
                )
            )
        }

        // Assert
        #expect(recorder.latest.count == count)
        #expect(recorder.latest.first?.name == "Performance \(count - 1)")
        #expect(recorder.latest.last?.name == "Performance 0")
    }

    @Test
    func storedPerformancesAreReportedAsLocal() async throws {
        // Arrange
        let recorder = try await observe()

        // Act
        try await repository.save(.stub(storage: .local))

        // Assert
        #expect(recorder.latest.allSatisfy { $0.storage == .local })
    }
}
