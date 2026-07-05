import Core
import Foundation

enum ExpenseEndpoint: Endpoint {
    case fetchAll
    case create(ExpenseDTO)
    case update(ExpenseDTO)
    case delete(id: UUID)

    var path: String {
        switch self {
        case .fetchAll, .create:
            return "/expenses"
        case .update(let dto):
            return "/expenses/\(dto.id.uuidString)"
        case .delete(let id):
            return "/expenses/\(id.uuidString)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchAll:
            return .get
        case .create:
            return .post
        case .update:
            return .put
        case .delete:
            return .delete
        }
    }

    var body: Data? {
        switch self {
        case .fetchAll, .delete:
            return nil
        case .create(let dto), .update(let dto):
            return try? JSONCoding.makeEncoder().encode(dto)
        }
    }
}
