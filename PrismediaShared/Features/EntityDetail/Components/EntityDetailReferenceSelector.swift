import SwiftUI

struct EntityDetailReferenceSelector: View {
    @Binding var selection: [EntityDetailReferenceDraft]

    let title: String
    let kind: EntityKind
    let mode: EntityDetailReferenceSelectionMode
    let searchService: EntityDetailReferenceSearchService

    var body: some View {
        Section(title) {
            ForEach(selection) { reference in
                HStack(spacing: PrismediaSpacing.small) {
                    RemotePosterImage(
                        path: reference.artworkPath,
                        fallbackSeed: reference.title,
                        systemImage: kind == .person ? "person.crop.square" : "tag"
                    )
                    .frame(width: 42, height: 42)
                    .clipShape(.rect(cornerRadius: PrismediaRadius.compact))

                    Text(reference.title)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button("Remove \(reference.title)", systemImage: "minus.circle", role: .destructive) {
                        selection.removeAll { $0.id == reference.id }
                    }
                    .labelStyle(.iconOnly)
                }
            }

            NavigationLink {
                EntityDetailReferenceSearchView(
                    selection: $selection,
                    title: title,
                    kind: kind,
                    mode: mode,
                    searchService: searchService
                )
            } label: {
                Label(selection.isEmpty ? "Select \(title)" : "Add \(title)", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
            }
            .accessibilityIdentifier("entity-detail.edit.\(kind.rawValue).select")
        }
    }
}

#if DEBUG
    #Preview("Entity Reference Selector") {
        @Previewable @State var selection = [
            EntityDetailReferenceDraft.new(title: "Atmospheric", kind: .tag)
        ]

        PreviewShell {
            NavigationStack {
                Form {
                    EntityDetailReferenceSelector(
                        selection: $selection,
                        title: "Tags",
                        kind: .tag,
                        mode: .multiple,
                        searchService: EntityDetailReferenceSearchService(
                            loader: StaticEntityGridLoader(items: [])
                        )
                    )
                }
            }
        }
    }
#endif
