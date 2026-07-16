import Foundation

public struct EntityGridSelectionState: Equatable, Sendable {
    public private(set) var isActive = false
    public private(set) var selectedIDs = Set<UUID>()

    public init() {}

    public mutating func enter() {
        isActive = true
    }

    public mutating func exit() {
        isActive = false
        selectedIDs.removeAll()
    }

    public mutating func toggle(_ entityID: UUID) {
        guard isActive else { return }
        if !selectedIDs.insert(entityID).inserted {
            selectedIDs.remove(entityID)
        }
    }

    public mutating func selectAllVisible<S: Sequence>(_ entityIDs: S) where S.Element == UUID {
        guard isActive else { return }
        selectedIDs.formUnion(entityIDs)
    }

    public mutating func clear() {
        selectedIDs.removeAll()
    }

    public mutating func remove(_ entityIDs: Set<UUID>) {
        selectedIDs.subtract(entityIDs)
    }

    public mutating func reconcile(withAvailableIDs availableIDs: Set<UUID>) {
        selectedIDs.formIntersection(availableIDs)
    }
}
