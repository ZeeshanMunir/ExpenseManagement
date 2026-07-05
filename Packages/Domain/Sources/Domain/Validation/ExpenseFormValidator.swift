import Foundation

public struct ExpenseFormValues: Equatable, Sendable {
    public let title: String
    public let amountText: String
    public let date: Date
    public let category: ExpenseCategory?
    public let note: String

    public init(
        title: String,
        amountText: String,
        date: Date,
        category: ExpenseCategory? = nil,
        note: String = ""
    ) {
        self.title = title
        self.amountText = amountText
        self.date = date
        self.category = category
        self.note = note
    }
}

/// Validates expense form input and builds domain DTOs. Single source of truth for form business rules.
public enum ExpenseFormValidator {
    public static func isValid(title: String, amountText: String) -> Bool {
        guard let amount = parseAmount(from: amountText), amount > 0 else { return false }
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public static func parseAmount(from text: String) -> Decimal? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard !normalized.isEmpty else { return nil }
        return Decimal(string: normalized)
    }

    public static func makeCreateInput(from values: ExpenseFormValues) -> Result<CreateExpenseInput, DomainError> {
        guard let amount = parseAmount(from: values.amountText), amount > 0 else {
            return .failure(.invalidAmount)
        }

        let title = values.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            return .failure(.invalidTitle)
        }

        let note = values.note.trimmingCharacters(in: .whitespacesAndNewlines)

        return .success(
            CreateExpenseInput(
                title: title,
                amount: amount,
                date: values.date,
                category: values.category,
                note: note.isEmpty ? nil : note
            )
        )
    }

    public static func makeUpdateInput(
        id: UUID,
        from values: ExpenseFormValues
    ) -> Result<UpdateExpenseInput, DomainError> {
        guard let amount = parseAmount(from: values.amountText), amount > 0 else {
            return .failure(.invalidAmount)
        }

        let title = values.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            return .failure(.invalidTitle)
        }

        let note = values.note.trimmingCharacters(in: .whitespacesAndNewlines)

        return .success(
            UpdateExpenseInput(
                id: id,
                title: title,
                amount: amount,
                date: values.date,
                category: values.category,
                note: note.isEmpty ? nil : note
            )
        )
    }
}
