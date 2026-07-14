import Foundation

struct AdministrativeApplyIdentifyQueueItemRequest: Encodable, Sendable {
    let proposal: AdministrativeEntityMetadataProposal?
    let selectedFields: [String]
    let selectedImages: [String: String?]?
    let progressID: UUID?

    enum CodingKeys: String, CodingKey {
        case proposal, selectedFields, selectedImages
        case progressID = "progressId"
    }
}
