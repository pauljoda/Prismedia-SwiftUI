import Foundation

public enum RequestCandidatePolicy {
    public static func route(
        for result: AdministrativeRequestSearchResult,
        kind: RequestKindDefinition
    ) -> RequestReviewRoute? {
        guard let pluginID = result.pluginID?.trimmingCharacters(in: .whitespacesAndNewlines),
            !pluginID.isEmpty,
            let identity = result.externalIdentity,
            !identity.namespace.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !identity.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }
        return RequestReviewRoute(kind: kind, pluginID: pluginID, externalIdentity: identity)
    }
}
