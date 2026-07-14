import SwiftUI

struct AudiobookDetailPlaybackSection: View {
    let presentation: AudiobookPlaybackPresentation?
    let errorMessage: String?
    let horizontalPadding: CGFloat
    let onResume: () -> Void
    let onStartOver: () -> Void
    let onToggleCompletion: () -> Void
    let onDismissError: () -> Void

    @ViewBuilder
    var body: some View {
        if presentation != nil || errorMessage != nil {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                if let errorMessage {
                    MediaProgressErrorBanner(
                        message: errorMessage,
                        textColor: PrismediaColor.textSecondary,
                        accessibilityIdentifier: "entity-detail.audiobook-progress.error",
                        onDismiss: onDismissError
                    )
                }

                if let presentation {
                    MediaProgressCard(
                        presentation: presentation.progress,
                        onResume: onResume,
                        onStartOver: onStartOver,
                        onToggleCompletion: onToggleCompletion
                    )
                }
            }
            .padding(.horizontal, horizontalPadding)
            .accessibilityIdentifier("entity-detail.audiobook-progress")
        }
    }

}

#if DEBUG
    #Preview("Audiobook · Listening · Accessibility") {
        PreviewShell {
            AudiobookDetailPlaybackSection(
                presentation: AudiobookPlaybackPresentation(
                    totalDuration: 36_300,
                    partCount: 2,
                    resumeSeconds: 12_420,
                    isCompleted: false,
                    isCurrentAudiobook: false,
                    isPlaying: false
                ),
                errorMessage: nil,
                horizontalPadding: PrismediaSpacing.extraLarge,
                onResume: {},
                onStartOver: {},
                onToggleCompletion: {},
                onDismissError: {}
            )
            .padding(.vertical)
        }
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
