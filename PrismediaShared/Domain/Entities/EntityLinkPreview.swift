import Foundation

/// Stable navigation identity for any entity, including child entities whose
/// destination requires structural parent context.
public struct EntityLinkPreview: Hashable, Sendable {
    public let title: String
    public let subtitle: String?
    public let artworkPath: String?
    public let progress: Double?
    public let resumeSeconds: Double?

    public init(
        title: String,
        subtitle: String?,
        artworkPath: String?,
        progress: Double? = nil,
        resumeSeconds: Double? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.artworkPath = artworkPath
        self.progress = progress
        self.resumeSeconds = resumeSeconds
    }
}
