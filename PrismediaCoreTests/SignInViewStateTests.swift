import XCTest

@testable import PrismediaCore

final class SignInViewStateTests: XCTestCase {
    func testServerStepRequiresAnAddressBeforeContinuing() {
        var state = SignInViewState()

        XCTAssertFalse(state.canSubmit)

        state.serverURLText = "localhost:8008"

        XCTAssertTrue(state.canSubmit)
        XCTAssertEqual(state.primaryActionTitle, "Continue")
    }

    func testLoginRequiresBothUsernameAndPassword() throws {
        var state = SignInViewState.login(
            server: try ServerAddress(text: "localhost:8008"),
            username: "paul"
        )

        XCTAssertFalse(state.canSubmit)

        state.password = "dev-prismedia"

        XCTAssertTrue(state.canSubmit)
        XCTAssertEqual(state.primaryActionTitle, "Sign In")
        XCTAssertEqual(state.serverDisplayName, "localhost:8008")
    }

    func testFirstAdminRequiresAnEightCharacterPassword() throws {
        var state = SignInViewState.firstRunSetup(
            server: try ServerAddress(text: "media.local:8008")
        )
        state.username = "admin"
        state.password = "short"

        XCTAssertFalse(state.canSubmit)

        state.password = "long-enough"

        XCTAssertTrue(state.canSubmit)
        XCTAssertEqual(state.primaryActionTitle, "Create Admin")
    }

    func testChangingServerClearsCredentialsAndErrors() throws {
        var state = SignInViewState.login(
            server: try ServerAddress(text: "localhost:8008"),
            username: "paul",
            errorMessage: "Invalid username or password."
        )
        state.password = "wrong"

        state.returnToServerSelection()

        XCTAssertEqual(state.step, .server)
        XCTAssertEqual(state.username, "")
        XCTAssertEqual(state.password, "")
        XCTAssertNil(state.errorMessage)
    }

    func testBusyStateUsesActionSpecificCopyAndDisablesSubmission() throws {
        var state = SignInViewState.login(
            server: try ServerAddress(text: "localhost:8008"),
            username: "paul"
        )
        state.password = "dev-prismedia"
        state.activity = .signingIn

        XCTAssertFalse(state.canSubmit)
        XCTAssertFalse(state.canChangeServer)
        XCTAssertEqual(state.primaryActionTitle, "Signing In…")
    }

    func testUnexpectedHTTPFailureDoesNotExposeDeveloperCopy() {
        let error = PrismediaAPIError.httpStatus(
            500,
            APIProblem(code: "database_unavailable", message: "Npgsql timeout from db-primary")
        )

        let message = AuthenticationErrorMessage.message(for: error)

        XCTAssertEqual(message, "The server couldn’t complete this request. Try again.")
        XCTAssertFalse(message.contains("HTTP"))
        XCTAssertFalse(message.contains("Npgsql"))
    }

    func testKnownCredentialFailureKeepsActionableCopy() {
        let error = PrismediaAPIError.httpStatus(
            401,
            APIProblem(code: "invalid_credentials", message: "Invalid username or password.")
        )

        XCTAssertEqual(
            AuthenticationErrorMessage.message(for: error),
            "Invalid username or password."
        )
    }
}
