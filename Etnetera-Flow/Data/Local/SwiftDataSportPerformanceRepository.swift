import Foundation
import OSLog
import SwiftData

@MainActor
final class SwiftDataSportPerformanceRepository: SportPerformanceRepository {
    private struct Observer {
        let onUpdate: ([SportPerformance]) -> Void
        let onError: (Error) -> Void
    }

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Flow",
        category: "SwiftDataSportPerformanceRepository"
    )

    private let modelContext: ModelContext
    private var observers: [UUID: Observer] = [:]

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func observePerformances(
        onUpdate: @escaping ([SportPerformance]) -> Void,
        onError: @escaping (Error) -> Void
    ) async throws -> any PerformanceObservation {
        let identifier = UUID()
        observers[identifier] = Observer(onUpdate: onUpdate, onError: onError)

        do {
            onUpdate(try loadPerformances())
        } catch {
            Self.log(error, operation: "Loading stored performances")
            onUpdate([])
            onError(error)
        }

        return BlockPerformanceObservation { [weak self] in
            self?.observers[identifier] = nil
        }
    }

    func save(_ performance: SportPerformance) async throws {
        do {
            modelContext.insert(SportPerformanceRecord(performance: performance))
            try modelContext.save()
        } catch {
            Self.log(error, operation: "Saving a performance")
            throw error
        }

        publishChanges()
    }

    func update(_ performance: SportPerformance) async throws {
        do {
            guard let record = try fetchRecord(with: performance.id) else { return }

            record.update(from: performance)
            try modelContext.save()
        } catch {
            Self.log(error, operation: "Updating a performance")
            throw error
        }

        publishChanges()
    }

    func delete(_ performance: SportPerformance) async throws {
        do {
            guard let record = try fetchRecord(with: performance.id) else { return }

            modelContext.delete(record)
            try modelContext.save()
        } catch {
            Self.log(error, operation: "Deleting a performance")
            throw error
        }

        publishChanges()
    }

    private func fetchRecord(with identifier: UUID) throws -> SportPerformanceRecord? {
        let predicate = #Predicate<SportPerformanceRecord> { $0.identifier == identifier }
        let descriptor = FetchDescriptor<SportPerformanceRecord>(predicate: predicate)

        return try modelContext.fetch(descriptor).first
    }

    private func loadPerformances() throws -> [SportPerformance] {
        let descriptor = FetchDescriptor<SportPerformanceRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        return try modelContext.fetch(descriptor).map(\.domainModel)
    }

    private func publishChanges() {
        do {
            let performances = try loadPerformances()
            observers.values.forEach { $0.onUpdate(performances) }
        } catch {
            Self.log(error, operation: "Reloading stored performances")
            observers.values.forEach { $0.onError(error) }
        }
    }

    private static func log(_ error: Error, operation: String) {
        logger.error("\(operation, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
    }
}
