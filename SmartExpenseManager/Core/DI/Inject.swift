import SwiftUI

// MARK: - Environment

private struct AppContainerKey: EnvironmentKey {
    static let defaultValue = AppContainer(configuration: .testing())
}

public extension EnvironmentValues {
    var appContainer: AppContainer {
        get { self[AppContainerKey.self] }
        set { self[AppContainerKey.self] = newValue }
    }
}

// MARK: - Inject

/// Resolves a dependency from the SwiftUI environment's `AppContainer`.
///
/// ```swift
/// struct HomeView: View {
///     @Inject(\.fetchExpensesUseCase) private var fetchExpensesUseCase
/// }
/// ```
@propertyWrapper
public struct Inject<T> {
    @Environment(\.appContainer) private var container
    private let keyPath: KeyPath<AppContainer, T>

    public init(_ keyPath: KeyPath<AppContainer, T>) {
        self.keyPath = keyPath
    }

    public var wrappedValue: T {
        container[keyPath: keyPath]
    }
}
