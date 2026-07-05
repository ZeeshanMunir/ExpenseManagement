import Core
import Data
import Domain
import SwiftUI

@main
struct SmartExpenseManagerApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let container: AppContainer

    init() {
        let container = AppContainer(configuration: .production)
        self.container = container
        BackgroundSyncScheduler.register(syncUseCase: container.syncExpensesUseCase)
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environment(\.appContainer, container)
                .task {
                    await container.syncCoordinator.startAutoSync()
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                BackgroundSyncScheduler.scheduleNextSync()
                Task {
                    if await container.reachability.isConnected() {
                        _ = try? await container.retryFailedSyncUseCase.execute()
                    }
                }
            }
        }
    }
}
