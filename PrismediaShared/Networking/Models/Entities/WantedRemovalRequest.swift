import Foundation

struct WantedRemovalRequest: Encodable, Sendable {
    let entityIds: [UUID]
}
