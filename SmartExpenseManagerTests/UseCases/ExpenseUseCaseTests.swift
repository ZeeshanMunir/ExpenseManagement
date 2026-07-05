import Data
import Domain
import XCTest

final class ExpenseUseCaseTests: XCTestCase {
  private var repository: MockExpenseRepository!

  override func setUp() {
    super.setUp()
    repository = MockExpenseRepository()
  }

  override func tearDown() {
    repository = nil
    super.tearDown()
  }

  // MARK: - Fetch

  func testFetchExpensesUseCaseReturnsExpensesOnSuccess() async throws {
    repository.expenses = [
      Expense(title: "Coffee", amount: 4.5, date: .now),
      Expense(title: "Lunch", amount: 12, date: .now),
    ]

    let useCase = FetchExpensesUseCase(repository: repository)
    let result = try await useCase.execute()

    XCTAssertEqual(result.count, 2)
    XCTAssertEqual(repository.fetchExpensesCallCount, 1)
  }

  func testFetchExpensesUseCaseThrowsOnFailure() async {
    repository.fetchExpensesError = DomainError.syncFailed(message: "Offline")

    let useCase = FetchExpensesUseCase(repository: repository)

    do {
      _ = try await useCase.execute()
      XCTFail("Expected fetch to throw")
    } catch {
      XCTAssertEqual(error as? DomainError, .syncFailed(message: "Offline"))
    }
  }

  // MARK: - Create

  func testCreateExpenseUseCaseCreatesExpenseOnSuccess() async throws {
    let useCase = CreateExpenseUseCase(repository: repository)
    let input = CreateExpenseInput(title: "Taxi", amount: 18, date: .now)

    let expense = try await useCase.execute(input)

    XCTAssertEqual(expense.title, "Taxi")
    XCTAssertEqual(expense.syncStatus, .pending)
    XCTAssertEqual(repository.createExpenseInputs.count, 1)
    XCTAssertEqual(repository.expenses.count, 1)
  }

  func testCreateExpenseUseCaseThrowsOnFailure() async {
    repository.createExpenseError = DomainError.invalidTitle
    let useCase = CreateExpenseUseCase(repository: repository)

    do {
      _ = try await useCase.execute(CreateExpenseInput(title: "", amount: 1, date: .now))
      XCTFail("Expected create to throw")
    } catch {
      XCTAssertEqual(error as? DomainError, .invalidTitle)
    }
  }

  // MARK: - Update

  func testUpdateExpenseUseCaseUpdatesExpenseOnSuccess() async throws {
    let existing = Expense(title: "Old", amount: 5, date: .now)
    repository.expenses = [existing]

    let useCase = UpdateExpenseUseCase(repository: repository)
    let input = UpdateExpenseInput(
      id: existing.id,
      title: "Updated",
      amount: 7.5,
      date: existing.date
    )

    let expense = try await useCase.execute(input)

    XCTAssertEqual(expense.title, "Updated")
    XCTAssertEqual(expense.amount, 7.5)
    XCTAssertEqual(repository.updateExpenseInputs.count, 1)
  }

  func testUpdateExpenseUseCaseThrowsWhenExpenseNotFound() async {
    let useCase = UpdateExpenseUseCase(repository: repository)
    let missingID = UUID()
    let input = UpdateExpenseInput(id: missingID, title: "Missing", amount: 1, date: .now)

    do {
      _ = try await useCase.execute(input)
      XCTFail("Expected update to throw")
    } catch {
      XCTAssertEqual(error as? DomainError, .expenseNotFound(id: missingID))
    }
  }

  // MARK: - Delete

  func testDeleteExpenseUseCaseDeletesOnSuccess() async throws {
    let expense = Expense(title: "Remove Me", amount: 3, date: .now)
    repository.expenses = [expense]

    let useCase = DeleteExpenseUseCase(repository: repository)
    try await useCase.execute(expense.id)

    XCTAssertEqual(repository.deletedExpenseIDs, [expense.id])
    XCTAssertTrue(repository.expenses.isEmpty)
  }

  func testDeleteExpenseUseCaseThrowsOnFailure() async {
    let expense = Expense(title: "Keep", amount: 3, date: .now)
    repository.expenses = [expense]
    repository.deleteExpenseError = DomainError.syncFailed(message: "Cannot delete offline")

    let useCase = DeleteExpenseUseCase(repository: repository)

    do {
      try await useCase.execute(expense.id)
      XCTFail("Expected delete to throw")
    } catch {
      XCTAssertEqual(error as? DomainError, .syncFailed(message: "Cannot delete offline"))
    }
  }

  // MARK: - Search

  func testSearchExpensesUseCaseReturnsMatchingExpenses() async throws {
    repository.expenses = [
      Expense(title: "Coffee Shop", amount: 5, date: .now),
      Expense(title: "Groceries", amount: 40, date: .now),
    ]

    let useCase = SearchExpensesUseCase(repository: repository)
    let results = try await useCase.execute(ExpenseSearchCriteria(query: "coffee"))

    XCTAssertEqual(results.count, 1)
    XCTAssertEqual(results.first?.title, "Coffee Shop")
    XCTAssertEqual(repository.searchCriteria.count, 1)
  }

  func testSearchExpensesUseCaseThrowsOnFailure() async {
    repository.searchExpensesError = DomainError.syncFailed(message: "Search unavailable")

    let useCase = SearchExpensesUseCase(repository: repository)

    do {
      _ = try await useCase.execute(ExpenseSearchCriteria(query: "test"))
      XCTFail("Expected search to throw")
    } catch {
      XCTAssertEqual(error as? DomainError, .syncFailed(message: "Search unavailable"))
    }
  }

  // MARK: - Sync

  func testSyncExpensesUseCaseReturnsSyncResultOnSuccess() async throws {
    repository.syncResult = SyncExpensesResult(syncedCount: 2, failedCount: 0)

    let useCase = SyncExpensesUseCase(repository: repository)
    let result = try await useCase.execute()

    XCTAssertEqual(result.syncedCount, 2)
    XCTAssertEqual(result.failedCount, 0)
    XCTAssertEqual(repository.syncExpensesCallCount, 1)
  }

  func testSyncExpensesUseCaseThrowsWhenOffline() async {
    repository.syncExpensesError = DomainError.syncFailed(message: "No network connection available.")

    let useCase = SyncExpensesUseCase(repository: repository)

    do {
      _ = try await useCase.execute()
      XCTFail("Expected sync to throw")
    } catch {
      XCTAssertEqual(error as? DomainError, .syncFailed(message: "No network connection available."))
    }
  }

  func testRetryFailedSyncUseCaseReturnsSyncResultOnSuccess() async throws {
    repository.syncResult = SyncExpensesResult(syncedCount: 1, failedCount: 0)

    let useCase = RetryFailedSyncUseCase(repository: repository)
    let result = try await useCase.execute()

    XCTAssertEqual(result.syncedCount, 1)
    XCTAssertEqual(repository.retryFailedSyncCallCount, 1)
  }

  func testRetryFailedSyncUseCaseThrowsOnFailure() async {
    repository.retryFailedSyncError = DomainError.syncFailed(message: "Retry failed")

    let useCase = RetryFailedSyncUseCase(repository: repository)

    do {
      _ = try await useCase.execute()
      XCTFail("Expected retry to throw")
    } catch {
      XCTAssertEqual(error as? DomainError, .syncFailed(message: "Retry failed"))
    }
  }
}
