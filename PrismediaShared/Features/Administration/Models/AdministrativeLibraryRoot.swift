import Foundation

public struct AdministrativeLibraryRoot: Decodable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let path: String
    public let label: String
    public let enabled: Bool
    public let recursive: Bool
    public let scanVideos: Bool
    public let scanImages: Bool
    public let scanAudio: Bool
    public let scanBooks: Bool
    public let isNsfw: Bool
    public let lastScannedAt: Date?
    public let createdAt: Date
    public let updatedAt: Date
    public let autoIdentify: Bool
    public let createdByUserID: UUID?
    public let accessUserIDs: [UUID]?

    public init(
        id: UUID,
        path: String,
        label: String,
        enabled: Bool,
        recursive: Bool = true,
        scanVideos: Bool = false,
        scanImages: Bool = false,
        scanAudio: Bool = false,
        scanBooks: Bool = false,
        isNsfw: Bool = false,
        lastScannedAt: Date? = nil,
        createdAt: Date = .distantPast,
        updatedAt: Date = .distantPast,
        autoIdentify: Bool = true,
        createdByUserID: UUID? = nil,
        accessUserIDs: [UUID]? = nil
    ) {
        self.id = id
        self.path = path
        self.label = label
        self.enabled = enabled
        self.recursive = recursive
        self.scanVideos = scanVideos
        self.scanImages = scanImages
        self.scanAudio = scanAudio
        self.scanBooks = scanBooks
        self.isNsfw = isNsfw
        self.lastScannedAt = lastScannedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.autoIdentify = autoIdentify
        self.createdByUserID = createdByUserID
        self.accessUserIDs = accessUserIDs
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        path = try container.decode(String.self, forKey: .path)
        label = try container.decode(String.self, forKey: .label)
        enabled = try container.decode(Bool.self, forKey: .enabled)
        recursive = try container.decode(Bool.self, forKey: .recursive)
        scanVideos = try container.decode(Bool.self, forKey: .scanVideos)
        scanImages = try container.decode(Bool.self, forKey: .scanImages)
        scanAudio = try container.decode(Bool.self, forKey: .scanAudio)
        scanBooks = try container.decode(Bool.self, forKey: .scanBooks)
        isNsfw = try container.decode(Bool.self, forKey: .isNsfw)
        lastScannedAt = try container.decodeIfPresent(Date.self, forKey: .lastScannedAt)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        autoIdentify = try container.decodeIfPresent(Bool.self, forKey: .autoIdentify) ?? true
        createdByUserID = try container.decodeIfPresent(UUID.self, forKey: .createdByUserID)
        accessUserIDs = try container.decodeIfPresent([UUID].self, forKey: .accessUserIDs)
    }

    enum CodingKeys: String, CodingKey {
        case id, path, label, enabled, recursive, scanVideos, scanImages, scanAudio, scanBooks, isNsfw
        case lastScannedAt, createdAt, updatedAt, autoIdentify
        case createdByUserID = "createdByUserId"
        case accessUserIDs = "accessUserIds"
    }
}
