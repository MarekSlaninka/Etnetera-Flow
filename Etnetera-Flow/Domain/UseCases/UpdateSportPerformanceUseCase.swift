struct UpdateSportPerformanceUseCase {
    let repository: SportPerformanceRepository

    func execute(_ performance: SportPerformance) async throws {
        try await repository.update(performance)
    }
}
