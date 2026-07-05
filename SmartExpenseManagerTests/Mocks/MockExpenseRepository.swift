import Domain
import Foundation

/// Configurable in-memory repository for unit testing use cases and view models.
final class MockExpenseRepository: ExpenseRepositoryProtocol, @unchecked Sendable {
  var expenses: [Expense] = []
  var syncResult = SyncExpensesResult(syncedCount: 0, failedCount: 0)

  var fetchExpensesError: Error?
  var fetchExpenseError: Error?
  var createExpenseError: Error?
  var updateExpenseError: Error?
  var deleteExpenseError: Error?
  var searchExpensesError: Error?
  var syncExpensesError: Error?
  var retryFailedSyncError: Error?

  private(set) var fetchExpensesCallCount = 0
  private(set) var createExpenseInputs: [CreateExpenseInput] = []
  private(set) var updateExpenseInputs: [UpdateExpenseInput] = []
  private(set) var deletedExpenseIDs: [UUID] = []
  private(set) var searchCriteria: [ExpenseSearchCriteria] = []
  private(set) var syncExpensesCallCount = 0
  private(set) var retryFailedSyncCallCount = 0

  func fetchExpenses() async throws -> [Expense] {
    fetchExpensesCallCount += 1
    if let fetchExpensesError { throw fetchExpensesError }
    return expenses
  }

  func fetchExpense(id: UUID) async throws -> Expense? {
    if let fetchExpenseError { throw fetchExpenseError }
    return expenses.first { $0.id == id }
  }

  func createExpense(_ input: CreateExpenseInput) async throws -> Expense {
    if let createExpenseError { throw createExpenseError }
    createExpenseInputs.append(input)
    let expense = Expense(
      title: input.title,
      amount: input.amount,
      date: input.date,
      category: input.category,
      note: input.note,
      syncStatus: .pending
    )
    expenses.append(expense)
    return expense
  }

  func updateExpense(_ input: UpdateExpenseInput) async throws -> Expense {
    if let updateExpenseError { throw updateExpenseError }
    updateExpenseInputs.append(input)
    guard let index = expenses.firstIndex(where: { $0.id == input.id }) else {
      throw DomainError.expenseNotFound(id: input.id)
    }
    let updated = Expense(
      id: input.id,
      title: input.title,
      amount: input.amount,
      date: input.date,
      category: input.category,
      note: input.note,
      syncStatus: .pending
    )
    expenses[index] = updated
    return updated
  }

  func deleteExpense(id: UUID) async throws {
    if let deleteExpenseError { throw deleteExpenseError }
    deletedExpenseIDs.append(id)
    expenses.removeAll { $0.id == id }
  }

  func searchExpenses(criteria: ExpenseSearchCriteria) async throws -> [Expense] {
    searchCriteria.append(criteria)
    if let searchExpensesError { throw searchExpensesError }
    guard !criteria.query.isEmpty else { return expenses }
    return expenses.filter {
      $0.title.localizedCaseInsensitiveContains(criteria.query)
        || ($0.note?.localizedCaseInsensitiveContains(criteria.query) ?? false)
    }
  }

  func syncExpenses() async throws -> SyncExpensesResult {
    syncExpensesCallCount += 1
    if let syncExpensesError { throw syncExpensesError }
    return syncResult
  }

  func retryFailedSync() async throws -> SyncExpensesResult {
    retryFailedSyncCallCount += 1
    if let retryFailedSyncError { throw retryFailedSyncError }
    return syncResult
  }
}
