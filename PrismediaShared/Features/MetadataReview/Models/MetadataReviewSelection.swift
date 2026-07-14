import Foundation

public struct MetadataReviewSelection: Hashable, Sendable {
    public var selectedFieldsByProposal: [String: Set<MetadataReviewField>]
    public var selectedImagesByProposal: [String: [String: String]]
    public var selectedTagsByProposal: [String: Set<String>]
    public var selectedCreditsByProposal: [String: Set<String>]
    public var excludedProposalIDs: Set<String>

    public init(
        selectedFieldsByProposal: [String: Set<MetadataReviewField>] = [:],
        selectedImagesByProposal: [String: [String: String]] = [:],
        selectedTagsByProposal: [String: Set<String>] = [:],
        selectedCreditsByProposal: [String: Set<String>] = [:],
        excludedProposalIDs: Set<String> = []
    ) {
        self.selectedFieldsByProposal = selectedFieldsByProposal
        self.selectedImagesByProposal = selectedImagesByProposal
        self.selectedTagsByProposal = selectedTagsByProposal
        self.selectedCreditsByProposal = selectedCreditsByProposal
        self.excludedProposalIDs = excludedProposalIDs
    }
}
