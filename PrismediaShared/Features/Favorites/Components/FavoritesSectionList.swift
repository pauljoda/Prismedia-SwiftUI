import SwiftUI

/// The favorite kinds as a list, beside the selected kind's grid on a wide
/// display.
struct FavoritesSectionList: View {
    @ScaledMetric(relativeTo: .headline) private var iconSize: CGFloat = 28

    let sections: [FavoritesSection]
    let selectedID: FavoritesSection.ID?
    let onSelect: (FavoritesSection) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: PrismediaSpacing.extraSmall) {
                ForEach(sections) { section in
                    Button {
                        onSelect(section)
                    } label: {
                        row(section, isSelected: section.id == selectedID)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(section.id == selectedID ? .isSelected : [])
                    .accessibilityIdentifier("favorites.section.\(section.id)")
                }
            }
            .padding(PrismediaSpacing.large)
        }
    }

    private func row(_ section: FavoritesSection, isSelected: Bool) -> some View {
        HStack(spacing: PrismediaSpacing.medium) {
            Image(systemName: section.definition.systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(PrismediaColor.onMedia)
                .frame(width: iconSize, height: iconSize)
                .background(
                    LinearGradient(
                        colors: section.definition.colorRole.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: .circle
                )
                .accessibilityHidden(true)

            Text(section.definition.title)
                .font(.headline)
                .foregroundStyle(PrismediaColor.textPrimary)

            Spacer(minLength: PrismediaSpacing.small)
        }
        .padding(.horizontal, PrismediaSpacing.medium)
        .frame(maxWidth: .infinity, minHeight: PrismediaLayout.minimumHitTarget, alignment: .leading)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: PrismediaRadius.control)
                    .fill(PrismediaColor.controlFill)
            }
        }
        .contentShape(.rect)
    }
}

#if DEBUG
    #Preview("Favorite Section List") {
        PreviewShell(signedIn: true) {
            FavoritesSectionList(
                sections: FavoritesCatalog.sections.prefix(3).map {
                    FavoritesSection(definition: $0, items: PrismediaPreviewData.videos)
                },
                selectedID: FavoritesCatalog.sections.first?.id,
                onSelect: { _ in }
            )
        }
    }
#endif
