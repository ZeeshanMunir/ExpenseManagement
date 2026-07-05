import Foundation

/// Maps errors to user-facing copy. Keeps presentation layers free of ad-hoc `localizedDescription` usage.
public enum UserErrorMessage {
    public static func message(for error: Error) -> String {
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription,
           !description.isEmpty {
            return description
        }
        return error.localizedDescription
    }
}
