import Foundation

@MainActor
protocol ExpenseFormViewModelProtocol: AnyObject {
    var form: ExpenseFormData { get set }
    var canSave: Bool { get }
    var isSaving: Bool { get }
    var showError: Bool { get set }
    var errorMessage: String? { get }
    func save() async -> SaveResult
}
