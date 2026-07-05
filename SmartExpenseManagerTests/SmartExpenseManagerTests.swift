import Domain
import Foundation
import Testing

struct SmartExpenseManagerTests {
    @Test func expenseEntityInitializesWithDefaults() {
        let expense = Expense(title: "Test", amount: 10, date: .now)
        #expect(expense.title == "Test")
        #expect(expense.amount == 10)
    }
}
