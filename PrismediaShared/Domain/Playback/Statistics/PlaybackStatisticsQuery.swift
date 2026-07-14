import Foundation

public struct PlaybackStatisticsQuery: Hashable, Sendable {
    public let from: Date
    public let to: Date
    public let kind: EntityKind?
    public let eventKind: PlaybackEventKind?
    public var hideNsfw: Bool

    public init(
        from: Date,
        to: Date,
        kind: EntityKind? = nil,
        eventKind: PlaybackEventKind? = nil,
        hideNsfw: Bool = true
    ) {
        self.from = from
        self.to = to
        self.kind = kind
        self.eventKind = eventKind
        self.hideNsfw = hideNsfw
    }

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "from", value: Self.formatter.string(from: from)),
            URLQueryItem(name: "to", value: Self.formatter.string(from: to)),
            URLQueryItem(name: "hideNsfw", value: hideNsfw ? "true" : "false"),
        ]
        if let kind { items.append(URLQueryItem(name: "kind", value: kind.rawValue)) }
        if let eventKind { items.append(URLQueryItem(name: "eventKind", value: eventKind.rawValue)) }
        return items
    }

    nonisolated(unsafe) private static let formatter = ISO8601DateFormatter()
}
