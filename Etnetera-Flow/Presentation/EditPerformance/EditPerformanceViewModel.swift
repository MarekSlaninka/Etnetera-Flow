import Foundation
import Observation

@MainActor
@Observable
final class EditPerformanceViewModel {
    var name: String
    var location: String
    var duration: Int
    private(set) var errorMessage: String?

    private let originalPerformance: SportPerformance
    private let updateUseCase: UpdateSportPerformanceUseCase

    var isSaveEnabled: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && duration > 0
    }

    init(performance: SportPerformance, updateUseCase: UpdateSportPerformanceUseCase) {
        originalPerformance = performance
        self.updateUseCase = updateUseCase
        name = performance.name
        location = performance.location
        duration = Self.editableMinutes(from: performance.duration)
    }

    private static func editableMinutes(from duration: TimeInterval) -> Int {
        let minutes = (duration / 60).rounded()
        let snapped = Int((minutes / 5).rounded()) * 5
        return min(max(snapped, 5), 720)
    }

    func save() async -> Bool {
        guard isSaveEnabled else { return false }

        let updatedPerformance = SportPerformance(
            id: originalPerformance.id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            duration: TimeInterval(duration * 60),
            storage: originalPerformance.storage,
            createdAt: originalPerformance.createdAt
        )

        do {
            try await updateUseCase.execute(updatedPerformance)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func dismissError() {
        errorMessage = nil
    }
}
