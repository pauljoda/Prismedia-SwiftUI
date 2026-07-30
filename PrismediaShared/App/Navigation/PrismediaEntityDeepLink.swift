import Foundation

public enum PrismediaEntityDeepLink {
    public static func link(from url: URL) -> EntityLink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        let scheme = components.scheme?.lowercased()
        guard scheme == "prismedia" || scheme == "https" || scheme == "http" else {
            return nil
        }

        if let queryLink = queryLink(from: components) {
            return queryLink
        }

        var segments = components.path.split(separator: "/").map(String.init)
        if scheme == "prismedia", let host = components.host, !host.isEmpty {
            segments.insert(host, at: 0)
        }
        if segments.first?.lowercased() == "entity" || segments.first?.lowercased() == "entities" {
            segments.removeFirst()
        }
        if let routeLink = detailLink(from: segments, components: components) {
            return routeLink
        }

        guard segments.count == 2,
              let kind = knownKind(for: segments[0]),
              let entityID = UUID(uuidString: segments[1])
        else { return nil }

        return EntityLink(entityID: entityID, kind: kind, intent: intent(from: components))
    }

    private static func queryLink(from components: URLComponents) -> EntityLink? {
        let values = (components.queryItems ?? []).reduce(into: [String: String]()) {
            $0[$1.name.lowercased()] = $1.value ?? ""
        }
        guard let kindValue = values["kind"],
            let kind = knownKind(for: kindValue),
            let idValue = values["id"] ?? values["entityid"],
            let entityID = UUID(uuidString: idValue)
        else { return nil }
        return EntityLink(entityID: entityID, kind: kind, intent: intent(from: components))
    }

    private static func intent(from components: URLComponents) -> EntityNavigationIntent {
        let value = components.queryItems?
            .first { $0.name.lowercased() == "intent" }?
            .value?
            .lowercased()
        switch value {
        case "playback", "play": return .playback
        case "audio-collection", "audiocollection": return .audioCollection
        default: return .detail
        }
    }

    private static func detailLink(
        from segments: [String],
        components: URLComponents
    ) -> EntityLink? {
        for matcher in canonicalDetailMatchers {
            if let link = match(
                segments,
                kind: matcher.kind,
                navigation: matcher.navigation,
                templateSegments: matcher.templateSegments,
                components: components
            ) {
                return link
            }
        }

        for alias in legacyDetailAliases {
            if let link = match(
                segments,
                kind: alias.kind,
                navigation: nil,
                templateSegments: alias.templateSegments,
                components: components
            ) {
                return link
            }
        }
        return nil
    }

    private static func knownKind(for rawValue: String) -> EntityKind? {
        generatedEntityKindDefinitions[EntityKind(rawValue: rawValue.lowercased())]?.kind
    }

    private static func match(
        _ routeSegments: [String],
        kind: EntityKind,
        navigation: EntityKindNavigation?,
        templateSegments: [String],
        components: URLComponents
    ) -> EntityLink? {
        guard routeSegments.count == templateSegments.count else { return nil }

        var identifiers: [String: UUID] = [:]
        for (routeSegment, templateSegment) in zip(routeSegments, templateSegments) {
            if templateSegment.first == "{", templateSegment.last == "}" {
                let name = String(templateSegment.dropFirst().dropLast())
                guard let identifier = UUID(uuidString: routeSegment) else { return nil }
                identifiers[name] = identifier
            } else if routeSegment.caseInsensitiveCompare(templateSegment) != .orderedSame {
                return nil
            }
        }

        guard let entityID = identifiers["id"] else { return nil }
        let parentEntityID = identifiers["parentId"]
        return EntityLink(
            entityID: entityID,
            kind: kind,
            parentEntityID: parentEntityID,
            parentKind: parentEntityID == nil ? nil : navigation?.requiredAncestorKind,
            intent: intent(from: components)
        )
    }

    private static let canonicalDetailMatchers: [(
        kind: EntityKind,
        navigation: EntityKindNavigation,
        templateSegments: [String]
    )] = generatedEntityKindDefinitions.values.compactMap { definition in
        guard let navigation = definition.navigation,
              let template = navigation.detailPathTemplate
        else { return nil }
        return (
            kind: definition.kind,
            navigation: navigation,
            templateSegments: template.split(separator: "/").map(String.init)
        )
    }
    .sorted {
        $0.templateSegments.count == $1.templateSegments.count
            ? $0.kind.rawValue < $1.kind.rawValue
            : $0.templateSegments.count > $1.templateSegments.count
    }

    /// Legacy aliases retained for links emitted by pre-template native builds.
    private static let legacyDetailAliases: [(kind: EntityKind, templateSegments: [String])] = [
        (.audioLibrary, ["album", "{id}"]),
        (.audioLibrary, ["albums", "{id}"]),
        (.audioTrack, ["track", "{id}"]),
        (.audioTrack, ["tracks", "{id}"]),
    ]
}
