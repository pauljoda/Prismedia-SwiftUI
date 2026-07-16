import Foundation

public enum AdministrativeDatabaseRestorePhase: Equatable, Sendable {
    case connecting
    case restoring
    case complete
    case failed(String)
}
