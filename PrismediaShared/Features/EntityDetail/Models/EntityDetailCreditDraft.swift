import Foundation

struct EntityDetailCreditDraft: Identifiable, Hashable, Sendable {
    let id: UUID
    var person: EntityDetailReferenceDraft
    var roles: [String]
    var character: String
    var preservedCharacters: [String]

    init(
        id: UUID = UUID(),
        person: EntityDetailReferenceDraft,
        roles: [String] = ["person"],
        character: String = "",
        preservedCharacters: [String] = []
    ) {
        self.id = id
        self.person = person
        self.roles = roles
        self.character = character
        self.preservedCharacters = preservedCharacters
    }
}
