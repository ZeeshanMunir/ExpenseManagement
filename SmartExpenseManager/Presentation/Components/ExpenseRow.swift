import Core
import Domain
import SwiftUI

struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 14) {
            CategoryIconView(category: expense.category ?? .other)

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let category = expense.category {
                        CategoryChip(category: category, style: .compact)
                            .layoutPriority(1)
                    }
                    Text(expense.date.formatted(as: "MMM d, yyyy"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .layoutPriority(0)
                    if expense.syncStatus != .synced {
                        SyncStatusBadge(status: expense.syncStatus, style: .compact)
                            .layoutPriority(2)
                    }
                }
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            AmountBadge(amount: expense.amount, style: .standard)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(Text("Opens expense details"))
    }

    private var accessibilityLabel: String {
        let amount = expense.amount.formattedAsCurrency()
        let category = expense.category?.displayName ?? ExpenseCategory.other.displayName
        return "\(expense.title), \(amount), \(category)"
    }
}
