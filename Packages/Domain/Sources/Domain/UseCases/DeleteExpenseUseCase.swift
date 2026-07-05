import Foundation

public protocol DeleteExpenseUseCaseProtocol: UseCase where Input == UUID, Output == Void {}
