import Foundation

public protocol SearchExpensesUseCaseProtocol: UseCase where Input == ExpenseSearchCriteria, Output == [Expense] {}
