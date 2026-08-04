import SwiftUI

struct PerformanceListView: View {
    let viewModel: PerformanceListViewModel
    let onAddPerformance: () -> Void
    let onEditPerformance: (SportPerformance) -> Void
    @State private var performancePendingDeletion: SportPerformance?
    @State private var deletionError: Error?
    @State private var isPresentingMap = false
    @State private var performanceToShowOnMap: SportPerformance?

    var body: some View {
        alerts(for: navigationView)
    }

    private var navigationView: some View {
        @Bindable var viewModel = viewModel

        return NavigationStack {
            listContent
                .navigationTitle(Text("list.title"))
                .searchable(
                    text: $viewModel.searchText,
                    prompt: Text("search.prompt")
                )
                .toolbar {
                    toolbar(filter: $viewModel.filter)
                }
        }
        .task {
            viewModel.observePerformances()
        }
        .onDisappear {
            viewModel.stopObserving()
        }
        .sheet(isPresented: $isPresentingMap) {
            PerformanceMapView(performances: viewModel.performances)
        }
        .sheet(item: $performanceToShowOnMap) { performance in
            PerformanceMapView(
                performances: viewModel.performances,
                focused: performance
            )
        }
    }

    @ViewBuilder
    private var listContent: some View {
        if viewModel.isLoading {
            LoadingView()
        } else if viewModel.performances.isEmpty {
            emptyContent
        } else {
            performanceList
        }
    }

    @ViewBuilder
    private var emptyContent: some View {
        if viewModel.isSearching {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else {
            ContentUnavailableView(
                "empty.title",
                systemImage: "figure.run",
                description: Text("empty.description")
            )
        }
    }

    private var performanceList: some View {
        List(viewModel.performances) { performance in
            PerformanceRow(performance: performance)
                .contentShape(.rect)
                .onTapGesture {
                    performanceToShowOnMap = performance
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        onEditPerformance(performance)
                    } label: {
                        Label("action.edit", systemImage: "pencil")
                    }
                    .tint(.blue)

                    Button(role: .destructive) {
                        performancePendingDeletion = performance
                    } label: {
                        Label("action.delete", systemImage: "trash")
                    }
                    .tint(.red)
                }
        }
        .listStyle(.insetGrouped)
    }

    @ToolbarContentBuilder
    private func toolbar(filter: Binding<PerformanceFilter>) -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Picker(selection: filter) {
                ForEach(PerformanceFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            } label: { Text("list.filterAccessibilityLabel") }
            .pickerStyle(.segmented)
            .accessibilityLabel(Text("list.filterAccessibilityLabel"))
        }

        ToolbarItem(placement: .topBarLeading) {
            Button {
                isPresentingMap = true
            } label: {
                Label("map.title", systemImage: "map")
            }
            .accessibilityLabel(Text("map.title"))
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button(action: onAddPerformance) {
                Label("form.save", systemImage: "plus")
            }
            .accessibilityLabel(Text("form.save"))
        }
    }

    private func alerts<Content: View>(for content: Content) -> some View {
        content
            .alert("performance.delete.title", isPresented: Binding(
                get: { performancePendingDeletion != nil },
                set: { if !$0 { performancePendingDeletion = nil } }
            ), presenting: performancePendingDeletion) { performance in
                Button("action.cancel", role: .cancel) { }
                Button("action.delete", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.delete(performance)
                        } catch {
                            deletionError = error
                        }
                    }
                }
            } message: { _ in
                Text("performance.delete.message")
            }
            .alert("performance.delete.failed.title", isPresented: Binding(
                get: { deletionError != nil },
                set: { if !$0 { deletionError = nil } }
            )) {
                Button("alert.failed.confirm", role: .cancel) { deletionError = nil }
            } message: {
                Text(
                    deletionError?.localizedDescription
                        ?? String(localized: "performance.delete.failed.message")
                )
            }
            .alert(isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.dismissError() } }
            )) {
                Alert(
                    title: Text("performance.load.failed.title"),
                    message: Text(
                        viewModel.errorMessage
                            ?? String(localized: "performance.load.failed.message")
                    ),
                    dismissButton: .cancel(
                        Text("alert.failed.confirm"),
                        action: viewModel.dismissError
                    )
                )
            }
    }
}

#Preview("Zoznam výkonov") {
    PerformanceListView(
        viewModel: PerformanceListViewModel(repository: PreviewData.makeRepository()),
        onAddPerformance: { },
        onEditPerformance: { _ in }
    )
}

#Preview("Prázdny zoznam") {
    PerformanceListView(
        viewModel: PerformanceListViewModel(
            repository: PreviewData.makeRepository(performances: [])
        ),
        onAddPerformance: { },
        onEditPerformance: { _ in }
    )
}
