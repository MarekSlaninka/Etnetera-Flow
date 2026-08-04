import Foundation
import Testing
@testable import Etnetera_Flow

@MainActor
struct AddPerformanceViewModelTests {
    private let repository = StubSportPerformanceRepository()
    private let viewModel: AddPerformanceViewModel

    init() {
        viewModel = AddPerformanceViewModel(
            saveUseCase: SaveSportPerformanceUseCase(repository: repository)
        )
    }

    private func fillValidForm() {
        viewModel.name = "Morning run"
        viewModel.location = "Bratislava"
    }

    @Test
    func saveIsDisabledOnAnEmptyForm() {
        // Arrange
        let viewModel = viewModel

        // Act
        let isEnabled = viewModel.isSaveEnabled

        // Assert
        #expect(!isEnabled)
    }

    @Test(arguments: ["", "   ", "\n\t"])
    func saveIsDisabledForBlankName(name: String) {
        // Arrange
        fillValidForm()

        // Act
        viewModel.name = name

        // Assert
        #expect(!viewModel.isSaveEnabled)
    }

    @Test(arguments: ["", "   ", "\n\t"])
    func saveIsDisabledForBlankLocation(location: String) {
        // Arrange
        fillValidForm()

        // Act
        viewModel.location = location

        // Assert
        #expect(!viewModel.isSaveEnabled)
    }

    @Test
    func saveIsEnabledOnceBothFieldsHaveContent() {
        // Arrange
        let viewModel = viewModel

        // Act
        fillValidForm()

        // Assert
        #expect(viewModel.isSaveEnabled)
    }

    @Test
    func savingAnInvalidFormDoesNotReachTheRepository() async {
        // Arrange
        let viewModel = viewModel

        // Act
        let didSave = await viewModel.save()

        // Assert
        #expect(!didSave)
        #expect(repository.savedPerformances.isEmpty)
    }

    @Test
    func saveTrimsWhitespace() async throws {
        // Arrange
        viewModel.name = "  Morning run  "
        viewModel.location = "\tBratislava\n"

        // Act
        let didSave = await viewModel.save()

        // Assert
        let saved = try #require(repository.savedPerformances.first)
        #expect(didSave)
        #expect(saved.name == "Morning run")
        #expect(saved.location == "Bratislava")
    }

    @Test
    func saveConvertsMinutesToSeconds() async throws {
        // Arrange
        fillValidForm()
        viewModel.duration = 45

        // Act
        _ = await viewModel.save()

        // Assert
        let saved = try #require(repository.savedPerformances.first)
        #expect(saved.duration == 2_700)
    }

    @Test
    func saveKeepsTheSelectedStorage() async throws {
        // Arrange
        fillValidForm()
        viewModel.storage = .remote

        // Act
        _ = await viewModel.save()

        // Assert
        let saved = try #require(repository.savedPerformances.first)
        #expect(saved.storage == .remote)
    }

    @Test
    func saveCarriesTheSelectedCoordinate() async throws {
        // Arrange
        fillValidForm()
        viewModel.coordinate = PerformanceCoordinate(latitude: 48.1486, longitude: 17.1077)

        // Act
        _ = await viewModel.save()

        // Assert
        let saved = try #require(repository.savedPerformances.first)
        #expect(saved.coordinate?.latitude == 48.1486)
        #expect(saved.coordinate?.longitude == 17.1077)
    }

    @Test
    func savingWithoutAPlaceLeavesTheCoordinateEmpty() async throws {
        // Arrange
        fillValidForm()

        // Act
        _ = await viewModel.save()

        // Assert
        let saved = try #require(repository.savedPerformances.first)
        #expect(saved.coordinate == nil)
    }

    @Test
    func saveFailureReportsAnError() async {
        // Arrange
        fillValidForm()
        repository.writeError = StubSportPerformanceRepository.Failure.write

        // Act
        let didSave = await viewModel.save()

        // Assert
        #expect(!didSave)
        #expect(viewModel.errorMessage != nil)
    }

    @Test
    func dismissingAnErrorClearsTheMessage() async {
        // Arrange
        fillValidForm()
        repository.writeError = StubSportPerformanceRepository.Failure.write
        _ = await viewModel.save()

        // Act
        viewModel.dismissError()

        // Assert
        #expect(viewModel.errorMessage == nil)
    }
}
