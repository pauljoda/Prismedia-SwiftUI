import Foundation

public enum AdministrativeFileValidationError: LocalizedError, Equatable, Sendable {
    case invalidName
    case absolutePath
    case escapingPath
    case emptyPath
    case unchangedDestination
    case descendantDestination

    public var errorDescription: String? {
        switch self {
        case .invalidName: "Enter one valid file or folder name without slashes."
        case .absolutePath: "Use a path relative to the selected library root."
        case .escapingPath: "The path cannot escape the selected library root."
        case .emptyPath: "Library roots cannot be changed by this operation."
        case .unchangedDestination: "Choose a different destination."
        case .descendantDestination: "A folder cannot be moved inside itself."
        }
    }
}
