import Core
import Core
import Domain
import Foundation

struct ExpenseFormData: Equatable {
    var title: String = ""
    var amountText: String = ""
    var date: Date = .now
    var category: ExpenseCategory = .other
    var note: String = ""

    init() {}

    init(expense: Expense) {
        title = expense.title
        amountText = expense.amount.expenseInputString
        date = expense.date
        category = expense.category ?? .other
        note = expense.note ?? ""
    }

    var domainValues: ExpenseFormValues {
        ExpenseFormValues(
            title: title,
            amountText: amountText,
            date: date,
            category: category,
            note: note
        )
    }

    var isValid: Bool {
        ExpenseFormValidator.isValid(title: title, amountText: amountText)
    }
}
