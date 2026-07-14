import Foundation

public struct AdministrativeRequestSearchResult: Decodable, Identifiable, Hashable, Sendable {
    public var id: String { "\(pluginID ?? source):\(externalID)" }
    public let serviceID: UUID
    public let source: String
    public let kind: String
    public let externalID: String
    public let title: String
    public let subtitle: String?
    public let year: Int?
    public let overview: String?
    public let posterURL: String?
    public let backdropURL: String?
    public let rating: Decimal?
    public let runtimeMinutes: Int?
    public let certification: String?
    public let trackCount: Int?
    public let tags: [String]
    public let tracked: Bool
    public let upstreamID: String?
    public let monitored: Bool?
    public let requestable: Bool
    public let providerName: String?
    public let pluginID: String?
    public let externalIdentity: AdministrativeExternalIdentity?

    enum CodingKeys: String, CodingKey {
        case serviceID = "serviceId"
        case source, kind
        case externalID = "externalId"
        case title, subtitle, year, overview
        case posterURL = "posterUrl"
        case backdropURL = "backdropUrl"
        case rating, runtimeMinutes, certification, trackCount, tags, tracked
        case upstreamID = "upstreamId"
        case monitored, requestable, providerName, externalIdentity
        case pluginID = "pluginId"
    }
}
