import Data
import Domain
import XCTest
@testable import SmartExpenseManager

@MainActor
final class ExpenseListViewModelTests: XCTestCase {
  private var repository: MockExpenseRepository!

  override func setUp() {
    super.setUp()
    repository = MockExpenseRepository()
  }

  override func tearDown() {
    repository = nil
    super.tearDown()
  }

  private func makeViewModel() -> ExpenseListViewModel {
    ExpenseListViewModel(
      fetchExpensesUseCase: FetchExpensesUseCase(repository: repository),
      searchExpensesUseCase: SearchExpensesUseCase(repository: repository),
      deleteExpenseUseCase: DeleteExpenseUseCase(repository: repository),
      syncExpensesUseCase: SyncExpensesUseCase(repository: repository),
      retryFailedSyncUseCase: RetryFailedSyncUseCase(repository: repository)
    )
  }

  func testLoadExpensesSetsContentStateOnSuccess() async {
    repository.expenses = [Expense(title: "Test", amount: 10, date: .now)]
    let viewModel = makeViewModel()

    await viewModel.loadExpenses()

    XCTAssertEqual(viewModel.screenState, .content)
    XCTAssertEqual(viewModel.expenses.count, 1)
  }

  func testLoadExpensesSetsEmptyStateWhenNoData() async {
    let viewModel = makeViewModel()

    await viewModel.loadExpenses()

    guard case .empty(let content) = viewModel.screenState else {
      return XCTFail("Expected empty state")
    }
    XCTAssertEqual(content.title, "No Expenses")
  }

  func testLoadExpensesSetsErrorStateOnFailure() async {
    repository.fetchExpensesError = DomainError.invalidTitle
    let viewModel = makeViewModel()

    await viewModel.loadExpenses()

    guard case .error = viewModel.screenState else {
      return XCTFail("Expected error state")
    }
  }

  func testSearchReturnsFilteredExpenses() async {
    repository.expenses = [
      Expense(title: "Coffee", amount: 5, date: .now),
      Expense(title: "Rent", amount: 900, date: .now),
    ]
    let viewModel = makeViewModel()
    viewModel.searchText = "coffee"

    await viewModel.search()

    XCTAssertEqual(viewModel.expenses.count, 1)
    XCTAssertEqual(viewModel.expenses.first?.title, "Coffee")
    XCTAssertEqual(viewModel.screenState, .content)
  }

  func testSearchWithEmptyQueryReloadsAllExpenses() async {
    repository.expenses = [Expense(title: "All", amount: 1, date: .now)]
    let viewModel = makeViewModel()
    viewModel.searchText = "   "

    await viewModel.search()

    XCTAssertEqual(viewModel.expenses.count, 1)
  }

  func testSearchSetsErrorStateOnFailure() async {
    repository.searchExpensesError = DomainError.syncFailed(message: "Search failed")
    let viewModel = makeViewModel()
    viewModel.searchText = "coffee"

    await viewModel.search()

    guard case .error = viewModel.screenState else {
      return XCTFail("Expected error state")
    }
  }

  func testRefreshSyncsWhenNoFailedItems() async {
    repository.expenses = [Expense(title: "Synced", amount: 1, date: .now, syncStatus: .synced)]
    repository.syncResult = SyncExpensesResult(syncedCount: 0, failedCount: 0)
    let viewModel = makeViewModel()
    await viewModel.loadExpenses()

    await viewModel.refresh()

    XCTAssertEqual(repository.syncExpensesCallCount, 1)
    XCTAssertEqual(repository.retryFailedSyncCallCount, 0)
    XCTAssertFalse(viewModel.isRefreshing)
  }

  func testRefreshRetriesFailedSyncWhenFailedItemsExist() async {
    repository.expenses = [
      Expense(title: "Failed", amount: 1, date: .now, syncStatus: .failed),
    ]
    repository.syncResult = SyncExpensesResult(syncedCount: 1, failedCount: 0)
    let viewModel = makeViewModel()
    await viewModel.loadExpenses()

    await viewModel.refresh()

    XCTAssertEqual(repository.retryFailedSyncCallCount, 1)
    XCTAssertEqual(repository.syncExpensesCallCount, 0)
  }

