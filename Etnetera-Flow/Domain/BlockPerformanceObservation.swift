@MainActor
final class BlockPerformanceObservation: PerformanceObservation {
    private let cancellation: @Sendable @MainActor () -> Void

    init(cancellation: @escaping @Sendable @MainActor () -> Void) {
        self.cancellation = cancellation
    }

    func cancel() {
        cancellation()
    }

    /// A `deinit` is nonisolated even on a main-actor class, so it must not touch
    /// main-actor state directly. `cancellation` is immutable and idempotent,
    /// which makes reading it here safe; the call itself is hopped back onto the
    /// main actor instead of running on whichever thread released this object.
    deinit {
        let cancellation = self.cancellation
        Task { @MainActor in cancellation() }
    }
}
