import Foundation

/// Localization keys backed by `Localizable.xcstrings`. Use these instead of hardcoded UI strings.
enum L10n {
    // MARK: - Common

    static let ok = String(localized: "common.ok")
    static let cancel = String(localized: "common.cancel")
    static let save = String(localized: "common.save")
    static let delete = String(localized: "common.delete")
    static let edit = String(localized: "common.edit")
    static let error = String(localized: "common.error")
    static let retry = String(localized: "common.retry")
    static let loading = String(localized: "common.loading")

    // MARK: - Expenses

    static let expensesTitle = String(localized: "expenses.title")
    static let addExpenseTitle = String(localized: "expenses.add_title")
    static let editExpenseTitle = String(localized: "expenses.edit_title")
    static let deleteExpenseTitle = String(localized: "expenses.delete_title")
    static let deleteExpenseMessage = String(localized: "expenses.delete_message")
    static let searchPrompt = String(localized: "expenses.search_prompt")
    static let loadingExpenses = String(localized: "expenses.loading")
    static let savingExpense = String(localized: "expenses.saving")
    static let deletingExpense = String(localized: "expenses.deleting")

    // MARK: - Empty States

    static let noExpensesTitle = String(localized: "empty.no_expenses_title")
    static let noExpensesMessage = String(localized: "empty.no_expenses_message")
    static let addExpenseAction = String(localized: "empty.add_expense_action")
    static let noResultsTitle = String(localized: "empty.no_results_title")
    static let noResultsMessage = String(localized: "empty.no_results_message")

    // MARK: - Errors

    static let somethingWentWrong = String(localized: "error.something_went_wrong")
    static let tryAgain = String(localized: "error.try_again")

    // MARK: - Form

    static let formDetailsSection = String(localized: "form.details_section")
    static let formTitlePlaceholder = String(localized: "form.title_placeholder")
    static let formAmountPlaceholder = String(localized: "form.amount_placeholder")
    static let formDateLabel = String(localized: "form.date_label")
    static let formCategorySection = String(localized: "form.category_section")
    static let formCategoryLabel = String(localized: "form.category_label")
    static let formNoteSection = String(localized: "form.note_section")
    static let formNotePlaceholder = String(localized: "form.note_placeholder")

    // MARK: - Detail

    static let detailDate = String(localized: "detail.date")
    static let detailCategory = String(localized: "detail.category")
    static let detailNote = String(localized: "detail.note")

    // MARK: - Sync

    static let syncStatusSynced = String(localized: "sync.status_synced")
    static let syncStatusPending = String(localized: "sync.status_pending")
    static let syncStatusFailed = String(localized: "sync.status_failed")

    static func deleteConfirmationMessage(title: String) -> String {
        String(format: String(localized: "expenses.delete_confirmation %@"), title)
    }

    static func syncFailedMessage(count: Int) -> String {
        String(localized: "sync.failed_count \(count)")
    }

    static func syncPendingMessage(count: Int) -> String {
        String(localized: "sync.pending_count \(count)")
    }
}
