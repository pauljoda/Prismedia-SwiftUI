import Foundation
import XCTest

@testable import PrismediaCore

final class AdministrativeLibraryFolderSelectionTests: XCTestCase {
    func testNavigationRemovesPreviouslySelectableFolderUntilNewResponseArrives() {
        var state = AdministrativeLibraryFolderSelection()
        let first = state.begin()
        state.succeed(.init(path: "/media", parentPath: "/", directories: []), request: first)
        XCTAssertEqual(state.selectedPath, "/media")
        let second = state.begin()
        XCTAssertNil(state.selectedPath)
        state.succeed(.init(path: "/stale", parentPath: "/", directories: []), request: first)
        XCTAssertNil(state.selectedPath)
        state.succeed(.init(path: "/media/books", parentPath: "/media", directories: []), request: second)
        XCTAssertEqual(state.selectedPath, "/media/books")
    }

    func testFailedAndCancelledRequestsCannotLeaveASelectablePath() {
        var state = AdministrativeLibraryFolderSelection()
        let failed = state.begin()
        state.fail(URLError(.cannotOpenFile), request: failed, isCancelled: false)
        XCTAssertNotNil(state.errorMessage)
        XCTAssertNil(state.selectedPath)
        let cancelled = state.begin()
        state.succeed(.init(path: "/media", parentPath: "/", directories: []), request: cancelled, isCancelled: true)
        XCTAssertNil(state.selectedPath)
        XCTAssertNil(state.errorMessage)
    }
}
