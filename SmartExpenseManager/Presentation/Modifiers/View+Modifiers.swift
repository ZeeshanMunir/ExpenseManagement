import SwiftUI

extension View {
    func loadingOverlay(isPresented: Bool, message: String) -> some View {
        modifier(LoadingOverlayModifier(isPresented: isPresented, message: message))
    }

    func errorAlert(message: Binding<String?>) -> some View {
        modifier(ErrorAlertModifier(message: message))
    }

    func deleteConfirmation(
        isPresented: Binding<Bool>,
        message: String,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) -> some View {
        modifier(
            DeleteConfirmationModifier(
                isPresented: isPresented,
                message: message,
                onConfirm: onConfirm,
                onCancel: onCancel
            )
        )
    }
}

private struct LoadingOverlayModifier: ViewModifier {
    let isPresented: Bool
    let message: String

    func body(content: Content) -> some View {
        ZStack {
            content
            if isPresented {
                LoadingView(message: message)
                    .background(.ultraThinMaterial)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}

private struct ErrorAlertModifier: ViewModifier {
    @Binding var message: String?

    private var isPresented: Binding<Bool> {
        Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )
    }

    func body(content: Content) -> some View {
        content.alert(L10n.error, isPresented: isPresented) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }
}

private struct DeleteConfirmationModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let onConfirm: () -> Void
    let onCancel: (() -> Void)?

    func body(content: Content) -> some View {
        content.confirmationDialog(
            L10n.deleteExpenseTitle,
            isPresented: $isPresented,
            titleVisibility: .visible
        ) {
            Button(L10n.delete, role: .destructive, action: onConfirm)
            Button(L10n.cancel, role: .cancel) {
                onCancel?()
            }
        } message: {
            Text(message)
        }
    }
}
