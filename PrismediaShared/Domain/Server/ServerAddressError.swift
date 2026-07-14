import Foundation

public enum ServerAddressError: Error, Equatable, LocalizedError {
    case invalidURL

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Enter a valid Prismedia server URL."
        }
    }
}
