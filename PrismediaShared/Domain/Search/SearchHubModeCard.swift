import Foundation

/// Display metadata for one section card on the search landing page.
public struct SearchHubModeCard: Identifiable, Hashable, Sendable {
    public let mode: AppMode
    public let preferredArtworkKinds: [EntityKind]

    public var id: String { mode.id }
    public var title: String { mode.title }
    public var systemImage: String { mode.systemImage }
    public var subtitle: String {
        mode.destinations.map(\.title).joined(separator: " · ")
    }

    public init(mode: AppMode, preferredArtworkKinds: [EntityKind]) {
        self.mode = mode
        self.preferredArtworkKinds = preferredArtworkKinds
    }
}
