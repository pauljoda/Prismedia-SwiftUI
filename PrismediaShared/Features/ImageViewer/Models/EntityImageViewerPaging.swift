import Foundation

struct EntityImageViewerPaging: Sendable {
    private let entityIDs: [UUID]

    init(entityIDs: [UUID]) {
        self.entityIDs = entityIDs
    }

    func destination(
        from entityID: UUID,
        direction: EntityImageViewerPagingDirection
    ) -> UUID? {
        guard let index = entityIDs.firstIndex(of: entityID) else { return nil }
        let destinationIndex =
            switch direction {
            case .previous: entityIDs.index(index, offsetBy: -1, limitedBy: entityIDs.startIndex)
            case .next: entityIDs.index(index, offsetBy: 1, limitedBy: entityIDs.endIndex)
            }
        guard let destinationIndex, entityIDs.indices.contains(destinationIndex) else { return nil }
        return entityIDs[destinationIndex]
    }
}
