import SwiftUI

struct EntityDetailChildGroupsView: View {
    @Environment(PrismediaAppEnvironment.self) private var environment
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
        EntityGridView(
            configuration: gridConfiguration(for: group),
            loader: StaticEntityGridLoader(
                items: group.entities,
                allowsNsfwContent: environment.allowsNsfwContent
            ),
            presentation: .embedded,
            horizontalContentPadding: horizontalPadding
        ) { item, layout in
            EntityThumbnailNavigationSurface(
                item: item,
                layout: layout,
                onPrimaryAction: onPrimaryAction
            )
            .accessibilityIdentifier("entity-detail.child.\(item.id.uuidString)")
        }
        .padding(.bottom, PrismediaSpacing.medium)
        .accessibilityIdentifier("entity-detail.children.\(group.kind.rawValue)")
        .prismediaFocusSection()
    }

    private func gridConfiguration(for group: EntityGroup) -> EntityGridConfiguration {
        let presentation = groupPresentation(for: group.kind)
        let itemKinds = Array(Set(group.entities.map(\.kind))).sorted {
            $0.rawValue < $1.rawValue
        }
        let query =
            itemKinds.count == 1
            ? EntityListQuery(kind: itemKinds.first)
            : EntityListQuery(kinds: itemKinds)

        return EntityGridConfiguration(
            title: group.label,
            query: query,
            pageSize: 48,
            minimumColumnWidth: minimumColumnWidth,
            defaultDisplayMode: presentation.defaultMode,
            availableDisplayModes: presentation.availableModes
        )
    }

    private func groupPresentation(
        for kind: EntityKind
    ) -> (defaultMode: EntityGridDisplayMode, availableModes: [EntityGridDisplayMode]) {
        switch kind {
        case .video:
            return (.list, [.list])
        case .image:
            return (.wall, [.wall, .grid])
        case .gallery:
            return (.grid, [.grid, .list, .feed])
        default:
            return (.grid, [.grid, .list])
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
