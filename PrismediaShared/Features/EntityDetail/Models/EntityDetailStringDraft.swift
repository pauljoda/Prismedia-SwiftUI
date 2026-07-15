import Foundation

struct EntityDetailStringDraft: Identifiable, Hashable, Sendable {
    let id: UUID
    var value: String

    init(id: UUID = UUID(), value: String = "") {
        self.id = id
        self.value = value
    }
}
