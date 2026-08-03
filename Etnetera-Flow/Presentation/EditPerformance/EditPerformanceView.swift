import SwiftUI

struct EditPerformanceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EditPerformanceViewModel
    let onSaved: () -> Void

    init(
        performance: SportPerformance,
        updateUseCase: UpdateSportPerformanceUseCase,
        onSaved: @escaping () -> Void
    ) {
        _viewModel = State(
            initialValue: EditPerformanceViewModel(
                performance: performance,
                updateUseCase: updateUseCase
            )
        )
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
                        Text(
                            String(
                                format: String(localized: "form.durationMinutes"),
                                viewModel.duration
                            )
                        )
                    }
                } header: { Text("form.duration") }

                Section {
                    Button {
                        Task {
                            if await viewModel.save() {
                                onSaved()
                            }
                        }
                    } label: { Text("action.saveChanges") }
                    .frame(maxWidth: .infinity)
                    .disabled(!viewModel.isSaveEnabled)
                }
            }
            .navigationTitle(Text("performance.edit.title"))
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
                    dismissButton: .cancel(
                        Text("alert.failed.confirm"),
                        action: viewModel.dismissError
                    )
                )
            }
        }
    }
}
