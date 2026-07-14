import Foundation

public enum RequestSelectionPolicy {
    public static func derive(from review: AdministrativeRequestReviewResponse) -> RequestReviewSelection {
        let definition = RequestKindDefinition(rawValue: review.kind)
        var seen = Set<String>()
        let directChildren = MetadataReviewPolicy.structuralChildren(of: review.proposal)
            .filter { seen.insert($0.proposalID).inserted }
        let targetsByID = Dictionary(uniqueKeysWithValues: review.targets.map { ($0.proposalID, $0) })
        let directTargets = directChildren.compactMap { targetsByID[$0.proposalID] }
        let configuredMode = definition?.reviewSelection ?? .root
        let mode: RequestReviewSelectionMode =
            configuredMode == .directChildren
                || (configuredMode == .directChildrenWhenPresent && !directChildren.isEmpty)
            ? .directChildren : .root
        let selectableIDs = Set(directTargets.filter(\.requestable).map(\.proposalID))
        let rootTarget = targetsByID[review.proposal.proposalID]
        let rootSelection: Set<String> =
            mode == .root && rootTarget?.requestable == true ? [review.proposal.proposalID] : []

        return RequestReviewSelection(
            mode: mode,
            selectableIDs: selectableIDs,
            rootSelection: rootSelection,
            children: directTargets
        )
    }
}
