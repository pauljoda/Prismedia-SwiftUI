import SwiftUI

struct SearchHubSearchControls: View {
    @Binding var filters: SearchHubFilterState

    let usesRegularLayout: Bool
    let onPresentFilters: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            HStack {
                Text("Search In")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Button(action: onPresentFilters) {
                    Label(
                        filters.isDefault
                            ? "Filters"
                            : "Filters (\(filters.activeFilterCount))",
                        systemImage: filters.isDefault
                            ? "line.3.horizontal.decrease"
                            : "line.3.horizontal.decrease.circle.fill"
                    )
                }
                .accessibilityHint("Shows rating, date, and entity-kind filters")
                .accessibilityIdentifier("shell.search.filter-sheet")
            }

            SearchHubKindSelector(filters: $filters, usesRegularLayout: usesRegularLayout)

            if !filters.isDefault {
                HStack(spacing: PrismediaSpacing.medium) {
                    Label(filterSummary, systemImage: "line.3.horizontal.decrease.circle.fill")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Spacer(minLength: PrismediaSpacing.small)

                    Button("Reset") {
                        filters.reset()
                    }
                    .accessibilityHint("Clears every Search filter")
                }
            }
        }
    }

    private var filterSummary: String {
        var parts: [String] = []
        if filters.selectedKinds != SearchHubKindCatalog.allKinds {
            parts.append("\(filters.selectedKinds.count) kinds")
        }
        if let minimumRating = filters.minimumRating {
            parts.append("\(minimumRating)+ stars")
        }
        if let dateFrom = filters.dateFrom {
            parts.append("from \(dateFrom.formatted(date: .abbreviated, time: .omitted))")
        }
        if let dateTo = filters.dateTo {
            parts.append("through \(dateTo.formatted(date: .abbreviated, time: .omitted))")
        }
        return parts.joined(separator: " · ")
    }
}

#if DEBUG
    #Preview("Search Controls · Default") {
        @Previewable @State var filters = SearchHubFilterState()

        SearchHubSearchControls(
            filters: $filters,
            usesRegularLayout: true,
            onPresentFilters: {}
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }

    #Preview("Search Controls · Active Filters") {
        @Previewable @State var filters = SearchHubFilterState(
            selectedKinds: [.movie, .videoSeries],
            minimumRating: 4,
            dateFrom: Date(timeIntervalSince1970: 1_704_067_200)
        )

        SearchHubSearchControls(
            filters: $filters,
            usesRegularLayout: false,
            onPresentFilters: {}
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }

    #Preview("Search Controls · Accessibility") {
        @Previewable @State var filters = SearchHubFilterState()

        SearchHubSearchControls(
            filters: $filters,
            usesRegularLayout: false,
            onPresentFilters: {}
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
