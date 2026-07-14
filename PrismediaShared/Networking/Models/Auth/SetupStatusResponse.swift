import Foundation

public struct SetupStatusResponse: Decodable, Equatable, Sendable {
    public let needsSetup: Bool
    public let hasUsers: Bool
}
