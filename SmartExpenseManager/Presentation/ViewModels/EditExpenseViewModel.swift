import Domain
import Foundation

@MainActor
@Observable
final class EditExpenseViewModel: ExpenseFormViewModelProtocol {
    var form: ExpenseFormData

    private(set) var screenState: FormScreenState = .idle

    private let expenseID: UUID
    private let updateExpenseUseCase: any UpdateExpenseUseCaseProtocol

    init(
        expense: Expense,
        updateExpenseUseCase: any UpdateExpenseUseCaseProtocol
    ) {
        self.expenseID = expense.id
        self.form = ExpenseFormData(expense: expense)
        self.updateExpenseUseCase = updateExpenseUseCase
    }

    var canSave: Bool {
        form.isValid && !screenState.isSaving
    }

    var isSaving: Bool {
        screenState.isSaving
    }

    var errorMessage: String? {
        screenState.errorMessage
    }

    var showError: Bool {
        get { screenState.showError }
        set {
            if !newValue, case .error = screenState {
                screenState = .idle
            }
        }
    }

    func save() async -> SaveResult {
        switch ExpenseFormValidator.makeUpdateInput(id: expenseID, from: form.domainValues) {
        case .failure(let error):
            screenState = ExpenseFormSaveExecutor.validationErrorState(for: error)
            return .validationFailed
        case .success(let input):
            screenState = .saving
            let (result, newState) = await ExpenseFormSaveExecutor.persist {
                try await updateExpenseUseCase.execute(input)
            }
            screenState = newState
            return result
        }
    }
}
