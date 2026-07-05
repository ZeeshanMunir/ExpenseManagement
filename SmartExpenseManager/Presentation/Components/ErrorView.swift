import SwiftUI

struct ErrorView: View {
    let message: String
    var retryTitle: String = L10n.tryAgain
    var retryAction: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(L10n.somethingWentWrong, systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            if let retryAction {
                Button(retryTitle, action: retryAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
