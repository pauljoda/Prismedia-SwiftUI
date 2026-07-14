import SwiftUI

/// Reading and audiobook progress for an entity detail page.
struct MediaProgressCard: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

    let presentation: MediaProgressCardPresentation
    let onResume: () -> Void
    let onStartOver: () -> Void
    let onToggleCompletion: () -> Void

    var body: some View {
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
        if presentation.showsResume {
            PrismediaButton(
                presentation.resumeTitle,
                systemImage: presentation.resumeSystemImage,
                variant: .prominent,
                form: .fill,
                primaryTint: artworkPrimaryAccent,
                isLoading: presentation.isBusy,
                action: onResume
            )
            .accessibilityHint(presentation.resumeAccessibilityHint)
            .accessibilityIdentifier("media-progress.resume")
        }
    }

    @ViewBuilder
    private var secondaryActions: some View {
        if presentation.showsStartOver || presentation.showsCompletionToggle {
            HStack(spacing: PrismediaSpacing.small) {
                if presentation.showsStartOver {
                    compactActionButton(
                        title: "Start Over",
                        systemImage: "arrow.counterclockwise",
                        accessibilityHint: presentation.startOverAccessibilityHint,
                        identifier: "media-progress.start-over",
                        action: onStartOver
                    )
                }

                if presentation.showsCompletionToggle {
                    compactActionButton(
                        title: presentation.completionTitle,
                        systemImage: presentation.status == .completed ? "circle" : "checkmark.circle",
                        accessibilityHint: presentation.completionAccessibilityHint,
                        identifier: "media-progress.completion",
                        action: onToggleCompletion
                    )
                }

                Spacer(minLength: 0)
            }
        }
    }

    private func compactActionButton(
        title: String,
        systemImage: String,
        accessibilityHint: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
        }
        .buttonStyle(.glass(.clear))
        .buttonBorderShape(.circle)
        .frame(
            minWidth: PrismediaLayout.minimumHitTarget,
            minHeight: PrismediaLayout.minimumHitTarget
        )
        .contentShape(.rect)
        .accessibilityLabel(title)
        .accessibilityHint(accessibilityHint)
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
                    showsCompletionToggle: true
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
