import Foundation

#if os(iOS) || os(macOS)
    extension AdministrativeRequestSearchResult {
        var pluginCandidate: AdministrativeEntitySearchCandidate {
            let identityValues = externalIdentity.map { [$0.namespace: $0.value] } ?? [:]
            return AdministrativeEntitySearchCandidate(
                externalIDs: identityValues,
                title: title,
                year: year,
                overview: overview,
                posterURL: posterURL,
                popularity: rating,
                candidateID: externalID,
                source: pluginID ?? source,
                confidence: nil,
                matchReason: subtitle
            )
        }
    }
#endif
