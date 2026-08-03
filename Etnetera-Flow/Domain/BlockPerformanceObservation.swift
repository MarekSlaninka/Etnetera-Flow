@MainActor
final class BlockPerformanceObservation: PerformanceObservation {
    private let cancellation: @Sendable @MainActor () -> Void

    init(cancellation: @escaping @Sendable @MainActor () -> Void) {
        self.cancellation = cancellation
    }

    func cancel() {
        cancellation()
    }

    deinit {
        let cancellation = self.cancellation
        Task { @MainActor in cancellation() }
    }
}
