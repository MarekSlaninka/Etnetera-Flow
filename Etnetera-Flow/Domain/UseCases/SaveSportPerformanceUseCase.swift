struct SaveSportPerformanceUseCase {
    let repository: SportPerformanceRepository

    func execute(_ performance: SportPerformance) async throws {
        try await repository.save(performance)
    }
}
