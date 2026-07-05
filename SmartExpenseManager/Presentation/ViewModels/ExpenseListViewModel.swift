import Core
import Domain
import Foundation

@MainActor
@Observable
final class ExpenseListViewModel {
    private(set) var expenses: [Expense] = []
    private(set) var screenState: ExpenseListScreenState = .loading
    private(set) var isRefreshing = false
    private(set) var failedSyncCount = 0
    private(set) var pendingSyncCount = 0

    var searchText = "" {
        didSet {
            guard searchText != oldValue else { return }
            Task { [searchDebouncer] in
                await searchDebouncer.schedule { [weak self] in
                    await self?.search()
                }
            }
        }
    }

    var expensePendingDeletion: Expense?
    var showDeleteConfirmation = false

    var hasSyncIssues: Bool {
        failedSyncCount > 0 || pendingSyncCount > 0
    }

    var syncStatusMessage: String? {
        if failedSyncCount > 0 {
            return L10n.syncFailedMessage(count: failedSyncCount)
        }
        if pendingSyncCount > 0 {
            return L10n.syncPendingMessage(count: pendingSyncCount)
        }
        return nil
    }

    private let searchDebouncer = Debouncer(nanoseconds: 300_000_000)

    private let fetchExpensesUseCase: any FetchExpensesUseCaseProtocol
    private let searchExpensesUseCase: any SearchExpensesUseCaseProtocol
    private let deleteExpenseUseCase: any DeleteExpenseUseCaseProtocol
    private let syncExpensesUseCase: any SyncExpensesUseCaseProtocol
    private let retryFailedSyncUseCase: any RetryFailedSyncUseCaseProtocol

    init(
        fetchExpensesUseCase: any FetchExpensesUseCaseProtocol,
        searchExpensesUseCase: any SearchExpensesUseCaseProtocol,
        deleteExpenseUseCase: any DeleteExpenseUseCaseProtocol,
        syncExpensesUseCase: any SyncExpensesUseCaseProtocol,
        retryFailedSyncUseCase: any RetryFailedSyncUseCaseProtocol
    ) {
        self.fetchExpensesUseCase = fetchExpensesUseCase
        self.searchExpensesUseCase = searchExpensesUseCase
        self.deleteExpenseUseCase = deleteExpenseUseCase
        self.syncExpensesUseCase = syncExpensesUseCase
        self.retryFailedSyncUseCase = retryFailedSyncUseCase
    }

    var deleteConfirmationMessage: String {
        guard let expense = expensePendingDeletion else { return "" }
        return L10n.deleteConfirmationMessage(title: expense.title)
    }

    var isShowingContent: Bool {
        screenState == .content
    }

    func onAppear() async {
        await loadExpenses()
    }

    func onDisappear() async {
        await searchDebouncer.cancel()
    }

    func loadExpenses() async {
        updateScreenState(loading: true)

        do {
            expenses = try await fetchExpensesUseCase.execute()
            updateSyncCounts()
            updateScreenState(loading: false)
        } catch {
            handleError(error, clearsExpenses: true)
        }
    }

    func refresh() async {
        isRefreshing = true

        do {
            if failedSyncCount > 0 {
                _ = try await retryFailedSyncUseCase.execute()
            } else {
                _ = try await syncExpensesUseCase.execute()
            }
            expenses = try await fetchExpensesUseCase.execute()
            updateSyncCounts()
            updateScreenState(loading: false)
        } catch {
            if expenses.isEmpty {
                handleError(error, clearsExpenses: false)
            } else {
                logError(error, context: "refresh")
            }
        }

        isRefreshing = false
    }

    func retryFailedSync() async {
        isRefreshing = true

        do {
            _ = try await retryFailedSyncUseCase.execute()
            expenses = try await fetchExpensesUseCase.execute()
            updateSyncCounts()
            updateScreenState(loading: false)
        } catch {
            handleError(error, clearsExpenses: false)
        }

        isRefreshing = false
    }

    func search() async {
        let query = searchText.trimmed

        guard !query.isEmpty else {
            await loadExpenses()
            return
        }

        do {
            expenses = try await searchExpensesUseCase.execute(
                ExpenseSearchCriteria(query: query)
            )
            updateSyncCounts()
            updateScreenState(loading: false)
        } catch {
            handleError(error, clearsExpenses: false)
        }
    }

    func requestDelete(_ expense: Expense) {
        expensePendingDeletion = expense
        showDeleteConfirmation = true
    }

    func confirmDelete() async {
        guard let expense = expensePendingDeletion else { return }
        expensePendingDeletion = nil
        showDeleteConfirmation = false

        do {
            try await deleteExpenseUseCase.execute(expense.id)
            expenses.removeAll { $0.id == expense.id }
            updateSyncCounts()
            updateScreenState(loading: false)
        } catch {
            handleError(error, clearsExpenses: false)
        }
    }

    func cancelDelete() {
        expensePendingDeletion = nil
        showDeleteConfirmation = false
    }

    func retry() async {
        await loadExpenses()
    }

    // MARK: - Private

    private func updateSyncCounts() {
        failedSyncCount = expenses.filter { $0.syncStatus == .failed }.count
        pendingSyncCount = expenses.filter { $0.syncStatus == .pending }.count
    }

    private func updateScreenState(loading: Bool) {
        if loading && expenses.isEmpty {
            screenState = .loading
            return
        }

        if expenses.isEmpty {
            screenState = .empty(makeEmptyStateContent())
            return
        }

        screenState = .content
    }

    private func makeEmptyStateContent() -> EmptyStateContent {
        let isSearching = !searchText.trimmed.isEmpty

        if isSearching {
            return EmptyStateContent(
                title: L10n.noResultsTitle,
                message: L10n.noResultsMessage,
                systemImage: "magnifyingglass"
            )
        }

        return EmptyStateContent(
            title: L10n.noExpensesTitle,
            message: L10n.noExpensesMessage,
            systemImage: "dollarsign.circle",
            actionTitle: L10n.addExpenseAction
        )
    }

    private func handleError(_ error: Error, clearsExpenses: Bool) {
        logError(error, context: "expense list")
        if clearsExpenses {
            expenses = []
        }
        screenState = .error(UserErrorMessage.message(for: error))
    }

    private func logError(_ error: Error, context: String) {
        AppLogger.logError(AppLogger.ui, "Expense list \(context) failed", error: error)
    }
}
