import Foundation

public enum MetadataReviewPolicy {
    public static func seededSelection(
        for proposal: AdministrativeEntityMetadataProposal
    ) -> MetadataReviewSelection {
        var selection = MetadataReviewSelection()
        walk(proposal) { node in
            selection.selectedFieldsByProposal[node.proposalID] = Set(
                MetadataReviewField.allCases.filter { !fieldValue($0, in: node).isEmpty }
            )
            selection.selectedImagesByProposal[node.proposalID] = defaultImages(for: node)
            selection.selectedTagsByProposal[node.proposalID] = Set(node.patch.tags)
            selection.selectedCreditsByProposal[node.proposalID] = Set(
                node.patch.credits.enumerated().map { creditKey($0.element, index: $0.offset) }
            )
        }
        return selection
    }

    public static func structuralChildren(
        of proposal: AdministrativeEntityMetadataProposal
    ) -> [AdministrativeEntityMetadataProposal] {
        unique(proposal.children.filter { !isRelationshipKind($0.targetKind) })
    }

    public static func relationships(
        of proposal: AdministrativeEntityMetadataProposal
    ) -> [AdministrativeEntityMetadataProposal] {
        unique(
            proposal.relationships
                + proposal.children.filter { isRelationshipKind($0.targetKind) }
        )
    }

    public static func proposal(
        withID proposalID: String,
        in root: AdministrativeEntityMetadataProposal
    ) -> AdministrativeEntityMetadataProposal? {
        if root.proposalID == proposalID { return root }
        for node in structuralChildren(of: root) + relationships(of: root) {
            if let match = proposal(withID: proposalID, in: node) { return match }
        }
        return nil
    }

    public static func fieldValue(
        _ field: MetadataReviewField,
        in proposal: AdministrativeEntityMetadataProposal
    ) -> String {
        let patch = proposal.patch
        switch field {
        case .title:
            return patch.title ?? ""
        case .description:
            return patch.description ?? ""
        case .externalIDs:
            return entries(patch.externalIDs)
        case .urls:
            return patch.urls.joined(separator: ", ")
        case .tags:
            return patch.tags.joined(separator: ", ")
        case .studio:
            return patch.studio ?? ""
        case .credits:
            return patch.credits.map { credit in
                guard let character = credit.character, !character.isEmpty else { return credit.name }
                return "\(credit.name) as \(character)"
            }.joined(separator: ", ")
        case .dates:
            return entries(patch.dates)
        case .stats:
            return entries(patch.stats)
        case .positions:
            return entries(patch.positions)
        case .classification:
            return patch.classification ?? ""
        case .images:
            return proposal.images.isEmpty ? "" : "\(proposal.images.count) available"
        }
    }

    public static func proposalForApply(
        _ proposal: AdministrativeEntityMetadataProposal,
        selection: MetadataReviewSelection
    ) -> AdministrativeEntityMetadataProposal {
        let selectedFields =
            selection.selectedFieldsByProposal[proposal.proposalID]
            ?? Set(MetadataReviewField.allCases)
        let selectedTagValues =
            selection.selectedTagsByProposal[proposal.proposalID]
            ?? Set(proposal.patch.tags)
        let selectedCreditValues =
            selection.selectedCreditsByProposal[proposal.proposalID]
            ?? Set(
                proposal.patch.credits.enumerated().map { creditKey($0.element, index: $0.offset) }
            )
        let selectedImages = selection.selectedImagesByProposal[proposal.proposalID]
        let appliedTags =
            selectedFields.contains(.tags)
            ? proposal.patch.tags.filter(selectedTagValues.contains)
            : []
        let appliedCredits =
            selectedFields.contains(.credits)
            ? proposal.patch.credits.enumerated().compactMap { index, credit in
                selectedCreditValues.contains(creditKey(credit, index: index)) ? credit : nil
            }
            : []
        let appliedPatch = AdministrativeEntityMetadataPatch(
            title: selectedFields.contains(.title) ? proposal.patch.title : nil,
            description: selectedFields.contains(.description) ? proposal.patch.description : nil,
            externalIDs: selectedFields.contains(.externalIDs) ? proposal.patch.externalIDs : [:],
            urls: selectedFields.contains(.urls) ? proposal.patch.urls : [],
            tags: appliedTags,
            studio: selectedFields.contains(.studio) ? proposal.patch.studio : nil,
            credits: appliedCredits,
            dates: selectedFields.contains(.dates) ? proposal.patch.dates : [:],
            stats: selectedFields.contains(.stats) ? proposal.patch.stats : [:],
            positions: selectedFields.contains(.positions) ? proposal.patch.positions : [:],
            classification: selectedFields.contains(.classification)
                ? proposal.patch.classification
                : nil,
            rating: proposal.patch.rating,
            flags: proposal.patch.flags
        )
        let includedChildren = structuralChildren(of: proposal)
            .filter { !selection.excludedProposalIDs.contains($0.proposalID) }
            .map { proposalForApply($0, selection: selection) }
        let includedRelationships = relationships(of: proposal)
            .filter { !selection.excludedProposalIDs.contains($0.proposalID) }
            .filter { relationshipIsSelected($0, selectedFields: selectedFields, patch: appliedPatch) }
            .map { proposalForApply($0, selection: selection) }

        return AdministrativeEntityMetadataProposal(
            proposalID: proposal.proposalID,
            provider: proposal.provider,
            targetKind: proposal.targetKind,
            confidence: proposal.confidence,
            matchReason: proposal.matchReason,
            patch: appliedPatch,
            images: selectedFields.contains(.images)
                ? proposal.images.filter { image in
                    guard let selectedImages else { return true }
                    return selectedImages[image.kind] == image.url
                }
                : [],
            children: includedChildren,
            candidates: proposal.candidates,
            targetEntityID: proposal.targetEntityID,
            relationships: includedRelationships
        )
    }

