import Foundation

@MainActor
final class PerformanceObserver {
    private let repository: SportPerformanceRepository
    private var observation: (any PerformanceObservation)?
    private var startTask: Task<Void, Never>?

    init(repository: SportPerformanceRepository) {
        self.repository = repository
    }

    func start(
        onUpdate: @escaping ([SportPerformance]) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        stop()

        startTask = Task { [weak self] in
            guard let self else { return }

            do {
                let observation = try await repository.observePerformances(
                    onUpdate: onUpdate,
                    onError: onError
                )

                guard !Task.isCancelled else {
                    observation.cancel()
                    return
                }

                self.observation = observation
            } catch {
                onError(error)
            }
        }
    }

    func stop() {
        startTask?.cancel()
        startTask = nil
        observation?.cancel()
        observation = nil
    }

}
