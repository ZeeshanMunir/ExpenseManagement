import SwiftUI

struct LoadingView: View {
    var message: String = L10n.loading

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .symbolEffect(.pulse, options: .repeating)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

#Preview {
    LoadingView(message: L10n.loadingExpenses)
}
