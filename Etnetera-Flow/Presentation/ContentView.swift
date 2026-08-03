import SwiftUI

struct ContentView: View {
    private let repository: SportPerformanceRepository
    @State private var listViewModel: PerformanceListViewModel
    @State private var isPresentingAddPerformance = false
    @State private var performanceBeingEdited: SportPerformance?

    init(repository: SportPerformanceRepository) {
        self.repository = repository
        _listViewModel = State(initialValue: PerformanceListViewModel(repository: repository))
    }

    var body: some View {
        PerformanceListView(viewModel: listViewModel) {
            isPresentingAddPerformance = true
        } onEditPerformance: { performance in
            performanceBeingEdited = performance
        }
        .tint(.mint)
        .sheet(isPresented: $isPresentingAddPerformance) {
            AddPerformanceView(
                saveUseCase: SaveSportPerformanceUseCase(repository: repository),
                onSaved: { isPresentingAddPerformance = false }
            )
        }
        .sheet(item: $performanceBeingEdited) { performance in
            EditPerformanceView(
                performance: performance,
                updateUseCase: UpdateSportPerformanceUseCase(repository: repository),
                onSaved: { performanceBeingEdited = nil }
            )
        }
    }
}

#Preview("Aplikácia") {
    ContentView(repository: PreviewData.makeRepository())
}
