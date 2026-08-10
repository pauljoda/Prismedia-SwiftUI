import Foundation

#if os(iOS) || os(macOS)
    enum PluginCandidateThumbnailPolicy {
        static func thumbnail(
            for candidate: AdministrativeEntitySearchCandidate,
            entityKind: String
        ) -> EntityThumbnail {
            EntityThumbnail(
                id: EntityThumbnailPresentationIdentity.id(
                    namespace: "plugin-candidate",
                    value: candidate.pluginSearchIdentity.rawValue
                ),
                kind: EntityKind(rawValue: entityKind),
                title: candidate.title,
                subtitle: candidate.year.map { $0.formatted(.number.grouping(.never)) },
                summary: candidate.overview,
                coverURL: ProviderImagePreviewPolicy.previewURL(
                    for: candidate.posterURL,
                    targetKind: entityKind
                )
            )
        }
    }
#endif
