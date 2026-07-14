import Foundation

public struct AdministrativeCountResponse: Decodable, Sendable {
    public let cancelled: Int?
    public let cleared: Int?

    public init(cancelled: Int? = nil, cleared: Int? = nil) {
        self.cancelled = cancelled
        self.cleared = cleared
    }
}
