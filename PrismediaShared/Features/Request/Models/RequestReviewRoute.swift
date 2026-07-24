import Foundation

public struct RequestReviewRoute: Hashable, Identifiable, Sendable {
    public let kind: RequestKindDefinition
    public let pluginID: String
    public let externalIdentity: AdministrativeExternalIdentity
    public let artworkPath: String?

    public init(
        kind: RequestKindDefinition,
        pluginID: String,
        externalIdentity: AdministrativeExternalIdentity,
        artworkPath: String? = nil
    ) {
        self.kind = kind
        self.pluginID = pluginID
        self.externalIdentity = externalIdentity
        self.artworkPath = artworkPath
    }

    public var id: String {
        "\(kind.rawValue):\(pluginID):\(externalIdentity.namespace):\(externalIdentity.value)"
    }
}
