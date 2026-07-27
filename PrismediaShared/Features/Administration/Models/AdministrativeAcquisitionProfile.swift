import Foundation

public struct AdministrativeAcquisitionProfile: Decodable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let kind: EntityKind
    public let displayName: String
    public let isDefault: Bool
    public let targetLibraryRootID: UUID
    public let pathTemplate: String
    public let importMode: String
    public let allowedFormats: [String]
    public let preferredLanguages: [String]
    public let minSeeders: Int
    public let minSizeBytes: Int64?
    public let maxSizeBytes: Int64?
    public let requiredTerms: [String]
    public let ignoredTerms: [String]
    public let preferredTerms: [String]
    public let weightedTerms: [AdministrativeWeightedTerm]
    public let autoPick: Bool
    public let autoRedownload: Bool
    public let upgradeUntilCutoff: Bool
    public let cutoffSourceTier: String
    public let cutoffFormatTier: String
    public let downloadCategory: String?
    public let allowedQualities: [String]?
    public let cutoffQuality: String?
    public let formatScores: [String: Int]?
    public let minFormatScore: Int
    public let cutoffFormatScore: Int?
    public let searchAfterDateType: EntityDateType?
    public let searchDelayDays: Int

    public init(
        id: UUID,
        kind: EntityKind,
        displayName: String,
        isDefault: Bool,
        targetLibraryRootID: UUID,
        pathTemplate: String = "",
        importMode: String = "copy",
        allowedFormats: [String] = [],
        preferredLanguages: [String] = [],
        minSeeders: Int = 0,
        minSizeBytes: Int64? = nil,
        maxSizeBytes: Int64? = nil,
        requiredTerms: [String] = [],
        ignoredTerms: [String] = [],
        preferredTerms: [String] = [],
        weightedTerms: [AdministrativeWeightedTerm] = [],
        autoPick: Bool = true,
        autoRedownload: Bool = false,
        upgradeUntilCutoff: Bool = false,
        cutoffSourceTier: String = "unknown",
        cutoffFormatTier: String = "unknown",
        downloadCategory: String? = nil,
        allowedQualities: [String]? = nil,
        cutoffQuality: String? = nil,
        formatScores: [String: Int]? = nil,
        minFormatScore: Int = 0,
        cutoffFormatScore: Int? = nil,
        searchAfterDateType: EntityDateType? = nil,
        searchDelayDays: Int = 0
    ) {
        self.id = id
        self.kind = kind
        self.displayName = displayName
        self.isDefault = isDefault
        self.targetLibraryRootID = targetLibraryRootID
        self.pathTemplate = pathTemplate
        self.importMode = importMode
        self.allowedFormats = allowedFormats
        self.preferredLanguages = preferredLanguages
        self.minSeeders = minSeeders
        self.minSizeBytes = minSizeBytes
        self.maxSizeBytes = maxSizeBytes
        self.requiredTerms = requiredTerms
        self.ignoredTerms = ignoredTerms
        self.preferredTerms = preferredTerms
        self.weightedTerms = weightedTerms
        self.autoPick = autoPick
        self.autoRedownload = autoRedownload
        self.upgradeUntilCutoff = upgradeUntilCutoff
        self.cutoffSourceTier = cutoffSourceTier
        self.cutoffFormatTier = cutoffFormatTier
        self.downloadCategory = downloadCategory
        self.allowedQualities = allowedQualities
        self.cutoffQuality = cutoffQuality
        self.formatScores = formatScores
        self.minFormatScore = minFormatScore
        self.cutoffFormatScore = cutoffFormatScore
        self.searchAfterDateType = searchAfterDateType
        self.searchDelayDays = searchDelayDays
    }

    enum CodingKeys: String, CodingKey {
        case id, kind, displayName, isDefault
        case targetLibraryRootID = "targetLibraryRootId"
        case pathTemplate, importMode, allowedFormats, preferredLanguages, minSeeders, minSizeBytes, maxSizeBytes
        case requiredTerms, ignoredTerms, preferredTerms, weightedTerms, autoPick, autoRedownload, upgradeUntilCutoff
        case cutoffSourceTier, cutoffFormatTier, downloadCategory, allowedQualities, cutoffQuality, formatScores
        case minFormatScore, cutoffFormatScore, searchAfterDateType, searchDelayDays
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        kind = try container.decode(EntityKind.self, forKey: .kind)
        displayName = try container.decode(String.self, forKey: .displayName)
        isDefault = try container.decode(Bool.self, forKey: .isDefault)
        targetLibraryRootID = try container.decode(UUID.self, forKey: .targetLibraryRootID)
        pathTemplate = try container.decode(String.self, forKey: .pathTemplate)
        importMode = try container.decode(String.self, forKey: .importMode)
        allowedFormats = try container.decode([String].self, forKey: .allowedFormats)
        preferredLanguages = try container.decode([String].self, forKey: .preferredLanguages)
        minSeeders = try PrismediaDecoding.integer(from: container, forKey: .minSeeders)
        minSizeBytes = try PrismediaDecoding.optionalInteger64(from: container, forKey: .minSizeBytes)
        maxSizeBytes = try PrismediaDecoding.optionalInteger64(from: container, forKey: .maxSizeBytes)
        requiredTerms = try container.decode([String].self, forKey: .requiredTerms)
        ignoredTerms = try container.decode([String].self, forKey: .ignoredTerms)
        preferredTerms = try container.decode([String].self, forKey: .preferredTerms)
        weightedTerms = try container.decode([AdministrativeWeightedTerm].self, forKey: .weightedTerms)
        autoPick = try container.decode(Bool.self, forKey: .autoPick)
        autoRedownload = try container.decode(Bool.self, forKey: .autoRedownload)
        upgradeUntilCutoff = try container.decode(Bool.self, forKey: .upgradeUntilCutoff)
        cutoffSourceTier = try container.decode(String.self, forKey: .cutoffSourceTier)
        cutoffFormatTier = try container.decode(String.self, forKey: .cutoffFormatTier)
        downloadCategory = try container.decodeIfPresent(String.self, forKey: .downloadCategory)
        allowedQualities = try container.decodeIfPresent([String].self, forKey: .allowedQualities)
        cutoffQuality = try container.decodeIfPresent(String.self, forKey: .cutoffQuality)
        formatScores = try PrismediaDecoding.optionalIntegerDictionary(from: container, forKey: .formatScores)
        minFormatScore =
            try PrismediaDecoding.optionalInteger(from: container, forKey: .minFormatScore) ?? 0
        cutoffFormatScore =
            try PrismediaDecoding.optionalInteger(from: container, forKey: .cutoffFormatScore)
        searchAfterDateType = try container.decodeIfPresent(EntityDateType.self, forKey: .searchAfterDateType)
        searchDelayDays =
            try PrismediaDecoding.optionalInteger(from: container, forKey: .searchDelayDays) ?? 0
    }
}
