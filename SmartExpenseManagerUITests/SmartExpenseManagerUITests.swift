import XCTest

final class SmartExpenseManagerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsExpensesScreen() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Expenses"].waitForExistence(timeout: 5))
    }
}
