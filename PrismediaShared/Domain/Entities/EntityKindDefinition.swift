import Foundation

/// Generated client snapshot of one canonical backend Entity-kind definition.
public struct EntityKindDefinition: Hashable, Sendable {
    public let kind: EntityKind
    public let displayName: String
    public let groupLabel: String
    public let category: String
    public let storageShape: String
    public let presentation: EntityKindPresentation
    public let navigation: EntityKindNavigation?
    public let search: EntityKindSearch?
    public let supportsFileDeletion: Bool
    public let supportsRequests: Bool
    /// Server selector used by automatic metadata identification, when this kind can be identified.
    public let autoIdentifySelector: String?
    /// Compatible provider kind used when plugins do not advertise this exact Entity kind.
    public let identifyPluginFallbackKind: EntityKind?
    /// Entity kinds that this kind may directly contain, when it owns a collection relationship.
    public let containableKinds: [EntityKind]?
    /// Whether users may create and manage instances of this kind without imported media.
    public let supportsManualManagement: Bool
    /// Browser upload and reviewed-replacement behavior declared by the backend kind definition.
    public let manualAcquisition: EntityManualAcquisitionPolicy
    /// Media quality family used by acquisition upgrade policy.
    public let mediaQualityFamily: EntityMediaQualityFamily
    /// Whether acquisition may replace this kind's media atomically during an upgrade.
    public let supportsAtomicMediaUpgrade: Bool
    /// Completion and filtering vocabulary declared by the backend kind definition.
    public let engagementMode: EntityEngagementMode
    /// Acquisition profile owned by this kind, when applicable.
    public let acquisitionProfile: EntityAcquisitionProfileDefinition?
    public let enumeratesIdentifyChildren: Bool

    public init(
        kind: EntityKind,
        displayName: String,
        groupLabel: String,
        category: String,
        storageShape: String,
        presentation: EntityKindPresentation,
        navigation: EntityKindNavigation?,
        search: EntityKindSearch?,
        supportsFileDeletion: Bool,
        supportsRequests: Bool,
        autoIdentifySelector: String?,
        identifyPluginFallbackKind: EntityKind?,
        containableKinds: [EntityKind]?,
        supportsManualManagement: Bool,
        manualAcquisition: EntityManualAcquisitionPolicy,
        mediaQualityFamily: EntityMediaQualityFamily,
        supportsAtomicMediaUpgrade: Bool,
        engagementMode: EntityEngagementMode,
        acquisitionProfile: EntityAcquisitionProfileDefinition?,
        enumeratesIdentifyChildren: Bool
    ) {
        self.kind = kind
        self.displayName = displayName
        self.groupLabel = groupLabel
        self.category = category
        self.storageShape = storageShape
        self.presentation = presentation
        self.navigation = navigation
        self.search = search
        self.supportsFileDeletion = supportsFileDeletion
        self.supportsRequests = supportsRequests
        self.autoIdentifySelector = autoIdentifySelector
        self.identifyPluginFallbackKind = identifyPluginFallbackKind
        self.containableKinds = containableKinds
        self.supportsManualManagement = supportsManualManagement
        self.manualAcquisition = manualAcquisition
        self.mediaQualityFamily = mediaQualityFamily
        self.supportsAtomicMediaUpgrade = supportsAtomicMediaUpgrade
        self.engagementMode = engagementMode
        self.acquisitionProfile = acquisitionProfile
        self.enumeratesIdentifyChildren = enumeratesIdentifyChildren
    }
}

public extension EntityKind {
    /// Canonical generated definition for this kind, or nil for a newer server kind unknown to the app build.
    var definition: EntityKindDefinition? {
        generatedEntityKindDefinitions[self]
    }

    var displayLabel: String {
        definition?.displayName
            ?? rawValue.replacingOccurrences(of: "-", with: " ").capitalized
    }

    var groupLabel: String {
        definition?.groupLabel ?? displayLabel
    }

    var thumbnailAspectRatio: Double {
        guard let presentation = definition?.presentation,
              presentation.thumbnailHeight > 0
        else { return 1 }
        return Double(presentation.thumbnailWidth) / Double(presentation.thumbnailHeight)
    }

    var prefersWideThumbnail: Bool {
        thumbnailAspectRatio > 1
    }
}
