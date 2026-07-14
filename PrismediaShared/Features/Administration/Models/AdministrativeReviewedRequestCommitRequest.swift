import Foundation

public struct AdministrativeReviewedRequestCommitRequest: Encodable, Hashable, Sendable {
    public let kind: String
    public let pluginID: String
    public let rootExternalIdentity: AdministrativeExternalIdentity
    public let proposalRevision: String
    public let selectedProposalIDs: [String]
    public let targetLibraryRootID: UUID?
    public let profileID: UUID?
    public let preset: String?

    public init(
        kind: String,
        pluginID: String,
        rootExternalIdentity: AdministrativeExternalIdentity,
        proposalRevision: String,
        selectedProposalIDs: [String],
        targetLibraryRootID: UUID? = nil,
        profileID: UUID? = nil,
        preset: String? = nil
    ) {
        self.kind = kind
        self.pluginID = pluginID
        self.rootExternalIdentity = rootExternalIdentity
        self.proposalRevision = proposalRevision
        self.selectedProposalIDs = selectedProposalIDs
        self.targetLibraryRootID = targetLibraryRootID
        self.profileID = profileID
        self.preset = preset
    }

    enum CodingKeys: String, CodingKey {
        case kind
        case pluginID = "pluginId"
        case rootExternalIdentity, proposalRevision
        case selectedProposalIDs = "selectedProposalIds"
        case targetLibraryRootID = "targetLibraryRootId"
        case profileID = "profileId"
        case preset
    }
}
