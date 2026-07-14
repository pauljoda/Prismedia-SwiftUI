import Foundation

public enum PrismediaAPIError: Error, LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case redirectedToSignIn(URL?)
    case httpStatus(Int, APIProblem?)
    case decoding(Error)

    public var isAuthenticationFailure: Bool {
        if case .httpStatus(401, _) = self {
            return true
        }
        return false
    }

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let path):
            return "Could not build a Prismedia URL for \(path)."
        case .invalidResponse:
            return "The Prismedia server returned an invalid response."
        case .redirectedToSignIn:
            return
                "The Prismedia API was redirected to a sign-in page before the request reached the server. Bypass proxy SSO for /api/* or use a direct server URL."
        case .httpStatus(let status, let problem):
            switch problem?.code {
            case "invalid_credentials":
                return "Invalid username or password."
            case "authentication_required":
                return "Your session has expired. Sign in again."
            case "auth_rate_limited":
                return "Too many sign-in attempts. Wait a couple of minutes and try again."
            case "setup_already_completed":
                return "This server has already been set up. Sign in instead."
            case "password_invalid":
                return "Passwords must be at least 8 characters."
            default:
                if let message = problem?.message, !message.isEmpty {
                    return "Prismedia returned HTTP \(status): \(message)"
                }
                return "Prismedia returned HTTP \(status)."
            }
        case .decoding:
            return "Prismedia returned data the app could not read yet."
        }
    }
}
