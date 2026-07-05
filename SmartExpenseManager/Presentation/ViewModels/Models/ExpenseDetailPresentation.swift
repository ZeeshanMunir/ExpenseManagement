import Core
import Domain
import Foundation

struct ExpenseDetailPresentation: Equatable {
    let expense: Expense
    let formattedDate: String
    let categoryName: String
    let category: ExpenseCategory
    let note: String?
    let hasNote: Bool

    init(expense: Expense) {
        self.expense = expense
        self.formattedDate = expense.date.formatted(as: "EEEE, MMM d, yyyy")
        let resolvedCategory = expense.category ?? .other
        self.category = resolvedCategory
        self.categoryName = resolvedCategory.displayName
        self.note = expense.note
        self.hasNote = !(expense.note?.isEmpty ?? true)
    }
}
