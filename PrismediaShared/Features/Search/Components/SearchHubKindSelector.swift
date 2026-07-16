import SwiftUI

struct SearchHubKindSelector: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Binding private var filters: SearchHubFilterState
    private let usesRegularLayout: Bool

    init(filters: Binding<SearchHubFilterState>, usesRegularLayout: Bool) {
        _filters = filters
        self.usesRegularLayout = usesRegularLayout
    }

    var body: some View {
        if usesRegularLayout && !dynamicTypeSize.isAccessibilitySize {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 116), spacing: PrismediaSpacing.small)],
                alignment: .leading,
                spacing: PrismediaSpacing.small
            ) {
                kindButtons
            }
        } else {
            ScrollView(.horizontal) {
                HStack(spacing: PrismediaSpacing.small) {
                    kindButtons
                }
                .padding(.vertical, PrismediaSpacing.extraExtraSmall)
            }
            .scrollIndicators(.hidden)
        }
    }

    @ViewBuilder
    private var kindButtons: some View {
        ForEach(SearchHubKindCatalog.kinds, id: \.rawValue) { kind in
            let isSelected = filters.selectedKinds.contains(kind)
            Button {
                filters.toggle(kind)
            } label: {
                Label(
                    SearchHubKindCatalog.label(for: kind),
                    systemImage: SearchHubKindCatalog.systemImage(for: kind)
                )
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .frame(maxWidth: usesRegularLayout ? .infinity : nil, alignment: .leading)
                .padding(.horizontal, PrismediaSpacing.medium)
                .padding(.vertical, PrismediaSpacing.small)
                .background(
                    isSelected
                        ? PrismediaColor.accent.opacity(PrismediaOpacity.statusFill)
                        : PrismediaColor.controlFill
                )
                .foregroundStyle(isSelected ? PrismediaColor.accent : PrismediaColor.textSecondary)
                .clipShape(.capsule)
                .contentShape(.capsule)
            }
            .buttonStyle(.plain)
            .accessibilityValue(isSelected ? "Included" : "Excluded")
            .accessibilityHint(
                isSelected && filters.selectedKinds.count == 1
                    ? "At least one kind must remain included"
                    : "Toggles this entity kind in search results"
            )
            .accessibilityIdentifier("shell.search.kind.\(kind.rawValue)")
        }
    }
}

#if DEBUG
    #Preview("Search Kinds · Compact") {
        @Previewable @State var filters = SearchHubFilterState()
        SearchHubKindSelector(filters: $filters, usesRegularLayout: false)
            .padding()
            .prismediaScreenBackground()
    }

    #Preview("Search Kinds · Regular") {
        @Previewable @State var filters = SearchHubFilterState()
        SearchHubKindSelector(filters: $filters, usesRegularLayout: true)
            .padding()
            .frame(width: 900)
            .prismediaScreenBackground()
    }
#endif
