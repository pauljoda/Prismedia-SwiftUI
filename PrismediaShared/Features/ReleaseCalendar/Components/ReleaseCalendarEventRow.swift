import SwiftUI

#if os(iOS) || os(macOS)
    struct ReleaseCalendarEventRow: View {
        let event: ReleaseCalendarEvent
        let resolveAssetURL: (String?) -> URL?
        let onOpen: (() -> Void)?

        init(
            event: ReleaseCalendarEvent,
            resolveAssetURL: @escaping (String?) -> URL?,
            onOpen: (() -> Void)? = nil
        ) {
            self.event = event
            self.resolveAssetURL = resolveAssetURL
            self.onOpen = onOpen
        }

        var body: some View {
            Group {
                if let onOpen {
                    Button(action: onOpen) { rowLabel }
                        .buttonStyle(.plain)
                } else {
                    NavigationLink(value: ReleaseCalendarPresentationPolicy.entityLink(for: event)) {
                        rowLabel
                    }
                    .buttonStyle(.plain)
                }
            }
            .accessibilityHint("Opens entity details")
        }

        private var rowLabel: some View {
            HStack(spacing: PrismediaSpacing.medium) {
                    AsyncImage(url: resolveAssetURL(event.posterURL)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "photo")
                            .foregroundStyle(PrismediaColor.textSecondary)
                    }
                    .frame(width: 42, height: 58)
                    .background(PrismediaColor.controlFill)
                    .clipShape(.rect(cornerRadius: PrismediaRadius.compact))

                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        Text(ReleaseCalendarPresentationPolicy.title(for: event))
                            .font(.headline)
                            .foregroundStyle(PrismediaColor.textPrimary)
                            .lineLimit(2)
                        Text(event.dateType.displayName)
                            .font(.subheadline)
                            .foregroundStyle(PrismediaColor.textSecondary)
                        if event.isSearchGate {
                            Label(searchGateLabel, systemImage: "magnifyingglass")
                                .font(.caption)
                                .foregroundStyle(event.isSearchEligible == true ? PrismediaColor.success : PrismediaColor.warning)
                        }
                    }
                    Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
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
    #Preview("Release Calendar Event") {
        NavigationStack {
            ReleaseCalendarEventRow(
                event: ReleaseCalendarPreviewFixtures.events[0],
                resolveAssetURL: { _ in nil }
            )
            .padding()
        }
        .preferredColorScheme(.dark)
    }
#endif
