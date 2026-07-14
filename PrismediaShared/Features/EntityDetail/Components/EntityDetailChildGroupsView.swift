import SwiftUI

struct EntityDetailChildGroupsView: View {
    @Environment(\.artworkSecondaryText) private var artworkSecondaryText
    let groups: [EntityGroup]
    let horizontalPadding: CGFloat
    let onPrimaryAction: ((EntityThumbnail) -> Void)?

    init(
        groups: [EntityGroup],
        horizontalPadding: CGFloat,
        onPrimaryAction: ((EntityThumbnail) -> Void)? = nil
    ) {
        self.groups = groups
        self.horizontalPadding = horizontalPadding
        self.onPrimaryAction = onPrimaryAction
    }

    var body: some View {
        ForEach(groups, id: \.entityDetailChildGroupID) { group in
            if group.kind == .tag {
                EntityTags(tags: group.entities, title: group.label)
                    .padding(.horizontal, horizontalPadding)
            } else {
                thumbnailGroup(group)
            }
        }
    }

    private func thumbnailGroup(_ group: EntityGroup) -> some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
            HStack(alignment: .firstTextBaseline) {
                Text(group.label)
                    .font(.title3.bold())
                    .foregroundStyle(PrismediaColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Text(String(group.entities.count))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(artworkSecondaryText)
            }
            .padding(.horizontal, horizontalPadding)

            EntityThumbnailGrid(
                items: group.entities,
                minimumColumnWidth: minimumColumnWidth
            ) { item in
                EntityThumbnailNavigationSurface(
                    item: item,
                    onPrimaryAction: onPrimaryAction
                )
                .accessibilityIdentifier("entity-detail.child.\(item.id.uuidString)")
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, PrismediaSpacing.medium)
            .accessibilityIdentifier("entity-detail.children.\(group.kind.rawValue)")
            .accessibilityValue(String(group.entities.count))
            .prismediaFocusSection()
        }
    }

    private var minimumColumnWidth: CGFloat {
        #if os(tvOS)
            240
        #else
            150
        #endif
    }
}

extension EntityGroup {
    fileprivate var entityDetailChildGroupID: String {
        code ?? "\(kind.rawValue):\(label)"
    }
}

#if DEBUG
    #Preview("Entity Detail Child Groups") {
        NavigationStack {
            ScrollView {
                EntityDetailChildGroupsView(
                    groups: EntityDetailPreviewFixture.detail.childrenByKind,
                    horizontalPadding: PrismediaSpacing.extraLarge
                )
            }
        }
    }
#endif
