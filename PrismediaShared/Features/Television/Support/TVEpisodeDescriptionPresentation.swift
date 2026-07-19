import Foundation

enum TVEpisodeDescriptionPresentation {
    private static let conservativeCollapsedCharacterCapacity = 120

    static func text(
        episode: EntityThumbnail?,
        episodeDetail: EntityDetail?,
        seriesDescription: String?
    ) -> String? {
        nonempty(episodeDetail.map { EntityDetailPresentation(detail: $0).description } ?? nil)
            ?? nonempty(episode?.summary)
            ?? nonempty(seriesDescription)
    }

    /// Geometry is authoritative once laid out. This conservative fallback
    /// keeps disclosure available during tvOS focus/layout transitions where
    /// the hidden full-height measurement can briefly inherit the line limit.
    static func likelyRequiresDisclosure(_ text: String) -> Bool {
        text.count > conservativeCollapsedCharacterCapacity
            || text.filter { $0.isNewline }.count >= 3
    }

    private static func nonempty(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else { return nil }
        return trimmed
    }
}
