#if os(iOS)
    import SwiftUI

    struct MusicTrackActionsPopoverView: View {
        @Environment(\.dismiss) private var dismiss

        let track: MusicTrack
        let onNavigate: (EntityLink) -> Void
        let onAddToCollection: () -> Void
        let onShowNowPlaying: () -> Void
        let onHidePlayer: () -> Void

        var body: some View {
            VStack(spacing: 0) {
                actionButton("Show Now Playing", systemImage: "music.note.list", action: onShowNowPlaying)

                if let albumLink = track.albumNavigationLink {
                    actionButton("Go to Album", systemImage: "square.stack") {
                        onNavigate(albumLink)
                    }
                }

                if let artistLink = track.artistNavigationLink {
                    actionButton("Go to Artist", systemImage: "music.mic") {
                        onNavigate(artistLink)
                    }
                }

                actionButton(
                    "Add to Collection",
                    systemImage: "rectangle.stack.badge.plus",
                    action: onAddToCollection
                )

                Divider()
                    .padding(.vertical, PrismediaSpacing.extraExtraSmall)

                actionButton("Hide Player", systemImage: "xmark", action: onHidePlayer)
            }
            .padding(.vertical, PrismediaSpacing.extraSmall)
            .frame(width: 270)
            .presentationCompactAdaptation(.popover)
            .accessibilityIdentifier("music.track-actions-popover")
        }

        private func actionButton(
            _ title: LocalizedStringKey,
            systemImage: String,
            action: @escaping () -> Void
        ) -> some View {
            Button {
                dismiss()
                action()
            } label: {
                Label(title, systemImage: systemImage)
                    .font(.body)
                    .foregroundStyle(PrismediaColor.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: PrismediaLayout.minimumHitTarget, alignment: .leading)
                    .padding(.horizontal, PrismediaSpacing.medium)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }

    #if DEBUG
        #Preview("Music Track Actions Popover") {
            MusicTrackActionsPopoverView(
                track: MusicPreviewData.tracks[0],
                onNavigate: { _ in },
                onAddToCollection: {},
                onShowNowPlaying: {},
                onHidePlayer: {}
            )
            .background(PrismediaBackdrop())
        }
    #endif
#endif
