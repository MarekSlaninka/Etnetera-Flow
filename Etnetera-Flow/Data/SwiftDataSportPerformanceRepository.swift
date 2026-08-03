import Foundation
import SwiftData

@MainActor
final class SwiftDataSportPerformanceRepository: SportPerformanceRepository {
    private let modelContext: ModelContext
    private var observers: [UUID: ([SportPerformance]) -> Void] = [:]

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func observePerformances(
        onUpdate: @escaping ([SportPerformance]) -> Void,
        onError: @escaping (Error) -> Void
    ) async throws -> any PerformanceObservation {
        let identifier = UUID()
        observers[identifier] = onUpdate
        onUpdate(loadPerformances())

        return BlockPerformanceObservation { [weak self] in
            self?.observers[identifier] = nil
        }
    }

    func save(_ performance: SportPerformance) async throws {
        modelContext.insert(SportPerformanceRecord(performance: performance))
        try modelContext.save()
        publishChanges()
    }

    func update(_ performance: SportPerformance) async throws {
        guard let record = try fetchRecord(with: performance.id) else { return }

        record.update(from: performance)
        try modelContext.save()
        publishChanges()
    }

    func delete(_ performance: SportPerformance) async throws {
        guard let record = try fetchRecord(with: performance.id) else { return }

        modelContext.delete(record)
        try modelContext.save()
        publishChanges()
    }

    private func fetchRecord(with identifier: UUID) throws -> SportPerformanceRecord? {
        let predicate = #Predicate<SportPerformanceRecord> { $0.identifier == identifier }
        let descriptor = FetchDescriptor<SportPerformanceRecord>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    private func loadPerformances() -> [SportPerformance] {
        var descriptor = FetchDescriptor<SportPerformanceRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = PerformanceFeed.pageSize

        do {
            return try modelContext.fetch(descriptor).map(\.domainModel)
        } catch {
            return []
        }
    }

    private func publishChanges() {
        let values = loadPerformances()
        observers.values.forEach { $0(values) }
    }
}
