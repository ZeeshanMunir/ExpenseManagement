import Foundation

enum LoadableViewState: Equatable {
    case loading
    case loaded
    case error(String)
}

struct EmptyStateContent: Equatable {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?

    init(
        title: String,
        message: String,
        systemImage: String,
        actionTitle: String? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
    }
}

enum ExpenseListScreenState: Equatable {
    case loading
    case empty(EmptyStateContent)
    case error(String)
    case content
}

enum FormScreenState: Equatable {
    case idle
    case saving
    case error(String)
}

enum SaveResult: Equatable {
    case success
    case validationFailed
    case failed
}

enum DeleteResult: Equatable {
    case success
    case failed
}
