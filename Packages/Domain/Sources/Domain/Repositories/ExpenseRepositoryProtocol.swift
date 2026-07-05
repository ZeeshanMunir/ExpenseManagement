import Foundation

public protocol ExpenseRepositoryProtocol: Sendable {
    func fetchExpenses() async throws -> [Expense]
    func fetchExpense(id: UUID) async throws -> Expense?
    func createExpense(_ input: CreateExpenseInput) async throws -> Expense
    func updateExpense(_ input: UpdateExpenseInput) async throws -> Expense
    func deleteExpense(id: UUID) async throws
    func searchExpenses(criteria: ExpenseSearchCriteria) async throws -> [Expense]
    func syncExpenses() async throws -> SyncExpensesResult
    func retryFailedSync() async throws -> SyncExpensesResult
}
