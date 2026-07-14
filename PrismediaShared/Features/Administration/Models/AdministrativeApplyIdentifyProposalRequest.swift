import Foundation

struct AdministrativeApplyIdentifyProposalRequest: Encodable, Sendable {
    let proposal: AdministrativeEntityMetadataProposal
    let selectedFields: [String]
    let selectedImages: [String: String?]?
}