  func testRetryFailedSyncUpdatesExpenses() async {
    repository.expenses = [
      Expense(title: "Failed", amount: 1, date: .now, syncStatus: .failed),
    ]
    repository.syncResult = SyncExpensesResult(syncedCount: 1, failedCount: 0)
    let viewModel = makeViewModel()
    await viewModel.loadExpenses()

    XCTAssertTrue(viewModel.hasSyncIssues)

    await viewModel.retryFailedSync()

    XCTAssertEqual(repository.retryFailedSyncCallCount, 1)
    XCTAssertEqual(viewModel.screenState, .content)
  }

  func testConfirmDeleteRemovesExpenseFromList() async {
    let expense = Expense(title: "Delete Me", amount: 3, date: .now)
    repository.expenses = [expense]
    let viewModel = makeViewModel()
    await viewModel.loadExpenses()
    viewModel.requestDelete(expense)

    await viewModel.confirmDelete()

    XCTAssertTrue(viewModel.expenses.isEmpty)
    XCTAssertEqual(repository.deletedExpenseIDs, [expense.id])
    guard case .empty = viewModel.screenState else {
      return XCTFail("Expected empty state after delete")
    }
  }

  func testConfirmDeleteSetsErrorOnFailure() async {
    let expense = Expense(title: "Keep", amount: 3, date: .now)
    repository.expenses = [expense]
    repository.deleteExpenseError = DomainError.expenseNotFound(id: expense.id)
    let viewModel = makeViewModel()
    await viewModel.loadExpenses()
    viewModel.requestDelete(expense)

    await viewModel.confirmDelete()

    XCTAssertEqual(viewModel.expenses.count, 1)
    guard case .error = viewModel.screenState else {
      return XCTFail("Expected error state")
    }
  }

  func testSyncCountsReflectPendingAndFailedStatuses() async {
    repository.expenses = [
      Expense(title: "Pending", amount: 1, date: .now, syncStatus: .pending),
      Expense(title: "Failed", amount: 2, date: .now, syncStatus: .failed),
      Expense(title: "Synced", amount: 3, date: .now, syncStatus: .synced),
    ]
    let viewModel = makeViewModel()

    await viewModel.loadExpenses()

    XCTAssertEqual(viewModel.pendingSyncCount, 1)
    XCTAssertEqual(viewModel.failedSyncCount, 1)
    XCTAssertTrue(viewModel.hasSyncIssues)
    XCTAssertEqual(viewModel.syncStatusMessage, "1 expense failed to sync")
  }
}

@MainActor
final class AddExpenseViewModelTests: XCTestCase {
  private var repository: MockExpenseRepository!

  override func setUp() {
    super.setUp()
    repository = MockExpenseRepository()
  }

  override func tearDown() {
    repository = nil
    super.tearDown()
  }

  func testSaveWithInvalidFormReturnsValidationFailed() async {
    let viewModel = AddExpenseViewModel(
      createExpenseUseCase: CreateExpenseUseCase(repository: repository)
    )
    viewModel.form.title = ""

    let result = await viewModel.save()

    XCTAssertEqual(result, .validationFailed)
    XCTAssertTrue(viewModel.errorMessage != nil)
    XCTAssertEqual(repository.createExpenseInputs.count, 0)
  }

  func testSaveWithValidFormReturnsSuccess() async {
    let viewModel = AddExpenseViewModel(
      createExpenseUseCase: CreateExpenseUseCase(repository: repository)
    )
    viewModel.form.title = "Lunch"
    viewModel.form.amountText = "12.50"

    let result = await viewModel.save()

    XCTAssertEqual(result, .success)
    XCTAssertEqual(repository.createExpenseInputs.count, 1)
    XCTAssertEqual(repository.createExpenseInputs.first?.title, "Lunch")
  }

