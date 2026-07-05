import Domain
import Foundation

enum AppRoute: Hashable {
    case expenseList
    case detail(Expense)
    case addExpense
    case editExpense(Expense)
}
