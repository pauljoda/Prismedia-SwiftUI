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
        cutoffFormatScore: Int? = nil
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
    }

    enum CodingKeys: String, CodingKey {
        case id, kind, displayName, isDefault
        case targetLibraryRootID = "targetLibraryRootId"
        case pathTemplate, importMode, allowedFormats, preferredLanguages, minSeeders, minSizeBytes, maxSizeBytes
        case requiredTerms, ignoredTerms, preferredTerms, weightedTerms, autoPick, autoRedownload, upgradeUntilCutoff
        case cutoffSourceTier, cutoffFormatTier, downloadCategory, allowedQualities, cutoffQuality, formatScores
        case minFormatScore, cutoffFormatScore
    }
}
