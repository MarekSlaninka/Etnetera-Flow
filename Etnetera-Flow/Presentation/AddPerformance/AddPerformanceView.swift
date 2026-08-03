import SwiftUI

struct AddPerformanceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddPerformanceViewModel
    let onSaved: () -> Void

    init(
        saveUseCase: SaveSportPerformanceUseCase,
        onSaved: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: AddPerformanceViewModel(saveUseCase: saveUseCase))
        self.onSaved = onSaved
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                Section {
                    TextField(text: $viewModel.name, prompt: Text("form.name")) {
                        Text("form.name")
                    }
                        .textInputAutocapitalization(.sentences)
                    TextField(text: $viewModel.location, prompt: Text("form.location")) {
                        Text("form.location")
                    }
                        .textInputAutocapitalization(.words)
                } header: { Text("form.details") }

                Section {
                    Stepper(value: $viewModel.duration, in: 5...720, step: 5) {
                        Text(String(format: String(localized: "form.durationMinutes"), viewModel.duration))
                    }
                } header: { Text("form.duration") }

                Section {
                    Picker(selection: $viewModel.storage) {
                        ForEach(StorageType.allCases) { storage in
                            Text(storage.title).tag(storage)
                        }
                    } label: { Text("form.saveTo") }
                    .pickerStyle(.segmented)

                    Text(viewModel.storage == .local
                         ? String(localized: "form.localDescription")
                         : String(localized: "form.firebaseDescription"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: { Text("form.storage") }

                Section {
                    Button {
                        Task {
                            if await viewModel.save() {
                                onSaved()
                            }
                        }
                    } label: { Text("form.save") }
                    .frame(maxWidth: .infinity)
                    .disabled(!viewModel.isSaveEnabled)
                }
            }
            .navigationTitle(Text("tab.addPerformance"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: dismiss.callAsFunction) {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(Text("action.close"))
                }
            }
            .alert(isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.dismissError() } }
            )) {
                Alert(
                    title: Text("alert.failed.title"),
                    message: Text(viewModel.errorMessage ?? String(localized: "alert.failed.message")),
                    dismissButton: .cancel(Text("alert.failed.confirm"), action: viewModel.dismissError)
                )
            }
        }
    }

}

#Preview("Nový výkon") {
    AddPerformanceView(
        saveUseCase: SaveSportPerformanceUseCase(
            repository: PreviewData.makeRepository()
        ),
        onSaved: { }
    )
}
