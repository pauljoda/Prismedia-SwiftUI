import Foundation

/// Adds and reads Prismedia's semantic paragraph anchor from a standard Readium locator JSON value.
enum EPUBParagraphLocator {
    private static let fragmentPrefix = "prismedia-paragraph="

    static func serialized(
        href: String,
        progression: Double,
        anchor: EPUBParagraphAnchor
    ) -> String? {
        let boundedProgression = min(max(progression, 0), 1)
        let locator: [String: Any] = [
            "href": href,
            "type": "application/xhtml+xml",
            "locations": ["progression": boundedProgression],
        ]
        guard let base = serialized(locator) else { return nil }
        return enriching(base, with: anchor)
    }

    static func enriching(_ serializedLocator: String, with anchor: EPUBParagraphAnchor) -> String? {
        guard var locator = object(from: serializedLocator) else { return nil }
        var locations = locator["locations"] as? [String: Any] ?? [:]
        var fragments = locations["fragments"] as? [String] ?? []
        fragments.removeAll { $0.hasPrefix(fragmentPrefix) }
        fragments.append("\(fragmentPrefix)\(anchor.index)")
        locations["fragments"] = fragments
        locator["locations"] = locations

        if let text = anchor.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            var locatorText = locator["text"] as? [String: Any] ?? [:]
            locatorText["highlight"] = text
            locator["text"] = locatorText
        }
        return serialized(locator)
    }

    static func anchor(from serializedLocator: String) -> EPUBParagraphAnchor? {
        guard let locator = object(from: serializedLocator),
            let locations = locator["locations"] as? [String: Any],
            let fragments = locations["fragments"] as? [String],
            let fragment = fragments.last(where: { $0.hasPrefix(fragmentPrefix) }),
            let index = Int(fragment.dropFirst(fragmentPrefix.count)),
            index >= 0
        else { return nil }
        let text = (locator["text"] as? [String: Any])?["highlight"] as? String
        return EPUBParagraphAnchor(index: index, text: text)
    }

    static func href(from serializedLocator: String) -> String? {
        object(from: serializedLocator)?["href"] as? String
    }

    static func removingAnchor(from serializedLocator: String) -> String? {
        guard var locator = object(from: serializedLocator) else { return nil }
        guard var locations = locator["locations"] as? [String: Any] else {
            return serializedLocator
        }
        let fragments = (locations["fragments"] as? [String] ?? []).filter {
            !$0.hasPrefix(fragmentPrefix)
        }
        if fragments.isEmpty {
            locations.removeValue(forKey: "fragments")
        } else {
            locations["fragments"] = fragments
        }
        locator["locations"] = locations
        return serialized(locator)
    }

    private static func object(from value: String) -> [String: Any]? {
        guard let data = value.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return object
    }

    private static func serialized(_ object: [String: Any]) -> String? {
        guard JSONSerialization.isValidJSONObject(object),
            let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
