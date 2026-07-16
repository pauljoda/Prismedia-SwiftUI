import Foundation

public struct AdministrativeLibraryRootMutation: Encodable, Hashable, Sendable {
    public let path: String
    public let label: String?
    public let enabled: Bool
    public let recursive: Bool
    public let scanVideos: Bool
    public let scanImages: Bool
    public let scanAudio: Bool
    public let scanBooks: Bool
    public let isNsfw: Bool
    public let autoIdentify: Bool
    public let grantUserIDs: [UUID]?

    public init(
        path: String,
        label: String? = nil,
        enabled: Bool = true,
        recursive: Bool = true,
        scanVideos: Bool = true,
        scanImages: Bool = true,
        scanAudio: Bool = true,
        scanBooks: Bool = false,
        isNsfw: Bool = false,
        autoIdentify: Bool = true,
        grantUserIDs: [UUID]? = nil
    ) {
        self.path = path
        self.label = label
        self.enabled = enabled
        self.recursive = recursive
        self.scanVideos = scanVideos
        self.scanImages = scanImages
        self.scanAudio = scanAudio
        self.scanBooks = scanBooks
        self.isNsfw = isNsfw
        self.autoIdentify = autoIdentify
        self.grantUserIDs = grantUserIDs
    }

    private enum CodingKeys: String, CodingKey {
        case path, label, enabled, recursive, scanVideos, scanImages, scanAudio, scanBooks, isNsfw, autoIdentify
        case grantUserIDs = "grantUserIds"
    }
}
