import SwiftUI

struct EntityDetailVideoProgressView: View {
    let presentation: MediaProgressCardPresentation?
    let errorMessage: String?
    let horizontalPadding: CGFloat
    let onContinue: () -> Void
    let onStartOver: () -> Void
    let onToggleCompletion: () -> Void
    let onDismissError: () -> Void

    var body: some View {
        if presentation != nil || errorMessage != nil {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                if let presentation {
                    MediaProgressCard(
                        presentation: presentation,
                        onResume: onContinue,
                        onStartOver: onStartOver,
                        onToggleCompletion: onToggleCompletion
                    )
                }

                if let errorMessage {
                    MediaProgressErrorBanner(
                        message: errorMessage,
                        textColor: PrismediaColor.textPrimary,
                        accessibilityIdentifier: "video-progress.error",
                        onDismiss: onDismissError
                    )
                }
            }
            .padding(.horizontal, horizontalPadding)
        }
    }
}

#if DEBUG
    #Preview("Video Container Progress") {
        EntityDetailVideoProgressView(
            presentation: MediaProgressCardPresentation(
                kind: .watch,
                status: .inProgress,
                percent: 46,
                positionLabel: "Episode 6 of 12",
                contextLabel: "The Long Way Home",
                showsResume: true,
                showsStartOver: true,
                showsCompletionToggle: true
            ),
            errorMessage: nil,
            horizontalPadding: PrismediaSpacing.extraLarge,
            onContinue: {},
            onStartOver: {},
            onToggleCompletion: {},
            onDismissError: {}
        )
        .padding(.vertical, PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }
#endif
