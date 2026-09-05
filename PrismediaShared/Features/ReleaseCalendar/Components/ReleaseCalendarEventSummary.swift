import SwiftUI

#if os(iOS) || os(macOS)
    struct ReleaseCalendarEventSummary: View {
        let event: ReleaseCalendarEvent

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Text(ReleaseCalendarPresentationPolicy.title(for: event))
                    .font(.headline)
                    .foregroundStyle(PrismediaColor.textPrimary)
                Text(event.dateType.displayName)
                    .font(.subheadline)
                    .foregroundStyle(PrismediaColor.textSecondary)
                if event.isSearchGate {
                    Label(searchGateLabel, systemImage: "magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(
                            event.isSearchEligible == true
                                ? PrismediaColor.success
                                : PrismediaColor.warning)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }

        private var searchGateLabel: String {
            if event.isSearchEligible == true { return "Search ready" }
            if let searchNotBefore = event.searchNotBefore,
                let date = ReleaseCalendarDatePolicy.date(from: searchNotBefore)
            {
                return "Searches \(date.formatted(.dateTime.month(.abbreviated).day()))"
            }
            return "Search gate"
        }
    }
#endif

#if DEBUG && (os(iOS) || os(macOS))
    #Preview("Release Summary · Long Title") {
        ReleaseCalendarEventSummary(event: ReleaseCalendarPreviewFixtures.longTitleEvent)
            .padding()
            .environment(\.dynamicTypeSize, .accessibility5)
    }
#endif