  func testSaveReturnsFailedWhenUseCaseThrows() async {
    repository.createExpenseError = DomainError.syncFailed(message: "Offline")
    let viewModel = AddExpenseViewModel(
      createExpenseUseCase: CreateExpenseUseCase(repository: repository)
    )
    viewModel.form.title = "Dinner"
    viewModel.form.amountText = "20"

    let result = await viewModel.save()

    XCTAssertEqual(result, .failed)
    XCTAssertEqual(viewModel.errorMessage, DomainError.syncFailed(message: "Offline").localizedDescription)
  }
}

@MainActor
final class EditExpenseViewModelTests: XCTestCase {
  private var repository: MockExpenseRepository!

  override func setUp() {
    super.setUp()
    repository = MockExpenseRepository()
  }

  override func tearDown() {
    repository = nil
    super.tearDown()
  }

  func testSaveWithInvalidAmountReturnsValidationFailed() async {
    let expense = Expense(title: "Edit", amount: 10, date: .now)
    let viewModel = EditExpenseViewModel(
      expense: expense,
      updateExpenseUseCase: UpdateExpenseUseCase(repository: repository)
    )
    viewModel.form.amountText = "0"

    let result = await viewModel.save()

    XCTAssertEqual(result, .validationFailed)
    XCTAssertEqual(repository.updateExpenseInputs.count, 0)
  }

  func testSaveWithValidFormReturnsSuccess() async {
    let expense = Expense(title: "Edit", amount: 10, date: .now)
    repository.expenses = [expense]
    let viewModel = EditExpenseViewModel(
      expense: expense,
      updateExpenseUseCase: UpdateExpenseUseCase(repository: repository)
    )
    viewModel.form.title = "Updated Title"
    viewModel.form.amountText = "25"

    let result = await viewModel.save()

    XCTAssertEqual(result, .success)
    XCTAssertEqual(repository.updateExpenseInputs.count, 1)
    XCTAssertEqual(repository.updateExpenseInputs.first?.title, "Updated Title")
  }

  func testSaveReturnsFailedWhenUseCaseThrows() async {
    let expense = Expense(title: "Edit", amount: 10, date: .now)
    repository.updateExpenseError = DomainError.syncFailed(message: "Offline")
    let viewModel = EditExpenseViewModel(
      expense: expense,
      updateExpenseUseCase: UpdateExpenseUseCase(repository: repository)
    )
    viewModel.form.title = "Updated"
    viewModel.form.amountText = "15"

    let result = await viewModel.save()

    XCTAssertEqual(result, .failed)
    XCTAssertNotNil(viewModel.errorMessage)
  }
}

@MainActor
final class ExpenseDetailViewModelTests: XCTestCase {
  private var repository: MockExpenseRepository!

  override func setUp() {
    super.setUp()
    repository = MockExpenseRepository()
  }

  override func tearDown() {
    repository = nil
    super.tearDown()
  }

  func testConfirmDeleteReturnsSuccess() async {
    let expense = Expense(title: "Detail", amount: 8, date: .now)
    repository.expenses = [expense]
    let viewModel = ExpenseDetailViewModel(
      expense: expense,
      deleteExpenseUseCase: DeleteExpenseUseCase(repository: repository)
    )

    let result = await viewModel.confirmDelete()

    XCTAssertEqual(result, .success)
    XCTAssertEqual(repository.deletedExpenseIDs, [expense.id])
    XCTAssertFalse(viewModel.isDeleting)
  }

  func testConfirmDeleteReturnsFailedOnError() async {
    let expense = Expense(title: "Detail", amount: 8, date: .now)
    repository.deleteExpenseError = DomainError.expenseNotFound(id: expense.id)
    let viewModel = ExpenseDetailViewModel(
      expense: expense,
      deleteExpenseUseCase: DeleteExpenseUseCase(repository: repository)
    )

    let result = await viewModel.confirmDelete()

    XCTAssertEqual(result, .failed)
    XCTAssertNotNil(viewModel.errorMessage)
    guard case .error = viewModel.screenState else {
      return XCTFail("Expected error screen state")
    }
  }
}
