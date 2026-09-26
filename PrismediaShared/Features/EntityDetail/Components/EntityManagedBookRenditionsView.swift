import SwiftUI

/// Shows the two independently managed formats of one canonical Book.
struct EntityManagedBookRenditionsView: View {
    let renditions: [EntityExternalBookRenditionProvenance]

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            Text("Connected book manager")
                .font(.headline)
                .foregroundStyle(PrismediaColor.textPrimary)
                .accessibilityAddTraits(.isHeader)

            ForEach(renditions.map(EntityManagedBookRenditionPresentation.init)) { item in
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.small) {
                        Text(formatName(item.provenance.rendition))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(PrismediaColor.textPrimary)
                        Spacer(minLength: PrismediaSpacing.small)
                        Text(statusName(item.state))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(PrismediaColor.textSecondary)
                    }

                    Text("\(item.provenance.connectionName) · \(item.provenance.libraryLabel)")
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)

                    if let problem = item.reviewProblem {
                        Text(problem)
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("entity-detail.managed-book.\(item.provenance.rendition.rawValue)")
            }
        }
        .padding(PrismediaSpacing.extraLarge)
        .prismediaCard()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatName(_ rendition: EntityBookRendition) -> String {
        if rendition == .audiobook { return "Audiobook" }
        if rendition == .ebook { return "Ebook" }
        return "Other format"
    }

    private func statusName(_ state: EntityManagedBookRenditionState) -> String {
        switch state {
        case .starting: "Starting"
        case .waitingForFiles: "Waiting for files"
        case .tracking: "Tracking"
        case .completed: "Completed"
        case .needsReview: "Needs review"
        case .releasing: "Releasing"
        case .released: "No longer managed"
        case .cancelled: "Cancelled"
        case .updating: "Updating"
        }
    }
}
