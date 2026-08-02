import SwiftUI

struct EntityGridSortMenu: View {
    let catalog: EntityGridControlCatalog
    let controls: EntityGridControls
    let onSelect: (EntityGridSort) -> Void
    let onReshuffle: () -> Void
    let onReverseDirection: () -> Void

    var body: some View {
        Menu {
            ForEach(catalog.sortOptions) { option in
                Button {
                    onSelect(option)
                } label: {
                    if controls.sort == option {
                        Label(option.label, systemImage: "checkmark")
                    } else {
                        Text(option.label)
                    }
                }
            }

            Divider()

            if controls.sort == .random {
                Button(action: onReshuffle) {
                    Label("Reshuffle", systemImage: "shuffle")
                }
            } else {
                Button(action: onReverseDirection) {
                    Label(
                        controls.sortDescending ? "Descending" : "Ascending",
                        systemImage: controls.sortDescending ? "arrow.down" : "arrow.up"
                    )
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .accessibilityLabel("Sort")
        .accessibilityIdentifier("entity.grid.sort")
    }
}

#if DEBUG
    #Preview("Entity Grid Sort · Standard") {
        EntityGridSortMenu(
            catalog: EntityGridControlCatalog(query: EntityListQuery(kind: .movie)),
            controls: EntityGridControls(baselineQuery: EntityListQuery(sort: PrismediaContractCodes.EntityListSort.title)),
            onSelect: { _ in },
            onReshuffle: {},
            onReverseDirection: {}
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }

    #Preview("Entity Grid Sort · Random") {
        EntityGridSortMenu(
            catalog: EntityGridControlCatalog(query: EntityListQuery()),
            controls: EntityGridPreviewFactory.randomControls,
            onSelect: { _ in },
            onReshuffle: {},
            onReverseDirection: {}
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }
#endif
