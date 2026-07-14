import Foundation

public struct AdministrativeJobListResponse: Decodable, Sendable {
    public let items: [AdministrativeJobRun]
    public let counts: [AdministrativeJobCount]
}
