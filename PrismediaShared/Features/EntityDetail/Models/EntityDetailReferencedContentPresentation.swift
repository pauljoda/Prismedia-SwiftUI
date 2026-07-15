import Foundation

struct EntityDetailReferencedContentPresentation: Hashable, Sendable {
    let title: String
    let query: EntityListQuery
    let preferencesID: String

    init?(detail: EntityDetail) {
        let relationshipCode: String
        switch detail.kind {
        case .tag:
            title = "Tagged Content"
            relationshipCode = "tags"
        case .person:
            title = "Appearances"
            relationshipCode = "cast"
        case .studio:
            title = "Content"
            relationshipCode = "studio"
        default:
            return nil
        }

        query = EntityListQuery(
            sort: "title",
            sortDescending: false,
            referencedBy: detail.id,
            relationshipCode: relationshipCode
        )
        preferencesID = "entity-detail:\(detail.kind.rawValue):\(detail.id.uuidString.lowercased()):references"
    }
}
