import Foundation
import Security

public enum KeychainSessionStoreError: Error, LocalizedError {
    case invalidData
    case unhandledStatus(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .invalidData:
            return "The saved Prismedia session could not be read."
        case .unhandledStatus(let status):
            return "Keychain returned status \(status)."
        }
    }
}
