import Foundation

public enum RequestCommitOutcomePolicy {
    public static func resolve(
        response: AdministrativeRequestCommitResponse,
        review: AdministrativeRequestReviewResponse
    ) -> RequestCommitResult {
        if let renditions = response.bookRenditions {
            let failed = renditions.filter { $0.error != nil }
            let bookID = renditions.compactMap { $0.item?.entityID }.first
            let started = renditions.filter { $0.item?.outcome == PrismediaContractCodes.RequestCommitOutcome.requested }
            let title = failed.isEmpty ? "Book Request Updated" : "Some Formats Need Attention"
            let message = failed.isEmpty
                ? started.isEmpty
                    ? "The selected formats are already owned or requested."
                    : "Started \(started.count) Book format request\(started.count == 1 ? "" : "s")."
                : failed.map { outcome in
                    let label = outcome.rendition == PrismediaContractCodes.BookRendition.audiobook
                        ? "Audiobook" : "Ebook"
                    return "\(label): \(outcome.error ?? "Could not request this format.")"
                }.joined(separator: " ")
            return RequestCommitResult(
                title: title,
                message: message,
                navigationIntent: bookID.map {
                    RequestEntityNavigationIntent(entityID: $0, entityKind: .book)
                }
            )
        }
        let requested = response.items.filter { $0.outcome == "requested" }
        if requested.count == 1, let item = requested.first, let entityID = item.entityID {
            let target = review.targets.first { target in
                "\(target.externalIdentity.namespace):\(target.externalIdentity.value)" == item.externalID
            }
            return RequestCommitResult(
                title: "Request Started",
                message: "\(item.title) is now being searched for.",
                navigationIntent: RequestEntityNavigationIntent(
                    entityID: entityID,
                    entityKind: target?.entityKind ?? review.entityKind
                )
            )
        }
        if !requested.isEmpty {
            return RequestCommitResult(
                title: "Requests Started",
                message: "Started \(requested.count) requests.",
                navigationIntent: response.containerEntityID.map {
                    RequestEntityNavigationIntent(entityID: $0, entityKind: review.entityKind)
                }
            )
        }
        if let containerID = response.containerEntityID {
            return RequestCommitResult(
                title: "Already Added",
                message: "This title is already available in your library.",
                navigationIntent: RequestEntityNavigationIntent(entityID: containerID, entityKind: review.entityKind)
            )
        }
        let allOwned = !response.items.isEmpty && response.items.allSatisfy { $0.outcome == "already-owned" }
        return RequestCommitResult(
            title: allOwned ? "Already in Library" : "Already Requested",
            message: allOwned
                ? "Everything selected is already in your library."
                : "The existing requests are still searching.",
            navigationIntent: nil
        )
    }
}
