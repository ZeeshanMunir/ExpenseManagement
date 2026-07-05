import SwiftUI

struct AddExpenseView: View {
    @State private var viewModel: AddExpenseViewModel
    let onSaved: () -> Void

    init(viewModel: AddExpenseViewModel, onSaved: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSaved = onSaved
    }

    var body: some View {
        ExpenseFormScreen(
            viewModel: viewModel,
            title: L10n.addExpenseTitle,
            onSaved: onSaved
        )
    }
}
