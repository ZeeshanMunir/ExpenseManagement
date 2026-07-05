import Core
import Data
import Domain
import Testing
@testable import SmartExpenseManager

struct AppContainerTests {
    @Test func productionContainerResolvesUseCases() {
        let container = AppContainer(configuration: .testing())
        #expect(container.fetchExpensesUseCase is FetchExpensesUseCase)
        #expect(container.createExpenseUseCase is CreateExpenseUseCase)
        #expect(container.expenseRepository is ExpenseRepository)
        #expect(container.retryFailedSyncUseCase is RetryFailedSyncUseCase)
        #expect(container.syncCoordinator is ExpenseSyncCoordinator)
    }

    @Test func testingConfigurationUsesInjectedMocks() {
        let mockClient = MockAPIClient()
        let container = AppContainer(
            configuration: .testing(apiClient: mockClient)
        )
        #expect(container.apiClient is MockAPIClient)
    }

    @MainActor
    @Test func viewModelFactoryCreatesExpenseListViewModel() {
        let container = AppContainer(configuration: .testing())
        let viewModel = ViewModelFactory.makeExpenseListViewModel(container: container)
        #expect(viewModel.expenses.isEmpty)
    }
}
