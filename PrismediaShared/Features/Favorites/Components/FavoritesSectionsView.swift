import SwiftUI

struct FavoritesSectionsView: View {
    let sections: [FavoritesSection]
    let onSelect: (FavoritesSectionDefinition) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(
                alignment: .leading,
                spacing: PrismediaSpacing.extraExtraLarge
            ) {
                ForEach(sections) { section in
                    DashboardShelfView(
                        title: section.definition.title,
                        systemImage: section.definition.systemImage,
                        colorRole: section.definition.colorRole,
                        items: section.items,
                        onSelect: { onSelect(section.definition) }
                    )
                }
            }
            .padding(.vertical, PrismediaSpacing.extraLarge)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#if DEBUG
    #Preview("Favorite Sections") {
        PreviewShell(signedIn: true) {
            FavoritesSectionsView(
                sections: [
                    FavoritesSection(
                        definition: FavoritesCatalog.sections[0],
                        items: [PrismediaPreviewData.videos[0]]
                    )
                ],
                onSelect: { _ in }
            )
        }
    }
#endif
