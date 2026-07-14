import Foundation

/// A top-level product section. The flyout shows every destination, while the
/// compact rail uses up to four preferred destinations and always keeps the
/// currently selected destination visible.
public struct AppMode: Identifiable, Hashable, Sendable {
    public static let compactTabLimit = 4

    public let id: String
    public let title: String
    public let systemImage: String
    public let requiresAdmin: Bool
    public let destinations: [AppDestination]
    public let preferredTabDestinationIDs: [String]

    public init(
        id: String,
        title: String,
        systemImage: String,
        requiresAdmin: Bool = false,
        destinations: [AppDestination],
        preferredTabDestinationIDs: [String] = []
    ) {
        precondition(!destinations.isEmpty, "An app mode requires at least one destination.")

        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.requiresAdmin = requiresAdmin
        self.destinations = destinations
        self.preferredTabDestinationIDs = preferredTabDestinationIDs
    }

    public func tabDestinations(selectedDestinationID: String) -> [AppDestination] {
        let preferred = preferredTabDestinationIDs.compactMap(destination(id:))
        let candidates = preferred.isEmpty ? destinations : preferred
        let compact = Array(candidates.prefix(Self.compactTabLimit))

        guard
            let selected = destination(id: selectedDestinationID),
            !compact.contains(where: { $0.id == selected.id })
        else {
            return compact
        }

        return Array(compact.dropLast()) + [selected]
    }

    public func destination(id: String) -> AppDestination? {
        destinations.first { $0.id == id }
    }
}
