import Foundation

public struct RequestReviewRoute: Hashable, Sendable {
    public let kind: RequestKindDefinition
    public let pluginID: String
    public let externalIdentity: AdministrativeExternalIdentity
}
