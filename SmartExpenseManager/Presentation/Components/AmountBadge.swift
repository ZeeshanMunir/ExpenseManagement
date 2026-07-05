import Core
import SwiftUI

struct AmountBadge: View {
    enum Style {
        case standard
        case prominent
    }

    let amount: Decimal
    var style: Style = .standard

    var body: some View {
        Text(amount.formattedAsCurrency())
            .font(style == .prominent ? .title2.weight(.semibold) : .subheadline.weight(.semibold))
            .foregroundStyle(style == .prominent ? .primary : Color.accentColor)
            .monospacedDigit()
    }
}

#Preview {
    VStack(spacing: 16) {
        AmountBadge(amount: 24.99)
        AmountBadge(amount: 128.50, style: .prominent)
    }
    .padding()
}
