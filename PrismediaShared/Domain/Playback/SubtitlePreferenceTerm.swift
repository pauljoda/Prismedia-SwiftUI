import Foundation

/// One case-insensitive subtitle-selection term and the score it contributes when a track matches.
public struct SubtitlePreferenceTerm: Codable, Equatable, Hashable, Sendable {
    /// Text matched independently against a subtitle track's language and label tokens.
    public let term: String

    /// Positive score added once when the term matches a track.
    public var weight: Int

    /// Creates one weighted subtitle-selection preference.
    /// - Parameters:
    ///   - term: Text matched without regard to case.
    ///   - weight: Score contributed by a matching track.
    public init(term: String, weight: Int) {
        self.term = term
        self.weight = weight
    }
}
