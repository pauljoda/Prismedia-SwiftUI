import SwiftUI

/// A reusable watch/read/listen progress surface. All behavior is injected by its
/// caller; the card owns only presentation and accessibility concerns.
public struct MediaProgressCard: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

    private let presentation: MediaProgressCardPresentation
    private let actions: MediaProgressCardActions

    public init(
        presentation: MediaProgressCardPresentation,
        onResume: @escaping () -> Void,
        onStartOver: @escaping () -> Void,
        onToggleCompletion: @escaping () -> Void
    ) {
        self.presentation = presentation
        actions = MediaProgressCardActions(
            resume: onResume,
            startOver: onStartOver,
            toggleCompletion: onToggleCompletion
        )
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            progressSummary
            progressBar
            actionsView
        }
        .padding(.vertical, PrismediaSpacing.small)
        .frame(
            maxWidth: PrismediaLayout.readableContentWidth,
            alignment: .leading
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(presentation.progressAccessibilityLabel)
    }

    private var progressSummary: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.medium) {
                Label(
                    presentation.statusTitle,
                    systemImage: presentation.statusSystemImage
                )
                .font(.headline)
                .foregroundStyle(statusTint)

                Spacer(minLength: PrismediaSpacing.small)

                if presentation.isBusy {
                    ProgressView()
                        .controlSize(.small)
                        .tint(artworkPrimaryAccent)
                        .accessibilityLabel("Updating progress")
                }

                if presentation.percent > 0 {
                    Text("\(presentation.percent)%")
                        .font(.title2.monospacedDigit().weight(.bold))
                        .foregroundStyle(PrismediaColor.textPrimary)
                        .accessibilityLabel("\(presentation.percent) percent complete")
                }
            }

            progressLabels
        }
    }

    @ViewBuilder
    private var progressLabels: some View {
        if presentation.positionLabel != nil || presentation.contextLabel != nil {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                if let positionLabel = presentation.positionLabel {
                    Text(positionLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PrismediaColor.textPrimary)
                        .accessibilityLabel("Current position, \(positionLabel)")
                }

                if let contextLabel = presentation.contextLabel {
                    Text(contextLabel)
                        .font(.footnote)
                        .foregroundStyle(PrismediaColor.textSecondary)
                        .accessibilityLabel("Context, \(contextLabel)")
                }
            }
        }
    }

    @ViewBuilder
    private var progressBar: some View {
        if presentation.percent > 0 {
            ProgressView(value: Double(presentation.percent), total: 100)
                .tint(statusTint)
                .accessibilityLabel("Progress")
                .accessibilityValue("\(presentation.percent) percent complete")
        }
    }

    @ViewBuilder
    private var actionsView: some View {
        if presentation.hasVisibleAction {
            GlassEffectContainer(spacing: PrismediaSpacing.small) {
                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    primaryAction
                    secondaryActions
                }
            }
            .disabled(presentation.isBusy)
        }
    }

    @ViewBuilder
    private var primaryAction: some View {
        if let resumeAction = presentation.resumeAction {
            PrismediaButton(
                resumeAction.title,
                systemImage: resumeAction.systemImage,
                variant: .prominent,
                form: .fill,
                primaryTint: artworkPrimaryAccent,
                isLoading: presentation.isBusy,
                action: actions.resume
            )
            .accessibilityHint(resumeAction.accessibilityHint)
            .accessibilityIdentifier("media-progress.resume")
        }
    }

    @ViewBuilder
    private var secondaryActions: some View {
        if presentation.startOverAction != nil || presentation.completionAction != nil {
            HStack(spacing: PrismediaSpacing.small) {
                if let startOverAction = presentation.startOverAction {
                    compactActionButton(
                        startOverAction,
                        identifier: "media-progress.start-over",
                        action: actions.startOver
                    )
                }

                if let completionAction = presentation.completionAction {
                    compactActionButton(
                        completionAction,
                        identifier: "media-progress.completion",
                        action: actions.toggleCompletion
                    )
                }

                Spacer(minLength: 0)
            }
        }
    }

    private func compactActionButton(
        _ actionPresentation: MediaProgressCardActionPresentation,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(actionPresentation.title, systemImage: actionPresentation.systemImage)
                .labelStyle(.iconOnly)
        }
        .buttonStyle(.glass(.clear))
        .buttonBorderShape(.circle)
        .frame(
            minWidth: PrismediaLayout.minimumHitTarget,
            minHeight: PrismediaLayout.minimumHitTarget
        )
        .contentShape(.rect)
        .accessibilityLabel(actionPresentation.title)
        .accessibilityHint(actionPresentation.accessibilityHint)
        .accessibilityIdentifier(identifier)
    }

    private var statusTint: Color {
        presentation.status == .notStarted
            ? PrismediaColor.textMuted
            : artworkPrimaryAccent
    }
}

#if DEBUG
    #Preview("Media Progress · Reading") {
        ZStack {
            PrismediaBackdrop()

            MediaProgressCard(
                presentation: MediaProgressCardPresentation(
                    kind: .read,
                    status: .inProgress,
                    percent: 42,
                    positionLabel: "Book page 84 of 200",
                    contextLabel: "Ch. 4: The Long Way Home",
                    showsResume: true,
                    showsStartOver: true,
                    showsCompletionToggle: true
                ),
                onResume: {},
                onStartOver: {},
                onToggleCompletion: {}
            )
            .padding(PrismediaSpacing.extraExtraLarge)
        }
        .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
        .preferredColorScheme(.dark)
    }

    #Preview("Media Progress · Watched") {
        ZStack {
            PrismediaBackdrop()

            MediaProgressCard(
                presentation: MediaProgressCardPresentation(
                    kind: .watch,
                    status: .completed,
                    percent: 100,
                    contextLabel: "Episode 8",
                    showsResume: false,
                    showsStartOver: true,
                    showsCompletionToggle: true
                ),
                onResume: {},
                onStartOver: {},
                onToggleCompletion: {}
            )
            .padding(PrismediaSpacing.extraExtraLarge)
        }
        .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumMagenta)
        .preferredColorScheme(.dark)
    }

    #Preview("Media Progress · Listening · Accessibility") {
        ZStack {
            PrismediaBackdrop()

            MediaProgressCard(
                presentation: MediaProgressCardPresentation(
                    kind: .listen,
                    status: .inProgress,
                    percent: 68,
                    positionLabel: "6:52:10 of 10:04:00",
                    contextLabel: "Part 9 of 14",
                    showsResume: true,
                    showsStartOver: true,
                    showsCompletionToggle: true,
                    isBusy: false
                ),
                onResume: {},
                onStartOver: {},
                onToggleCompletion: {}
            )
            .padding(PrismediaSpacing.extraExtraLarge)
        }
        .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumOrange)
        .environment(\.dynamicTypeSize, .accessibility3)
        .preferredColorScheme(.dark)
    }
#endif
