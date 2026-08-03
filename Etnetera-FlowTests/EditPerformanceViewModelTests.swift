import Foundation
import Testing
@testable import Etnetera_Flow

@MainActor
struct EditPerformanceViewModelTests {
    private let repository = StubSportPerformanceRepository()

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
        let viewModel = makeViewModel(
            for: .stub(name: "Run", location: "Bratislava", duration: 2_700)
        )

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
        let viewModel = makeViewModel(for: .stub(duration: duration))

        #expect(viewModel.duration == expected)
    }

    @Test
    func prefilledDurationAlwaysSatisfiesValidation() {
        let viewModel = makeViewModel(for: .stub(duration: 90))

        #expect(viewModel.isSaveEnabled)
    }

    @Test
    func savePreservesIdentityStorageAndCreationDate() async throws {
        let original = SportPerformance.stub(
            storage: .remote,
            createdAt: Date(timeIntervalSince1970: 4_242)
        )
        let viewModel = makeViewModel(for: original)
        viewModel.name = "  Evening swim "

        let didSave = await viewModel.save()
        let updated = try #require(repository.updatedPerformances.first)

        #expect(didSave)
        #expect(updated.id == original.id)
        #expect(updated.storage == .remote)
        #expect(updated.createdAt == original.createdAt)
        #expect(updated.name == "Evening swim")
    }

    @Test
    func prefillsTheCoordinateFromTheStoredPerformance() {
        let coordinate = PerformanceCoordinate(latitude: 48.7164, longitude: 21.2611)
        let viewModel = makeViewModel(for: .stub(coordinate: coordinate))

        #expect(viewModel.coordinate == coordinate)
    }

    @Test
    func saveCarriesAChangedCoordinate() async throws {
        let viewModel = makeViewModel(
            for: .stub(coordinate: PerformanceCoordinate(latitude: 48.1486, longitude: 17.1077))
        )
        let moved = PerformanceCoordinate(latitude: 48.7164, longitude: 21.2611)
        viewModel.coordinate = moved

        _ = await viewModel.save()
        let updated = try #require(repository.updatedPerformances.first)

        #expect(updated.coordinate == moved)
    }

    @Test
    func clearingTheCoordinateIsPersisted() async throws {
        let viewModel = makeViewModel(
            for: .stub(coordinate: PerformanceCoordinate(latitude: 48.1486, longitude: 17.1077))
        )
        viewModel.coordinate = nil

        _ = await viewModel.save()
        let updated = try #require(repository.updatedPerformances.first)

        #expect(updated.coordinate == nil)
    }

    @Test
    func savingABlankNameIsRejected() async {
        let viewModel = makeViewModel(for: .stub())
        viewModel.name = "   "

        let didSave = await viewModel.save()

        #expect(!didSave)
        #expect(repository.updatedPerformances.isEmpty)
    }

    @Test
    func saveFailureReportsAnError() async {
        let viewModel = makeViewModel(for: .stub())
        repository.writeError = StubSportPerformanceRepository.Failure.write

        let didSave = await viewModel.save()

        #expect(!didSave)
        #expect(viewModel.errorMessage != nil)
    }
}
