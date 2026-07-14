import Foundation

#if os(iOS) || os(macOS)
    struct PluginSearchCandidateIdentity: Hashable, Sendable {
        let rawValue: String

        init(candidate: AdministrativeEntitySearchCandidate) {
            let source = candidate.source?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if let candidateID = candidate.candidateID?.trimmingCharacters(in: .whitespacesAndNewlines),
                !candidateID.isEmpty
            {
                rawValue = "candidate|\(source)|\(candidateID)"
                return
            }

            if !candidate.externalIDs.isEmpty {
                let identities = candidate.externalIDs
                    .sorted { $0.key < $1.key }
                    .map { "\($0.key)=\($0.value)" }
                    .joined(separator: "&")
                rawValue = "external|\(source)|\(identities)"
                return
            }

            rawValue = [
                "fallback",
                source,
                candidate.title,
                candidate.year.map(String.init) ?? "",
                candidate.posterURL ?? "",
            ].joined(separator: "|")
        }
    }

    extension AdministrativeEntitySearchCandidate {
        var pluginSearchIdentity: PluginSearchCandidateIdentity {
            PluginSearchCandidateIdentity(candidate: self)
        }
    }
#endif
