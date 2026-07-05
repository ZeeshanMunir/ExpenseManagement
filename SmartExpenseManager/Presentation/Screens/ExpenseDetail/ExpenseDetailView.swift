import Domain
import SwiftUI

struct ExpenseDetailView: View {
    @State private var viewModel: ExpenseDetailViewModel
    @Environment(\.dismiss) private var dismiss

    let onDeleted: () -> Void
    let onEdit: (Expense) -> Void

    init(
        viewModel: ExpenseDetailViewModel,
        onDeleted: @escaping () -> Void,
        onEdit: @escaping (Expense) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onDeleted = onDeleted
        self.onEdit = onEdit
    }

    var body: some View {
        content
            .loadingOverlay(isPresented: viewModel.isDeleting, message: L10n.deletingExpense)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(viewModel.presentation.expense.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .deleteConfirmation(
                isPresented: $viewModel.showDeleteConfirmation,
                message: L10n.deleteExpenseMessage,
                onConfirm: {
                    Task {
                        if await viewModel.confirmDelete() == .success {
                            onDeleted()
                            dismiss()
                        }
                    }
                }
            )
            .errorAlert(message: $viewModel.errorMessage)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                detailsSection
                if viewModel.presentation.hasNote, let note = viewModel.presentation.note {
                    noteSection(note)
                }
            }
            .padding(20)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CategoryIconView(category: viewModel.presentation.category, size: 52, cornerRadius: 14)

                Spacer()

                AmountBadge(amount: viewModel.presentation.expense.amount, style: .prominent)
            }

            if viewModel.presentation.expense.category != nil {
                CategoryChip(category: viewModel.presentation.category)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var detailsSection: some View {
        VStack(spacing: 0) {
            detailRow(title: L10n.detailDate, value: viewModel.presentation.formattedDate)
            Divider().padding(.leading, 16)
            detailRow(title: L10n.detailCategory, value: viewModel.presentation.categoryName)
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func noteSection(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.detailNote)
                .font(.headline)
            Text(note)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    onEdit(viewModel.presentation.expense)
                } label: {
                    Label(L10n.edit, systemImage: "pencil")
                }

                Button(role: .destructive) {
                    viewModel.requestDelete()
                } label: {
                    Label(L10n.delete, systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .accessibilityLabel(Text("Expense actions"))
            }
        }
    }
}
