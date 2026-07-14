import Foundation

enum AuthenticationErrorMessage {
    private static let knownProblemCodes = [
        "invalid_credentials",
        "authentication_required",
        "auth_rate_limited",
        "setup_already_completed",
        "password_invalid",
    ]

    static func message(for error: Error) -> String {
        if error is URLError {
            return "We couldn’t reach that server. Check the address and try again."
        }

        if let apiError = error as? PrismediaAPIError {
            switch apiError {
            case .invalidURL:
                return "We couldn’t build a request for that server. Check the address and try again."
            case .invalidResponse, .decoding:
                return "We couldn’t understand the server’s response. Check that Prismedia is up to date and try again."
            case .redirectedToSignIn:
                return "That address opened another sign-in page. Try your Prismedia server’s direct address."
            case .httpStatus(_, let problem):
                guard let problem, knownProblemCodes.contains(problem.code) else {
                    return "The server couldn’t complete this request. Try again."
                }
                return apiError.localizedDescription
            }
        }

        if error is ServerAddressError {
            return "Enter a valid Prismedia server address."
        }

        return "Something went wrong. Try again."
    }
}
