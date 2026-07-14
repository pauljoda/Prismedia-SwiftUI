import Foundation

public struct AdministrativeEntitySearchCandidate: Codable, Hashable, Sendable {
    public let externalIDs: [String: String]
    public let title: String
    public let year: Int?
    public let overview: String?
    public let posterURL: String?
    public let popularity: Decimal?
    public let candidateID: String?
    public let source: String?
    public let confidence: Decimal?
    public let matchReason: String?

    public init(
        externalIDs: [String: String],
        title: String,
        year: Int? = nil,
        overview: String? = nil,
        posterURL: String? = nil,
        popularity: Decimal? = nil,
        candidateID: String? = nil,
        source: String? = nil,
        confidence: Decimal? = nil,
        matchReason: String? = nil
    ) {
        self.externalIDs = externalIDs
        self.title = title
        self.year = year
        self.overview = overview
        self.posterURL = posterURL
        self.popularity = popularity
        self.candidateID = candidateID
        self.source = source
        self.confidence = confidence
        self.matchReason = matchReason
    }

    enum CodingKeys: String, CodingKey {
        case externalIDs = "externalIds"
        case title, year, overview
        case posterURL = "posterUrl"
        case popularity
        case candidateID = "candidateId"
        case source, confidence, matchReason
    }
}
