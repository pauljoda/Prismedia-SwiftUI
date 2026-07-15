import SwiftUI

/// Reading and audiobook progress for an entity detail page.
struct MediaProgressCard: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

    let presentation: MediaProgressCardPresentation
    let onResume: () -> Void
    let onStartOver: () -> Void
    let onToggleCompletion: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
            header
            progressRow
            resumeButton
        }
        .padding(PrismediaSpacing.extraLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .prismediaPanel()
        .disabled(presentation.isBusy)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(presentation.progressAccessibilityLabel)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.medium) {
            Text("Your progress")
                .font(.caption.weight(.semibold))
                .foregroundStyle(PrismediaColor.textSecondary)
                .textCase(.uppercase)

            Spacer(minLength: PrismediaSpacing.small)

            if presentation.isBusy {
                ProgressView()
                    .controlSize(.small)
                    .tint(artworkPrimaryAccent)
                    .accessibilityLabel("Updating progress")
            }

            progressOptions
        }
    }

    private var progressRow: some View {
        GlassEffectContainer(spacing: PrismediaSpacing.small) {
            HStack(spacing: PrismediaSpacing.medium) {
                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.medium) {
                        Label(
                            presentation.statusTitle,
                            systemImage: presentation.resumeSystemImage
                        )
                        .font(.headline)
                        .foregroundStyle(statusTint)

                        Spacer(minLength: PrismediaSpacing.small)

                        if presentation.percent > 0 {
                            Text("\(presentation.percent)%")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(PrismediaColor.textPrimary)
                                .accessibilityLabel(
                                    "\(presentation.percent) percent complete"
                                )
                        }
                    }

                    progressBar
                    progressLabels
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }
        }
    }

    @ViewBuilder
    private var resumeButton: some View {
        if presentation.showsResume {
            PrismediaButton(
                presentation.resumeTitle,
                systemImage: presentation.resumeSystemImage,
                variant: .prominent,
                form: .fill,
                primaryTint: artworkPrimaryAccent,
                action: onResume
            )
            .accessibilityHint(presentation.resumeAccessibilityHint)
            .accessibilityIdentifier("media-progress.resume")
        }
    }

    @ViewBuilder
    private var progressOptions: some View {
        if presentation.showsStartOver || presentation.showsCompletionToggle {
            Menu {
                if presentation.showsStartOver {
                    Button(
                        "Start Over",
                        systemImage: "arrow.counterclockwise",
                        action: onStartOver
                    )
                    .accessibilityHint(presentation.startOverAccessibilityHint)
                    .accessibilityIdentifier("media-progress.start-over")
                }

                if presentation.showsCompletionToggle {
                    Button(
                        presentation.completionTitle,
                        systemImage: presentation.status == .completed
                            ? "circle"
                            : "checkmark.circle",
                        action: onToggleCompletion
                    )
                    .accessibilityHint(presentation.completionAccessibilityHint)
                    .accessibilityIdentifier("media-progress.completion")
                }
            } label: {
                Label("Progress Options", systemImage: "ellipsis")
                    .labelStyle(.iconOnly)
                    .padding(PrismediaSpacing.small)
            }
            .buttonStyle(.glass(.clear))
            .buttonBorderShape(.circle)
            .accessibilityLabel("Progress Options")
        }
    }

    @ViewBuilder
    private var progressLabels: some View {
        if presentation.positionLabel != nil || presentation.contextLabel != nil {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                if let positionLabel = presentation.positionLabel {
                    Text(positionLabel)
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                        .accessibilityLabel("Current position, \(positionLabel)")
                }

                if let contextLabel = presentation.contextLabel {
                    Text(contextLabel)
                        .font(.caption)
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
