import XCTest

@testable import PrismediaCore

final class SignInViewStateTests: XCTestCase {
    func testAuthenticationErrorsExposeSafeActionableMessages() {
        let internalFailure = PrismediaAPIError.httpStatus(
            500,
            APIProblem(code: "database_unavailable", message: "Npgsql timeout from db-primary")
        )
        let credentialFailure = PrismediaAPIError.httpStatus(
            401,
            APIProblem(code: "invalid_credentials", message: "Invalid username or password.")
        )

        let internalMessage = AuthenticationErrorMessage.message(for: internalFailure)

        XCTAssertEqual(internalMessage, "The server couldn’t complete this request. Try again.")
        XCTAssertFalse(internalMessage.contains("HTTP"))
        XCTAssertFalse(internalMessage.contains("Npgsql"))
        XCTAssertEqual(
            AuthenticationErrorMessage.message(for: credentialFailure),
            "Invalid username or password."
        )
    }
}
