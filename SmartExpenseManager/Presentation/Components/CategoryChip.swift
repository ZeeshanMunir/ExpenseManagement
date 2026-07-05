import Domain
import SwiftUI

struct CategoryChip: View {
    enum Style {
        case standard
        case compact
    }

    let category: ExpenseCategory
    var style: Style = .standard

    var body: some View {
        HStack(spacing: style == .compact ? 4 : 6) {
            Image(systemName: category.iconName)
                .font(style == .compact ? .caption2 : .caption)
            Text(category.displayName)
                .font(style == .compact ? .caption2 : .caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .fixedSize(horizontal: true, vertical: false)
        .foregroundStyle(category.tint)
        .padding(.horizontal, style == .compact ? 8 : 10)
        .padding(.vertical, style == .compact ? 3 : 5)
        .background(category.tint.opacity(0.12), in: Capsule())
    }
}

#Preview {
    VStack(spacing: 12) {
        CategoryChip(category: .food)
        CategoryChip(category: .transport, style: .compact)
    }
    .padding()
}
