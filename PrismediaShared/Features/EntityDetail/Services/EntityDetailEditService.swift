import Foundation

@MainActor
struct EntityDetailEditService {
    private let metadataMutator: any EntityMetadataMutating
    private let userMetadataMutator: (any EntityDetailMutating)?

    init(
        metadataMutator: any EntityMetadataMutating,
        userMetadataMutator: (any EntityDetailMutating)?
    ) {
        self.metadataMutator = metadataMutator
        self.userMetadataMutator = userMetadataMutator
    }

    func save(
        draft: EntityDetailEditDraft,
        original: EntityDetailEditDraft,
        detail: EntityDetail
    ) async -> EntityDetailEditOutcome {
        var savedPartialChanges = false
        for section in EntityDetailEditSection.allCases
        where hasChanges(
            in: section,
            draft: draft,
            original: original
        ) {
            do {
                let request = try metadataRequest(
                    draft: draft,
                    detail: detail,
                    section: section
                )
                _ = try await metadataMutator.updateMetadata(
                    id: detail.id,
                    kind: detail.kind,
                    request: request
                )
                savedPartialChanges = true
            } catch {
                return .failed(
                    message: error.localizedDescription,
                    savedPartialChanges: savedPartialChanges
                )
            }
        }

        guard hasMainChanges(draft: draft, original: original), let userMetadataMutator else {
            return .saved
        }

        do {
            if draft.rating != original.rating {
                _ = try await userMetadataMutator.updateRating(
                    id: detail.id,
                    value: draft.rating
                )
            }

            if draft.isFavorite != original.isFavorite
                || draft.isNsfw != original.isNsfw
                || draft.isOrganized != original.isOrganized
            {
                _ = try await userMetadataMutator.updateFlags(
                    id: detail.id,
                    isFavorite: draft.isFavorite,
                    isNsfw: draft.isNsfw,
                    isOrganized: draft.isOrganized
                )
            }
            return .saved
        } catch {
            return .failed(
                message:
                    "Some entity details were saved, but user metadata could not be updated: \(error.localizedDescription)",
                savedPartialChanges: savedPartialChanges
            )
        }
    }

    func metadataRequest(
        draft: EntityDetailEditDraft,
        detail: EntityDetail,
        section: EntityDetailEditSection
    ) throws -> EntityDetailMetadataUpdateRequest {
        switch section {
        case .main:
            return try mainRequest(draft: draft, detail: detail)
        case .metadata:
            return try metadataRequest(draft: draft)
        }
    }

    private func mainRequest(
        draft: EntityDetailEditDraft,
        detail: EntityDetail
    ) throws -> EntityDetailMetadataUpdateRequest {
        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw EntityDetailEditValidationError.emptyTitle }
        if let rating = draft.rating, !(0...5).contains(rating) {
            throw EntityDetailEditValidationError.invalidRating
        }

        var fields = ["title", "description"]
        var tags: [String] = []
        var studio: String?
        var credits: [EntityDetailCreditPatch] = []

        if EntityDetailEditPolicy.canEditTags(in: detail) {
            fields.append("tags")
            tags = uniqueValues(draft.tags.map(\.title))
        }
        if EntityDetailEditPolicy.canEditStudio(in: detail) {
            fields.append("studio")
            studio = draft.studio.flatMap { nonempty($0.title) }
        }
        if EntityDetailEditPolicy.canEditCredits(in: detail) {
            fields.append("credits")
            credits = creditPatches(draft.credits)
        }

        return EntityDetailMetadataUpdateRequest(
            fields: fields,
            patch: EntityDetailMetadataPatch(
                title: title,
                description: nonempty(draft.description),
                tags: tags,
                studio: studio,
                credits: credits
            )
        )
    }

    private func metadataRequest(
        draft: EntityDetailEditDraft
    ) throws -> EntityDetailMetadataUpdateRequest {
        let urls = try draft.urls.compactMap { item -> String? in
            guard let value = nonempty(item.value) else { return nil }
            guard let url = URL(string: value),
                let scheme = url.scheme?.lowercased(),
                ["http", "https"].contains(scheme),
                url.host != nil
            else { throw EntityDetailEditValidationError.invalidURL(value) }
            return value
        }

        return EntityDetailMetadataUpdateRequest(
            fields: ["urls", "externalIds", "dates", "stats", "positions", "classification"],
            patch: EntityDetailMetadataPatch(
                externalIDs: keyValueRecord(draft.externalIDs),
                urls: uniqueValues(urls),
                dates: keyValueRecord(draft.dates),
                stats: try integerRecord(draft.stats, section: "Stats"),
                positions: try integerRecord(draft.positions, section: "Positions"),
                classification: nonempty(draft.classification)
            )
        )
    }

    private func creditPatches(
        _ drafts: [EntityDetailCreditDraft]
    ) -> [EntityDetailCreditPatch] {
        drafts.enumerated().flatMap { index, draft -> [EntityDetailCreditPatch] in
            guard let name = nonempty(draft.person.title) else { return [] }
            let roles = uniqueValues(draft.roles)
            let effectiveRoles = roles.isEmpty ? ["person"] : roles
            let character = nonempty(draft.character)
            var rows = effectiveRoles.enumerated().map { roleIndex, role in
                EntityDetailCreditPatch(
                    name: name,
                    role: role,
                    character: roleIndex == 0 ? character : nil,
                    sortOrder: index
                )
            }
            for preserved in uniqueValues(draft.preservedCharacters) {
                guard preserved.caseInsensitiveCompare(character ?? "") != .orderedSame else { continue }
                rows.append(
                    EntityDetailCreditPatch(
                        name: name,
                        role: effectiveRoles[0],
                        character: preserved,
                        sortOrder: index
                    )
                )
            }
            return rows
        }
    }

    private func keyValueRecord(
        _ drafts: [EntityDetailKeyValueDraft]
    ) -> [String: String] {
        drafts.reduce(into: [:]) { result, draft in
            guard let key = nonempty(draft.key), let value = nonempty(draft.value) else { return }
            result[key] = value
        }
    }

    private func integerRecord(
        _ drafts: [EntityDetailKeyValueDraft],
        section: String
    ) throws -> [String: Int] {
        try drafts.reduce(into: [:]) { result, draft in
            guard let key = nonempty(draft.key), let value = nonempty(draft.value) else { return }
            guard let number = Int(value) else {
                throw EntityDetailEditValidationError.invalidNumber(section: section, key: key)
            }
            result[key] = number
        }
    }

    private func nonempty(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func uniqueValues(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { value in
            guard !value.isEmpty else { return false }
            return seen.insert(value.lowercased()).inserted
        }
    }

    private func hasChanges(
        in section: EntityDetailEditSection,
        draft: EntityDetailEditDraft,
        original: EntityDetailEditDraft
    ) -> Bool {
        switch section {
        case .main:
            hasMainChanges(draft: draft, original: original)
        case .metadata:
            draft.urls != original.urls
                || draft.externalIDs != original.externalIDs
                || draft.dates != original.dates
                || draft.stats != original.stats
                || draft.positions != original.positions
                || draft.classification != original.classification
        }
    }

    private func hasMainChanges(
        draft: EntityDetailEditDraft,
        original: EntityDetailEditDraft
    ) -> Bool {
        draft.title != original.title
            || draft.description != original.description
            || draft.rating != original.rating
            || draft.isFavorite != original.isFavorite
            || draft.isNsfw != original.isNsfw
            || draft.isOrganized != original.isOrganized
            || draft.tags != original.tags
            || draft.studio != original.studio
            || draft.credits != original.credits
    }
}