    public static func selectedRootFields(
        for proposal: AdministrativeEntityMetadataProposal,
        selection: MetadataReviewSelection
    ) -> [String] {
        MetadataReviewField.allCases.compactMap { field in
            selection.selectedFieldsByProposal[proposal.proposalID]?.contains(field) == true
                ? field.rawValue
                : nil
        }
    }

    public static func selectedRootImages(
        for proposal: AdministrativeEntityMetadataProposal,
        selection: MetadataReviewSelection
    ) -> [String: String] {
        selection.selectedImagesByProposal[proposal.proposalID] ?? [:]
    }

    public static func creditKey(
        _ credit: AdministrativeCreditPatch,
        index: Int
    ) -> String {
        [credit.name, credit.role, credit.character ?? "", String(index)]
            .joined(separator: "|")
    }

    private static func defaultImages(
        for proposal: AdministrativeEntityMetadataProposal
    ) -> [String: String] {
        proposal.images.reduce(into: [:]) { selected, image in
            guard selected[image.kind] == nil else { return }
            guard image.kind.lowercased() != "logo" || proposal.targetKind.lowercased() == "studio" else {
                return
            }
            selected[image.kind] = image.url
        }
    }

    private static func isRelationshipKind(_ kind: String) -> Bool {
        ["person", "studio", "tag"].contains(kind.lowercased())
    }

    private static func unique(
        _ proposals: [AdministrativeEntityMetadataProposal]
    ) -> [AdministrativeEntityMetadataProposal] {
        var seen = Set<String>()
        return proposals.filter { seen.insert($0.proposalID).inserted }
    }

    private static func walk(
        _ proposal: AdministrativeEntityMetadataProposal,
        visit: (AdministrativeEntityMetadataProposal) -> Void
    ) {
        visit(proposal)
        for child in structuralChildren(of: proposal) {
            walk(child, visit: visit)
        }
        for relationship in relationships(of: proposal) {
            walk(relationship, visit: visit)
        }
    }

    private static func relationshipIsSelected(
        _ relationship: AdministrativeEntityMetadataProposal,
        selectedFields: Set<MetadataReviewField>,
        patch: AdministrativeEntityMetadataPatch
    ) -> Bool {
        switch relationship.targetKind.lowercased() {
        case "person":
            return selectedFields.contains(.credits)
                && patch.credits.contains {
                    $0.name.caseInsensitiveCompare(relationship.patch.title ?? "") == .orderedSame
                }
        case "studio":
            return selectedFields.contains(.studio)
                && patch.studio?.caseInsensitiveCompare(relationship.patch.title ?? "") == .orderedSame
        case "tag":
            return selectedFields.contains(.tags)
        default:
            return true
        }
    }

    private static func entries<T>(_ values: [String: T]) -> String {
        values.keys.sorted().map { "\($0): \(values[$0]!)" }.joined(separator: ", ")
    }
}
