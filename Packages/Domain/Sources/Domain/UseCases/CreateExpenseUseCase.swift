import Foundation

public protocol CreateExpenseUseCaseProtocol: UseCase where Input == CreateExpenseInput, Output == Expense {}
