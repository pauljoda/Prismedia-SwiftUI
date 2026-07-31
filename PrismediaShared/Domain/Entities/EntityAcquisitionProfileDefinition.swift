import Foundation

/// Generated client snapshot of acquisition-profile policy owned by an Entity kind.
public struct EntityAcquisitionProfileDefinition: Hashable, Sendable {
    public let label: String
    public let displayOrder: Int
    public let libraryRootMediaCapability: String
    public let supportedReleaseDateTypes: [EntityDateType]
    public let defaultNamingTemplate: String
    public let namingHint: String
    public let namingFamily: String

    public init(
        label: String,
        displayOrder: Int,
        libraryRootMediaCapability: String,
        supportedReleaseDateTypes: [EntityDateType],
        defaultNamingTemplate: String,
        namingHint: String,
        namingFamily: String
    ) {
        self.label = label
        self.displayOrder = displayOrder
        self.libraryRootMediaCapability = libraryRootMediaCapability
        self.supportedReleaseDateTypes = supportedReleaseDateTypes
        self.defaultNamingTemplate = defaultNamingTemplate
        self.namingHint = namingHint
        self.namingFamily = namingFamily
    }
}
