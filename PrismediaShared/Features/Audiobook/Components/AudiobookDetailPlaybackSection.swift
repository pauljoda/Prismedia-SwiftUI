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
                    errorBanner(errorMessage)
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

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(PrismediaColor.warning)
                .accessibilityHidden(true)
            Text(message)
                .font(.callout)
                .foregroundStyle(PrismediaColor.textSecondary)
            Spacer(minLength: 8)
            Button("Dismiss", systemImage: "xmark", action: onDismissError)
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
        }
        .padding(PrismediaSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .prismediaPanel()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("entity-detail.audiobook-progress.error")
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
