@MainActor
protocol SportPerformanceRepository {
    func observePerformances(
        onUpdate: @escaping ([SportPerformance]) -> Void,
        onError: @escaping (Error) -> Void
    ) async throws -> any PerformanceObservation
    func save(_ performance: SportPerformance) async throws
    func update(_ performance: SportPerformance) async throws
    func delete(_ performance: SportPerformance) async throws
}

@MainActor
protocol PerformanceObservation: AnyObject {
    func cancel()
}
