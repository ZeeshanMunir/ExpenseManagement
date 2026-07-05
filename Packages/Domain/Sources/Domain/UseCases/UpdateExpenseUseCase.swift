import Foundation

public protocol UpdateExpenseUseCaseProtocol: UseCase where Input == UpdateExpenseInput, Output == Expense {}
