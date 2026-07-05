import BackgroundTasks
import Domain
import Foundation

enum BackgroundSyncScheduler {
    static let taskIdentifier = "com.smartexpensemanager.app.expense-sync"

    static func register(syncUseCase: any SyncExpensesUseCaseProtocol) {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handleAppRefresh(task: refreshTask, syncUseCase: syncUseCase)
        }
    }

    static func scheduleNextSync() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    // MARK: - Private

    private static func handleAppRefresh(
        task: BGAppRefreshTask,
        syncUseCase: any SyncExpensesUseCaseProtocol
    ) {
        scheduleNextSync()

        let syncTask = Task {
            try await syncUseCase.execute()
        }

        task.expirationHandler = {
            syncTask.cancel()
        }

        Task {
            do {
                _ = try await syncTask.value
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }
}
