import Foundation

public extension Decimal {
    /// Parses a user-entered amount string, accepting comma or dot decimal separators.
    static func parsed(from text: String) -> Decimal? {
        let normalized = text.trimmed.replacingOccurrences(of: ",", with: ".")
        guard !normalized.isEmpty else { return nil }
        return Decimal(string: normalized)
    }

    /// Plain numeric string suitable for amount text fields.
    var expenseInputString: String {
        (self as NSDecimalNumber).stringValue
    }
}
