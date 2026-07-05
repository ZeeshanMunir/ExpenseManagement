import Domain
import SwiftUI

struct ExpenseListView: View {
    @State private var viewModel: ExpenseListViewModel
    @State private var showAddExpense = false
    @State private var expenseToEdit: Expense?

    private let makeAddExpenseViewModel: () -> AddExpenseViewModel
    private let makeEditExpenseViewModel: (Expense) -> EditExpenseViewModel

    init(
        viewModel: ExpenseListViewModel,
        makeAddExpenseViewModel: @escaping () -> AddExpenseViewModel,
        makeEditExpenseViewModel: @escaping (Expense) -> EditExpenseViewModel
    ) {
        _viewModel = State(initialValue: viewModel)
        self.makeAddExpenseViewModel = makeAddExpenseViewModel
        self.makeEditExpenseViewModel = makeEditExpenseViewModel
    }

    var body: some View {
        content
            .navigationTitle(L10n.expensesTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: L10n.searchPrompt
            )
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showAddExpense) {
                NavigationStack {
                    AddExpenseView(
                        viewModel: makeAddExpenseViewModel(),
                        onSaved: {
                            showAddExpense = false
                            Task { await viewModel.loadExpenses() }
                        }
                    )
                }
            }
            .sheet(item: $expenseToEdit) { expense in
                NavigationStack {
                    EditExpenseView(
                        viewModel: makeEditExpenseViewModel(expense),
                        onSaved: {
                            expenseToEdit = nil
                            Task { await viewModel.loadExpenses() }
                        }
                    )
                }
            }
            .deleteConfirmation(
                isPresented: $viewModel.showDeleteConfirmation,
                message: viewModel.deleteConfirmationMessage,
                onConfirm: {
                    Task { await viewModel.confirmDelete() }
                },
                onCancel: {
                    viewModel.cancelDelete()
                }
            )
            .task {
                await viewModel.onAppear()
            }
            .onDisappear {
                Task { await viewModel.onDisappear() }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.screenState {
        case .loading:
            LoadingView(message: L10n.loadingExpenses)

        case .error(let message):
            ErrorView(message: message) {
                Task { await viewModel.retry() }
            }

        case .empty(let emptyContent):
            EmptyStateView(
                title: emptyContent.title,
                message: emptyContent.message,
                systemImage: emptyContent.systemImage,
                actionTitle: emptyContent.actionTitle,
                action: emptyContent.actionTitle == nil ? nil : { showAddExpense = true }
            )

        case .content:
            VStack(spacing: 0) {
                if viewModel.hasSyncIssues, let message = viewModel.syncStatusMessage {
                    syncStatusBanner(message: message)
                }
                expenseList
            }
        }
    }

    private func syncStatusBanner(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.failedSyncCount > 0 ? "exclamationmark.icloud" : "arrow.triangle.2.circlepath")
                .foregroundStyle(viewModel.failedSyncCount > 0 ? .red : .orange)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            if viewModel.failedSyncCount > 0 {
                Button(L10n.retry) {
                    Task { await viewModel.retryFailedSync() }
                }
                .font(.subheadline.weight(.semibold))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var expenseList: some View {
        List {
            ForEach(viewModel.expenses) { expense in
                NavigationLink(value: AppRoute.detail(expense)) {
                    ExpenseRow(expense: expense)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.requestDelete(expense)
                    } label: {
                        Label(L10n.delete, systemImage: "trash")
                    }

                    Button {
                        expenseToEdit = expense
                    } label: {
                        Label(L10n.edit, systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showAddExpense = true
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel(L10n.addExpenseAction)
        }
    }
}

#Preview {
    NavigationStack {
        ExpenseListView(
            viewModel: ExpenseListViewModel(
                fetchExpensesUseCase: PreviewFetchUseCase(),
                searchExpensesUseCase: PreviewSearchUseCase(),
                deleteExpenseUseCase: PreviewDeleteUseCase(),
                syncExpensesUseCase: PreviewSyncUseCase(),
                retryFailedSyncUseCase: PreviewSyncUseCase()
            ),
            makeAddExpenseViewModel: { AddExpenseViewModel(createExpenseUseCase: PreviewCreateUseCase()) },
            makeEditExpenseViewModel: { expense in
                EditExpenseViewModel(expense: expense, updateExpenseUseCase: PreviewUpdateUseCase())
            }
        )
    }
    .environment(\.appContainer, AppContainer(configuration: .testing()))
}

private struct PreviewFetchUseCase: FetchExpensesUseCaseProtocol {
    func execute() async throws -> [Expense] {
        [Expense(title: "Coffee", amount: 4.5, date: .now, category: .food)]
    }
}

private struct PreviewSearchUseCase: SearchExpensesUseCaseProtocol {
    func execute(_ input: ExpenseSearchCriteria) async throws -> [Expense] { [] }
}

private struct PreviewDeleteUseCase: DeleteExpenseUseCaseProtocol {
    func execute(_ input: UUID) async throws {}
}

private struct PreviewSyncUseCase: SyncExpensesUseCaseProtocol, RetryFailedSyncUseCaseProtocol {
    func execute() async throws -> SyncExpensesResult { SyncExpensesResult(syncedCount: 0, failedCount: 0) }
}

private struct PreviewCreateUseCase: CreateExpenseUseCaseProtocol {
    func execute(_ input: CreateExpenseInput) async throws -> Expense {
        Expense(title: input.title, amount: input.amount, date: input.date, category: input.category)
    }
}

private struct PreviewUpdateUseCase: UpdateExpenseUseCaseProtocol {
    func execute(_ input: UpdateExpenseInput) async throws -> Expense {
        Expense(id: input.id, title: input.title, amount: input.amount, date: input.date, category: input.category)
    }
}
