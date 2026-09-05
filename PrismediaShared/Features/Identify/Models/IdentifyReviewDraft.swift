import Foundation

/// In-session review choices and the proposal version they were made against.
struct IdentifyReviewDraft: Equatable, Sendable {
    let proposal: AdministrativeEntityMetadataProposal
    let selection: MetadataReviewSelection

    /// Retains choices for the same proposal while including newly streamed metadata.
    /// A replacement match starts a fresh review rather than inheriting another match's choices.
    func selection(for updated: AdministrativeEntityMetadataProposal) -> MetadataReviewSelection {
        guard proposal.proposalID == updated.proposalID else {
            return MetadataReviewPolicy.seededSelection(for: updated)
        }
        return MetadataReviewPolicy.mergingSeededDefaults(
            from: proposal, to: updated, into: selection
        )
    }
}
