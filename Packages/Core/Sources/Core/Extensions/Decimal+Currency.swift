import Foundation

public extension Decimal {
    func formattedAsCurrency(code: String = AppConstants.defaultCurrencyCode) -> String {
        (self as NSDecimalNumber).decimalValue.formatted(
            .currency(code: code)
            .precision(.fractionLength(2))
        )
    }
}
