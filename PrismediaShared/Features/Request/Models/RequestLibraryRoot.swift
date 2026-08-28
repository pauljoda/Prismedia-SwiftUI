import Foundation

/// A library destination the signed-in user may target with a content request.
public struct RequestLibraryRoot: Decodable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let label: String
    public let scanVideos: Bool
    public let scanImages: Bool
    public let scanAudio: Bool
    public let scanBooks: Bool
    public let isNsfw: Bool

    public init(
        id: UUID,
        label: String,
        scanVideos: Bool = false,
        scanImages: Bool = false,
        scanAudio: Bool = false,
        scanBooks: Bool = false,
        isNsfw: Bool = false
    ) {
        self.id = id
        self.label = label
        self.scanVideos = scanVideos
        self.scanImages = scanImages
        self.scanAudio = scanAudio
        self.scanBooks = scanBooks
        self.isNsfw = isNsfw
    }
}
