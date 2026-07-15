import Foundation

struct EntityDetailEditPresentation: Identifiable, Hashable, Sendable {
    let detail: EntityDetail

    var id: UUID { detail.id }
}
