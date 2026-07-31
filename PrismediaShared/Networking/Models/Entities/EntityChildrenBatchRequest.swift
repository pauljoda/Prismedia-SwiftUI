import Foundation

struct EntityChildrenBatchRequest: Encodable {
    let parentIds: [UUID]
}
