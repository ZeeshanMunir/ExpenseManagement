import SwiftUI

/// Shared add/edit expense screen. Eliminates duplicate layout, toolbar, and alert wiring.
struct ExpenseFormScreen<ViewModel>: View where ViewModel: ExpenseFormViewModelProtocol & Observable {
    @Bindable var viewModel: ViewModel
    @Environment(\.dismiss) private var dismiss

    let title: String
    let onSaved: () -> Void

    var body: some View {
        ExpenseFormView(form: $viewModel.form)
            .loadingOverlay(isPresented: viewModel.isSaving, message: L10n.savingExpense)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .errorAlert(message: errorMessageBinding)
    }

    private var errorMessageBinding: Binding<String?> {
        Binding(
            get: { viewModel.errorMessage },
            set: { newValue in
                if newValue == nil {
                    viewModel.showError = false
                }
            }
        )
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(L10n.cancel) { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button(L10n.save) {
                Task {
                    if await viewModel.save() == .success {
                        onSaved()
                        dismiss()
                    }
                }
            }
            .disabled(!viewModel.canSave)
            .fontWeight(.semibold)
            .accessibilityHint(Text("Saves the expense"))
        }
    }
}
