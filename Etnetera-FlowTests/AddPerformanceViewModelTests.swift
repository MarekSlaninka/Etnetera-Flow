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
        #expect(!viewModel.isSaveEnabled)
    }

    @Test(arguments: ["", "   ", "\n\t"])
    func saveIsDisabledForBlankName(name: String) {
        fillValidForm()
        viewModel.name = name

        #expect(!viewModel.isSaveEnabled)
    }

    @Test(arguments: ["", "   ", "\n\t"])
    func saveIsDisabledForBlankLocation(location: String) {
        fillValidForm()
        viewModel.location = location

        #expect(!viewModel.isSaveEnabled)
    }

    @Test
    func saveIsEnabledOnceBothFieldsHaveContent() {
        fillValidForm()

        #expect(viewModel.isSaveEnabled)
    }

    @Test
    func savingAnInvalidFormDoesNotReachTheRepository() async {
        let didSave = await viewModel.save()

        #expect(!didSave)
        #expect(repository.savedPerformances.isEmpty)
    }

    @Test
    func saveTrimsWhitespace() async throws {
        viewModel.name = "  Morning run  "
        viewModel.location = "\tBratislava\n"

        let didSave = await viewModel.save()
        let saved = try #require(repository.savedPerformances.first)

        #expect(didSave)
        #expect(saved.name == "Morning run")
        #expect(saved.location == "Bratislava")
    }

    @Test
    func saveConvertsMinutesToSeconds() async throws {
        fillValidForm()
        viewModel.duration = 45

        _ = await viewModel.save()
        let saved = try #require(repository.savedPerformances.first)

        #expect(saved.duration == 2_700)
    }

    @Test
    func saveKeepsTheSelectedStorage() async throws {
        fillValidForm()
        viewModel.storage = .remote

        _ = await viewModel.save()
        let saved = try #require(repository.savedPerformances.first)

        #expect(saved.storage == .remote)
    }

    @Test
    func saveFailureReportsAnErrorAndDoesNotDismiss() async {
        fillValidForm()
        repository.writeError = StubSportPerformanceRepository.Failure.write

        let didSave = await viewModel.save()

        #expect(!didSave)
        #expect(viewModel.errorMessage != nil)

        viewModel.dismissError()

        #expect(viewModel.errorMessage == nil)
    }
}
