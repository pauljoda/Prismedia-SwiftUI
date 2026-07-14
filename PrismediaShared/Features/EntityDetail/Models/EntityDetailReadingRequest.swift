import Foundation

struct EntityDetailReadingRequest: Hashable, Sendable {
    let entityID: UUID
    let generation: Int
}
