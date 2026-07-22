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
                    referenceArtwork(reference)

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

    @ViewBuilder
    private func referenceArtwork(_ reference: EntityDetailReferenceDraft) -> some View {
        if let thumbnail = reference.sourceThumbnail {
            EntityThumbnailCompactArtworkView(item: thumbnail, width: 42)
        } else {
            EntityThumbnailCompactArtworkView(
                title: reference.title,
                kind: reference.kind,
                artworkPath: reference.artworkPath,
                width: 42
            )
        }
    }
}

#if DEBUG
    #Preview("Entity Reference Selector") {
        @Previewable @State var people = [
            EntityDetailReferenceDraft(
                thumbnail: EntityThumbnail(id: UUID(), kind: .person, title: "Mara Voss")
            )
        ]
        @Previewable @State var studios = [
            EntityDetailReferenceDraft(
                thumbnail: EntityThumbnail(id: UUID(), kind: .studio, title: "Northlight Studio")
            )
        ]
        @Previewable @State var tags = [
            EntityDetailReferenceDraft(
                thumbnail: EntityThumbnail(id: UUID(), kind: .tag, title: "Atmospheric")
            )
        ]

        PreviewShell {
            NavigationStack {
                Form {
                    EntityDetailReferenceSelector(
                        selection: $people,
                        title: "People",
                        kind: .person,
                        mode: .multiple,
                        searchService: EntityDetailReferenceSearchService(
                            loader: StaticEntityGridLoader(items: [])
                        )
                    )
                    EntityDetailReferenceSelector(
                        selection: $studios,
                        title: "Studio",
                        kind: .studio,
                        mode: .single,
                        searchService: EntityDetailReferenceSearchService(
                            loader: StaticEntityGridLoader(items: [])
                        )
                    )
                    EntityDetailReferenceSelector(
                        selection: $tags,
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
