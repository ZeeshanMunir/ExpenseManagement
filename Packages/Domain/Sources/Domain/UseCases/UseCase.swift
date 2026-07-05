import Foundation

public protocol UseCase: Sendable {
    associatedtype Input
    associatedtype Output

    func execute(_ input: Input) async throws -> Output
}

public protocol NoInputUseCase: Sendable {
    associatedtype Output

    func execute() async throws -> Output
}
