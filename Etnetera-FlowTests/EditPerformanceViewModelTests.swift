import Foundation
import Testing
@testable import Etnetera_Flow

@MainActor
struct EditPerformanceViewModelTests {
    private let repository = StubSportPerformanceRepository()
    private let bratislava = PerformanceCoordinate(latitude: 48.1486, longitude: 17.1077)
    private let kosice = PerformanceCoordinate(latitude: 48.7164, longitude: 21.2611)

    private func makeViewModel(
        for performance: SportPerformance
    ) -> EditPerformanceViewModel {
        EditPerformanceViewModel(
            performance: performance,
            updateUseCase: UpdateSportPerformanceUseCase(repository: repository)
        )
    }

    @Test
    func prefillsTheFormFromTheStoredPerformance() {
        // Arrange
        let performance = SportPerformance.stub(
            name: "Run",
            location: "Bratislava",
            duration: 2_700
        )

        // Act
        let viewModel = makeViewModel(for: performance)

        // Assert
        #expect(viewModel.name == "Run")
        #expect(viewModel.location == "Bratislava")
        #expect(viewModel.duration == 45)
    }

    @Test(arguments: [
        (TimeInterval(90), 5),
        (TimeInterval(0), 5),
        (TimeInterval(2_700), 45),
        (TimeInterval(3_660), 60),
        (TimeInterval(100_000), 720),
    ])
    func snapsDurationOntoTheStepperGrid(duration: TimeInterval, expected: Int) {
        // Arrange
        let performance = SportPerformance.stub(duration: duration)

        // Act
        let viewModel = makeViewModel(for: performance)

        // Assert
        #expect(viewModel.duration == expected)
    }

    @Test
    func prefilledDurationAlwaysSatisfiesValidation() {
        // Arrange
        let performance = SportPerformance.stub(duration: 90)

        // Act
        let viewModel = makeViewModel(for: performance)

        // Assert
        #expect(viewModel.isSaveEnabled)
    }

    @Test
    func prefillsTheCoordinateFromTheStoredPerformance() {
        // Arrange
        let performance = SportPerformance.stub(coordinate: kosice)

        // Act
        let viewModel = makeViewModel(for: performance)

        // Assert
        #expect(viewModel.coordinate == kosice)
    }

    @Test
    func savePreservesIdentityStorageAndCreationDate() async throws {
        // Arrange
        let original = SportPerformance.stub(
            storage: .remote,
            createdAt: Date(timeIntervalSince1970: 4_242)
        )
        let viewModel = makeViewModel(for: original)
        viewModel.name = "  Evening swim "

        // Act
        let didSave = await viewModel.save()

        // Assert
        let updated = try #require(repository.updatedPerformances.first)
        #expect(didSave)
        #expect(updated.id == original.id)
        #expect(updated.storage == .remote)
        #expect(updated.createdAt == original.createdAt)
        #expect(updated.name == "Evening swim")
    }

    @Test
    func saveCarriesAChangedCoordinate() async throws {
        // Arrange
        let viewModel = makeViewModel(for: .stub(coordinate: bratislava))
        viewModel.coordinate = kosice

        // Act
        _ = await viewModel.save()

        // Assert
        let updated = try #require(repository.updatedPerformances.first)
        #expect(updated.coordinate == kosice)
    }

    @Test
    func clearingTheCoordinateIsPersisted() async throws {
        // Arrange
        let viewModel = makeViewModel(for: .stub(coordinate: bratislava))
        viewModel.coordinate = nil

        // Act
        _ = await viewModel.save()

        // Assert
        let updated = try #require(repository.updatedPerformances.first)
        #expect(updated.coordinate == nil)
    }

    @Test
    func savingABlankNameIsRejected() async {
        // Arrange
        let viewModel = makeViewModel(for: .stub())
        viewModel.name = "   "

        // Act
        let didSave = await viewModel.save()

        // Assert
        #expect(!didSave)
        #expect(repository.updatedPerformances.isEmpty)
    }

    @Test
    func saveFailureReportsAnError() async {
        // Arrange
        let viewModel = makeViewModel(for: .stub())
        repository.writeError = StubSportPerformanceRepository.Failure.write

        // Act
        let didSave = await viewModel.save()

        // Assert
        #expect(!didSave)
        #expect(viewModel.errorMessage != nil)
    }
}
