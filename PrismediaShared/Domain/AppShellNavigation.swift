import Foundation

/// Keeps section and destination selection valid as the shell adapts, and
/// remembers the last destination used in each section.
public struct AppShellNavigation: Equatable, Sendable {
    private struct Selection: Equatable, Sendable {
        let modeID: String
        let destinationID: String
    }

    private var selection: Selection
    private var lastDestinationByMode: [String: String]

    public var modeID: String { selection.modeID }
    public var destinationID: String { selection.destinationID }

    public init(mode: AppMode, destinationID: String? = nil) {
        let destination = mode.destination(id: destinationID ?? "") ?? mode.destinations[0]
        selection = Selection(modeID: mode.id, destinationID: destination.id)
        lastDestinationByMode = [mode.id: destination.id]
    }

    public mutating func select(mode: AppMode) {
        let rememberedID = lastDestinationByMode[mode.id]
        let destination = mode.destination(id: rememberedID ?? "") ?? mode.destinations[0]
        apply(mode: mode, destination: destination)
    }

    public mutating func select(mode: AppMode, destination: AppDestination) {
        guard let validDestination = mode.destination(id: destination.id) else {
            select(mode: mode)
            return
        }

        apply(mode: mode, destination: validDestination)
    }

    public mutating func select(destinationID: String, in mode: AppMode) {
        guard let destination = mode.destination(id: destinationID) else { return }
        apply(mode: mode, destination: destination)
    }

    public mutating func reconcile(with modes: [AppMode]) {
        guard let mode = modes.first(where: { $0.id == modeID }) else {
            guard let fallback = modes.first else { return }
            select(mode: fallback)
            return
        }

        guard let destination = mode.destination(id: destinationID) else {
            select(mode: mode)
            return
        }

        apply(mode: mode, destination: destination)
    }

    private mutating func apply(mode: AppMode, destination: AppDestination) {
        selection = Selection(modeID: mode.id, destinationID: destination.id)
        lastDestinationByMode[mode.id] = destination.id
    }
}
