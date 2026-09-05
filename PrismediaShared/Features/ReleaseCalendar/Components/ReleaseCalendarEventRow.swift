import SwiftUI

#if os(iOS) || os(macOS)
    struct ReleaseCalendarEventRow: View {
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
                    AsyncImage(url: resolveAssetURL(event.posterURL)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "photo")
                            .foregroundStyle(PrismediaColor.textSecondary)
                    }
                    .frame(width: 42, height: 58)
                    .background(PrismediaColor.controlFill)
                    .clipShape(.rect(cornerRadius: PrismediaRadius.compact))
                    .accessibilityHidden(true)
                    if !dynamicTypeSize.isAccessibilitySize {
                        ReleaseCalendarEventSummary(event: event)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Spacer(minLength: 0)
                    }
                    Image(systemName: "chevron.forward")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PrismediaColor.textMuted)
                        .accessibilityHidden(true)
                }
                if dynamicTypeSize.isAccessibilitySize {
                    ReleaseCalendarEventSummary(event: event)
                }
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
            .accessibilityElement(children: .combine)
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
    #Preview("Release Calendar Event · Largest Text") {
        PreviewShell {
            List {
                ReleaseCalendarEventRow(
                    event: ReleaseCalendarPreviewFixtures.longTitleEvent,
                    resolveAssetURL: { _ in nil }, onOpen: {})
            }
        }
        .environment(\.dynamicTypeSize, .accessibility5)
    }
#endif
