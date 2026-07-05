import Domain
import SwiftUI

struct CategoryIconView: View {
    let category: ExpenseCategory
    var size: CGFloat = 40
    var cornerRadius: CGFloat = 10

    var body: some View {
        Image(systemName: category.iconName)
            .font(size >= 48 ? .title2.weight(.semibold) : .body.weight(.semibold))
            .foregroundStyle(category.tint)
            .frame(width: size, height: size)
            .background(category.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: cornerRadius))
            .accessibilityHidden(true)
    }
}
