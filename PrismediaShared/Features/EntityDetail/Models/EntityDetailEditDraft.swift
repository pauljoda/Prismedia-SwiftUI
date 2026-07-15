import Foundation

struct EntityDetailEditDraft: Hashable, Sendable {
    var title: String
    var description: String
    var rating: Int?
    var isFavorite: Bool
    var isNsfw: Bool
    var isOrganized: Bool
    var tags: [EntityDetailReferenceDraft]
    var studio: EntityDetailReferenceDraft?
    var credits: [EntityDetailCreditDraft]
    var urls: [EntityDetailStringDraft]
    var externalIDs: [EntityDetailKeyValueDraft]
    var dates: [EntityDetailKeyValueDraft]
    var stats: [EntityDetailKeyValueDraft]
    var positions: [EntityDetailKeyValueDraft]
    var classification: String

    init(detail: EntityDetail) {
        let flags = detail.capability(EntityFlagsCapability.self)
        let links = detail.capability(EntityLinksCapability.self)
        let tagGroup = detail.relationships.first {
            $0.kind == .tag || $0.code == "tags"
        }
        let studioGroup = detail.relationships.first { $0.code == "studio" }
        let people = detail.relationships
            .filter { $0.kind == .person }
            .flatMap(\.entities)
            .reduce(into: [EntityThumbnail]()) { result, person in
                if !result.contains(where: { $0.id == person.id }) {
                    result.append(person)
                }
            }
        let peopleByID = Dictionary(uniqueKeysWithValues: people.map { ($0.id, $0) })

        title = detail.title
        description = detail.capability(EntityDescriptionCapability.self)?.value ?? ""
        rating = detail.capability(EntityRatingCapability.self)?.value
        isFavorite = flags?.isFavorite ?? false
        isNsfw = flags?.isNsfw ?? false
        isOrganized = flags?.isOrganized ?? false
        tags = tagGroup?.entities.map(EntityDetailReferenceDraft.init(thumbnail:)) ?? []
        studio = studioGroup?.entities.first.map(EntityDetailReferenceDraft.init(thumbnail:))
        let metadataCredits: [EntityDetailCreditDraft] = detail.creditMetadata.compactMap { credit in
            guard let person = peopleByID[credit.personID] else { return nil }
            let roles = credit.roles.isEmpty ? [credit.role].compactMap { $0 } : credit.roles
            let characters =
                credit.characters.isEmpty
                ? [credit.character].compactMap { $0 }
                : credit.characters
            return EntityDetailCreditDraft(
                person: EntityDetailReferenceDraft(thumbnail: person),
                roles: roles.isEmpty ? ["person"] : roles,
                character: characters.first ?? "",
                preservedCharacters: Array(characters.dropFirst())
            )
        }
        let creditedPersonIDs: Set<UUID> = Set(metadataCredits.compactMap { $0.person.entityID })
        let fallbackCredits: [EntityDetailCreditDraft] = people.compactMap { person in
            guard !creditedPersonIDs.contains(person.id) else { return nil }
            return EntityDetailCreditDraft(
                person: EntityDetailReferenceDraft(thumbnail: person),
                roles: [EntityDetailEditPolicy.defaultCreditRole(in: detail).rawValue]
            )
        }
        credits = metadataCredits + fallbackCredits
        urls = links?.urls.map { EntityDetailStringDraft(value: $0.value) } ?? []
        externalIDs =
            links?.externalIDs.map {
                EntityDetailKeyValueDraft(key: $0.provider, value: $0.value)
            } ?? []
        dates =
            detail.capability(EntityItemsCapability<EntityDate>.self)?.items.map {
                EntityDetailKeyValueDraft(key: $0.code, value: $0.value)
            } ?? []
        stats =
            detail.capability(EntityItemsCapability<EntityStat>.self)?.items.map {
                EntityDetailKeyValueDraft(key: $0.code, value: $0.value)
            } ?? []
        positions =
            detail.capability(EntityItemsCapability<EntityPosition>.self)?.items.map {
                EntityDetailKeyValueDraft(key: $0.code, value: String($0.value))
            } ?? []
        classification = detail.capability(EntityClassificationCapability.self)?.value ?? ""
    }
}
