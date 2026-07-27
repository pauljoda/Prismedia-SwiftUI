import Foundation

public struct AdministrativeAcquisitionProfileSaveRequest: Encodable, Sendable {
    public let id: UUID?
    public let displayName: String
    public let isDefault: Bool
    public let kind: EntityKind
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
        profile: AdministrativeAcquisitionProfile,
        searchAfterDateType: EntityDateType?,
        searchDelayDays: Int
    ) {
        id = profile.id
        displayName = profile.displayName
        isDefault = profile.isDefault
        kind = profile.kind
        targetLibraryRootID = profile.targetLibraryRootID
        pathTemplate = profile.pathTemplate
        importMode = profile.importMode
        allowedFormats = profile.allowedFormats
        preferredLanguages = profile.preferredLanguages
        minSeeders = profile.minSeeders
        minSizeBytes = profile.minSizeBytes
        maxSizeBytes = profile.maxSizeBytes
        requiredTerms = profile.requiredTerms
        ignoredTerms = profile.ignoredTerms
        preferredTerms = profile.preferredTerms
        weightedTerms = profile.weightedTerms
        autoPick = profile.autoPick
        autoRedownload = profile.autoRedownload
        upgradeUntilCutoff = profile.upgradeUntilCutoff
        cutoffSourceTier = profile.cutoffSourceTier
        cutoffFormatTier = profile.cutoffFormatTier
        downloadCategory = profile.downloadCategory
        allowedQualities = profile.allowedQualities
        cutoffQuality = profile.cutoffQuality
        formatScores = profile.formatScores
        minFormatScore = profile.minFormatScore
        cutoffFormatScore = profile.cutoffFormatScore
        self.searchAfterDateType = searchAfterDateType
        self.searchDelayDays = searchAfterDateType == nil ? 0 : max(0, searchDelayDays)
    }

    private enum CodingKeys: String, CodingKey {
        case id, displayName, isDefault, kind
        case targetLibraryRootID = "targetLibraryRootId"
        case pathTemplate, importMode, allowedFormats, preferredLanguages, minSeeders
        case minSizeBytes, maxSizeBytes, requiredTerms, ignoredTerms, preferredTerms
        case weightedTerms, autoPick, autoRedownload, upgradeUntilCutoff
        case cutoffSourceTier, cutoffFormatTier, downloadCategory, allowedQualities
        case cutoffQuality, formatScores, minFormatScore, cutoffFormatScore
        case searchAfterDateType, searchDelayDays
    }
}
