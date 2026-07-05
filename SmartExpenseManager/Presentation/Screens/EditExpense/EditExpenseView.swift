import SwiftUI

struct EditExpenseView: View {
    @State private var viewModel: EditExpenseViewModel
    let onSaved: () -> Void

    init(viewModel: EditExpenseViewModel, onSaved: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSaved = onSaved
    }

    var body: some View {
        ExpenseFormScreen(
            viewModel: viewModel,
            title: L10n.editExpenseTitle,
            onSaved: onSaved
        )
    }
}
