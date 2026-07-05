import Core
import Domain
import Foundation

@MainActor
@Observable
final class ExpenseDetailViewModel {
    private(set) var presentation: ExpenseDetailPresentation
    private(set) var screenState: LoadableViewState = .loaded
    var errorMessage: String?

    var showDeleteConfirmation = false

    private let deleteExpenseUseCase: any DeleteExpenseUseCaseProtocol

    init(
        expense: Expense,
        deleteExpenseUseCase: any DeleteExpenseUseCaseProtocol
    ) {
        self.presentation = ExpenseDetailPresentation(expense: expense)
        self.deleteExpenseUseCase = deleteExpenseUseCase
    }

    var isDeleting: Bool {
        screenState == .loading
    }

    var showError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    func requestDelete() {
        showDeleteConfirmation = true
    }

    func confirmDelete() async -> DeleteResult {
        screenState = .loading
        errorMessage = nil

        do {
            try await deleteExpenseUseCase.execute(presentation.expense.id)
            screenState = .loaded
            return .success
        } catch {
            let message = UserErrorMessage.message(for: error)
            errorMessage = message
            screenState = .error(message)
            AppLogger.logError(AppLogger.ui, "Expense delete failed", error: error)
            return .failed
        }
    }
}
