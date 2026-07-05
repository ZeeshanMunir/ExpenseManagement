import Foundation
import os.log

public enum AppLogger {
    private static let subsystem = AppConstants.bundleIdentifier

    public static let network = Logger(subsystem: subsystem, category: "Network")
    public static let data = Logger(subsystem: subsystem, category: "Data")
    public static let ui = Logger(subsystem: subsystem, category: "UI")

    public static func logError(_ logger: Logger, _ message: String, error: Error? = nil) {
        if let error {
            logger.error("\(message, privacy: .public): \(error.localizedDescription, privacy: .public)")
        } else {
            logger.error("\(message, privacy: .public)")
        }
    }

    public static func logDebug(_ logger: Logger, _ message: String) {
        logger.debug("\(message, privacy: .public)")
    }
}
