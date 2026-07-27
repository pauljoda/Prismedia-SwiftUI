import SwiftUI

#if os(iOS) || os(macOS)
    struct ReleaseCalendarEventRow: View {
        @State private var artworkPalette: ArtworkPalette?

        let event: ReleaseCalendarEvent
        let resolveAssetURL: (String?) -> URL?
        let onOpen: () -> Void

        init(
            event: ReleaseCalendarEvent,
            resolveAssetURL: @escaping (String?) -> URL?,
            onOpen: @escaping () -> Void
        ) {
            self.event = event
            self.resolveAssetURL = resolveAssetURL
            self.onOpen = onOpen
        }

        var body: some View {
            Button(action: onOpen) { rowLabel }
                .buttonStyle(.plain)
                .padding(.vertical, PrismediaSpacing.extraSmall)
                .prismediaArtworkPalette(
                    for: event.posterURL,
                    palette: $artworkPalette
                )
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
                            .foregroundStyle(
                                event.isSearchEligible == true
                                    ? PrismediaColor.success
                                    : PrismediaColor.warning
                            )
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.forward")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(PrismediaColor.textMuted)
                    .accessibilityHidden(true)
            }
            .padding(PrismediaSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                cardBackground
                    .clipShape(cardShape)
            }
            .overlay {
                cardShape.stroke(
                    PrismediaColor.borderSubtle,
                    lineWidth: PrismediaLayout.hairline
                )
            }
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(PrismediaColor.entityAccent(for: event.kind))
                    .frame(width: 4)
                    .padding(.vertical, PrismediaSpacing.medium)
                    .padding(.leading, PrismediaSpacing.extraSmall)
                    .accessibilityHidden(true)
            }
            .contentShape(.rect)
        }

        private var cardBackground: some View {
            ZStack {
                PrismediaColor.elevatedContentBackground
                if let artworkPalette {
                    artworkPalette.background.color
                    LinearGradient(
                        colors: [
                            artworkPalette.primary.color.opacity(0.42),
                            artworkPalette.secondary.color.opacity(0.24),
                            .clear,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .animation(.easeInOut(duration: 0.18), value: artworkPalette)
        }

        private var cardShape: PrismediaStableRoundedRectangle {
            PrismediaStableRoundedRectangle(cornerRadius: PrismediaRadius.card)
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
        PreviewShell {
            NavigationStack {
                ReleaseCalendarEventRow(
                    event: ReleaseCalendarPreviewFixtures.events[0],
                    resolveAssetURL: { _ in nil },
                    onOpen: {}
                )
                .padding()
            }
        }
        .preferredColorScheme(.dark)
    }
#endif
