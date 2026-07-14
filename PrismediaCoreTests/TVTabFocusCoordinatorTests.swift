import XCTest

@testable import PrismediaCore

@MainActor
final class TVTabFocusCoordinatorTests: XCTestCase {
    func testEachFocusRequestPublishesANewGeneration() {
        let coordinator = TVTabFocusCoordinator()

        coordinator.requestFocus()
        let firstRequest = coordinator.requestGeneration
        coordinator.requestFocus()

        XCTAssertEqual(firstRequest, 1)
        XCTAssertEqual(coordinator.requestGeneration, 2)
    }

    func testTVShellRoutesFocusedTabExitCommandThroughItsNavigationStack() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let shell = try String(
            contentsOf: repositoryRoot.appending(
                path: "PrismediaShared/App/Shell/PrismediaTVShellView.swift"
            ),
            encoding: .utf8
        )

        XCTAssertTrue(shell.contains(".onExitCommand(perform:"))
        XCTAssertTrue(shell.contains("router.navigateBack(in:"))
        XCTAssertFalse(
            shell.contains("guard focusedTabID != nil"),
            "System Tab labels do not reliably publish @FocusState on tvOS; back availability must follow the selected stack."
        )
    }
}
