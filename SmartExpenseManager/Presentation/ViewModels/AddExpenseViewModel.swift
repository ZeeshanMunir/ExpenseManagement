import Domain
import Foundation

@MainActor
@Observable
final class AddExpenseViewModel: ExpenseFormViewModelProtocol {
    var form = ExpenseFormData()

    private(set) var screenState: FormScreenState = .idle

    private let createExpenseUseCase: any CreateExpenseUseCaseProtocol

    init(createExpenseUseCase: any CreateExpenseUseCaseProtocol) {
        self.createExpenseUseCase = createExpenseUseCase
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
        switch ExpenseFormValidator.makeCreateInput(from: form.domainValues) {
        case .failure(let error):
            screenState = ExpenseFormSaveExecutor.validationErrorState(for: error)
            return .validationFailed
        case .success(let input):
            screenState = .saving
            let (result, newState) = await ExpenseFormSaveExecutor.persist {
                try await createExpenseUseCase.execute(input)
            }
            screenState = newState
            return result
        }
    }
}
