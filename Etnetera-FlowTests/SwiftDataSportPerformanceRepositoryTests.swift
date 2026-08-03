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

    @Test
    func savedPerformanceReachesObservers() async throws {
        let recorder = PerformanceRecorder()
        let performance = SportPerformance.stub(name: "Run")

        _ = try await repository.observePerformances(
            onUpdate: { recorder.record($0) },
            onError: { recorder.record($0) }
        )
        try await repository.save(performance)

        #expect(recorder.latest == [performance])
    }

    @Test
    func observationEmitsNewestFirst() async throws {
        let recorder = PerformanceRecorder()
        let older = SportPerformance.stub(
            name: "Older",
            createdAt: Date(timeIntervalSince1970: 1_000)
        )
        let newer = SportPerformance.stub(
            name: "Newer",
            createdAt: Date(timeIntervalSince1970: 2_000)
        )

        _ = try await repository.observePerformances(
            onUpdate: { recorder.record($0) },
            onError: { recorder.record($0) }
        )
        try await repository.save(older)
        try await repository.save(newer)

        #expect(recorder.latest.map(\.name) == ["Newer", "Older"])
    }

    @Test
    func updateChangesEditableFieldsAndKeepsCreationDate() async throws {
        let recorder = PerformanceRecorder()
        let original = SportPerformance.stub(name: "Run", location: "Bratislava")

        _ = try await repository.observePerformances(
            onUpdate: { recorder.record($0) },
            onError: { recorder.record($0) }
        )
        try await repository.save(original)

        let edited = SportPerformance.stub(
            id: original.id,
            name: "Evening run",
            location: "Košice",
            duration: 3_600,
            createdAt: Date(timeIntervalSince1970: 9_999)
        )
        try await repository.update(edited)

        let stored = try #require(recorder.latest.first)
        #expect(stored.name == "Evening run")
        #expect(stored.location == "Košice")
        #expect(stored.duration == 3_600)
        #expect(stored.createdAt == original.createdAt)
    }

    @Test
    func updatingUnknownPerformanceIsIgnored() async throws {
        let recorder = PerformanceRecorder()

        _ = try await repository.observePerformances(
            onUpdate: { recorder.record($0) },
            onError: { recorder.record($0) }
        )
        try await repository.update(.stub(name: "Never saved"))

        #expect(recorder.latest.isEmpty)
    }

    @Test
    func deleteRemovesPerformance() async throws {
        let recorder = PerformanceRecorder()
        let performance = SportPerformance.stub()

        _ = try await repository.observePerformances(
            onUpdate: { recorder.record($0) },
            onError: { recorder.record($0) }
        )
        try await repository.save(performance)
        try await repository.delete(performance)

        #expect(recorder.latest.isEmpty)
    }

    @Test
    func cancelledObservationStopsReceivingUpdates() async throws {
        let recorder = PerformanceRecorder()

        let observation = try await repository.observePerformances(
            onUpdate: { recorder.record($0) },
            onError: { recorder.record($0) }
        )
        observation.cancel()

        let updatesBeforeSave = recorder.updates.count
        try await repository.save(.stub())

        #expect(recorder.updates.count == updatesBeforeSave)
    }

    @Test
    func storedPerformancesAreReportedAsLocal() async throws {
        let recorder = PerformanceRecorder()

        _ = try await repository.observePerformances(
            onUpdate: { recorder.record($0) },
            onError: { recorder.record($0) }
        )
        try await repository.save(.stub(storage: .local))

        #expect(recorder.latest.allSatisfy { $0.storage == .local })
    }
}
