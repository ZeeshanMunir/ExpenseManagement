import Core
import Domain
import Foundation

extension FormScreenState {
    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }

    var isSaving: Bool {
        self == .saving
    }

    var showError: Bool {
        errorMessage != nil
    }
}

/// Shared save/validation flow for expense form view models.
enum ExpenseFormSaveExecutor {
    @MainActor
    static func validationErrorState(for error: DomainError) -> FormScreenState {
        AppLogger.logError(AppLogger.ui, "Expense form validation failed", error: error)
        return .error(error.errorDescription ?? UserErrorMessage.message(for: error))
    }

    @MainActor
    static func persist(_ operation: () async throws -> Void) async -> (SaveResult, FormScreenState) {
        do {
            try await operation()
            return (.success, .idle)
        } catch {
            AppLogger.logError(AppLogger.ui, "Expense form save failed", error: error)
            return (.failed, .error(UserErrorMessage.message(for: error)))
        }
    }
}
