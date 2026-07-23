import SwiftUI

struct SearchHubNavigationSection: View {
    let matches: [SearchHubNavigationTarget]
    let onSelect: (SearchHubNavigationTarget) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            Text("Navigate")
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                ForEach(Array(matches.enumerated()), id: \.element.destination.id) { index, target in
                    navigationRow(target)

                    if index < matches.count - 1 {
                        Divider()
                            .padding(
                                .leading,
                                PrismediaSpacing.section + PrismediaSpacing.medium
                            )
                    }
                }
            }
        }
    }

    private func navigationRow(_ target: SearchHubNavigationTarget) -> some View {
        Button {
            onSelect(target)
        } label: {
            HStack(spacing: PrismediaSpacing.medium) {
                Image(systemName: target.destination.systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(PrismediaColor.accent)
                    .frame(
                        width: PrismediaSpacing.section,
                        height: PrismediaSpacing.section
                    )

                VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                    Text(target.destination.title)
                        .foregroundStyle(.primary)
                    Text(target.mode.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: PrismediaLayout.minimumHitTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("shell.search.navigation.\(target.destination.id)")
    }
}

#if DEBUG
    #Preview("Search Navigation · Matches") {
        SearchHubNavigationSection(
            matches: Array(
                SearchHubCatalog.navigationMatches(for: "movie")
                    .prefix(3)
            ),
            onSelect: { _ in }
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }

    #Preview("Search Navigation · Accessibility") {
        SearchHubNavigationSection(
            matches: Array(
                SearchHubCatalog.navigationMatches(for: "movie")
                    .prefix(3)
            ),
            onSelect: { _ in }
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
