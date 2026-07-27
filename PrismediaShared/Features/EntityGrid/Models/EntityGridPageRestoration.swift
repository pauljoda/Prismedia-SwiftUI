import Foundation

struct EntityGridPageRestoration: Sendable {
    let snapshot: EntityGridSnapshot
    let scrollTargetID: UUID?
    let focusedItemID: UUID?
}
