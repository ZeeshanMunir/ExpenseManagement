import Domain
import Foundation

@MainActor
enum ViewModelFactory {
    static func makeExpenseListViewModel(container: AppContainer) -> ExpenseListViewModel {
        ExpenseListViewModel(
            fetchExpensesUseCase: container.fetchExpensesUseCase,
            searchExpensesUseCase: container.searchExpensesUseCase,
            deleteExpenseUseCase: container.deleteExpenseUseCase,
            syncExpensesUseCase: container.syncExpensesUseCase,
            retryFailedSyncUseCase: container.retryFailedSyncUseCase
        )
    }

    static func makeExpenseDetailViewModel(
        container: AppContainer,
        expense: Expense
    ) -> ExpenseDetailViewModel {
        ExpenseDetailViewModel(
            expense: expense,
            deleteExpenseUseCase: container.deleteExpenseUseCase
        )
    }

    static func makeAddExpenseViewModel(container: AppContainer) -> AddExpenseViewModel {
        AddExpenseViewModel(createExpenseUseCase: container.createExpenseUseCase)
    }

    static func makeEditExpenseViewModel(
        container: AppContainer,
        expense: Expense
    ) -> EditExpenseViewModel {
        EditExpenseViewModel(
            expense: expense,
            updateExpenseUseCase: container.updateExpenseUseCase
        )
    }
}
