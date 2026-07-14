import SwiftUI

/// A dense, fully wrapping collection of entity tags.
public struct EntityTags: View {
    private let tags: [EntityThumbnail]
    private let title: String

    public init(tags: [EntityThumbnail], title: String = "Tags") {
        self.tags = tags
        self.title = title
    }

    public var body: some View {
        let metrics = EntityTagsMetrics.dense

        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(PrismediaTypography.subsectionTitle)
                    .foregroundStyle(PrismediaColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text(String(tags.count))
                    .font(PrismediaTypography.numericCaption)
                    .foregroundStyle(PrismediaColor.textMuted)
            }

            EntityTagsFlowLayout(
                horizontalSpacing: metrics.horizontalSpacing,
                verticalSpacing: metrics.verticalSpacing
            ) {
                ForEach(tags) { tag in
                    NavigationLink(value: EntityLink(thumbnail: tag)) {
                        Label(tag.title, systemImage: "tag.fill")
                            .font(PrismediaTypography.captionEmphasized)
                            .foregroundStyle(PrismediaColor.textSecondary)
                            .lineLimit(1)
                            .padding(.horizontal, metrics.horizontalPadding)
                            .padding(.vertical, metrics.verticalPadding)
                            .background(PrismediaColor.controlFill.opacity(0.82))
                            .overlay {
                                Capsule().stroke(PrismediaColor.border, lineWidth: PrismediaLayout.hairline)
                            }
                            .clipShape(Capsule())
                    }
                    .prismediaEntityNavigationButtonStyle()
                    .accessibilityIdentifier("entity-tags.\(tag.id.uuidString)")
                    .accessibilityHint("Opens tag details")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .prismediaFocusSection()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
        .accessibilityIdentifier("entity-tags")
    }
}

#if DEBUG
    #Preview("Entity Tags") {
        let titles = [
            "Science Fiction",
            "Space Opera",
            "Found Family",
            "Adventure",
            "Long Form",
            "Award Winner",
        ]
        let tags = titles.enumerated().map { index, title in
            EntityThumbnail(
                id: UUID(uuidString: "00000000-0000-0000-0000-0000000000\(String(format: "%02d", index + 1))")!,
                kind: .tag,
                title: title
            )
        }

        PreviewShell {
            NavigationStack {
                EntityTags(tags: tags)
                    .padding(PrismediaSpacing.extraLarge)
                    .background(PrismediaBackdrop())
            }
        }
    }
#endif
