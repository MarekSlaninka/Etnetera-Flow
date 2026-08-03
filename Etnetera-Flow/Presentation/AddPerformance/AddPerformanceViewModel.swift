import Foundation
import Observation

@MainActor
@Observable
final class AddPerformanceViewModel {
    var name = ""
    var location = ""
    var coordinate: PerformanceCoordinate?
    var duration = 30
    var storage: StorageType = .local
    private(set) var errorMessage: String?

    private let saveUseCase: SaveSportPerformanceUseCase

    var isSaveEnabled: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && duration > 0
    }

    init(saveUseCase: SaveSportPerformanceUseCase) { self.saveUseCase = saveUseCase }

    func save() async -> Bool {
        guard isSaveEnabled else { return false }

        let performance = SportPerformance(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            coordinate: coordinate,
            duration: TimeInterval(duration * 60),
            storage: storage,
            createdAt: .now
        )

        do {
            try await saveUseCase.execute(performance)
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
