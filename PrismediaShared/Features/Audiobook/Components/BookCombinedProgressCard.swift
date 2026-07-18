import SwiftUI

struct BookCombinedProgressCard: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

    let presentation: BookCombinedProgressPresentation
    let onContinueReading: () -> Void
    let onContinueListening: () -> Void
    let onContinueCombined: () -> Void
    let onStartReadingOver: () -> Void
    let onStartListeningOver: () -> Void
    let onToggleReadingCompletion: () -> Void
    let onToggleListeningCompletion: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
            header
            progressRows
            Text(presentation.combinedContextLabel)
                .font(.footnote)
                .foregroundStyle(PrismediaColor.textSecondary)
            actions
        }
        .padding(PrismediaSpacing.extraLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .prismediaPanel()
        .disabled(presentation.isBusy)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("combined-book-progress")
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.medium) {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Text("Your progress")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PrismediaColor.textSecondary)
                    .textCase(.uppercase)
                Text("Read & Listen")
                    .font(.title3.bold())
                    .foregroundStyle(PrismediaColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
            }
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

    private var progressRows: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
            progressRow(
                title: "Reading",
                systemImage: "book.fill",
                percent: presentation.readingPercent,
                position: presentation.readingPositionLabel
            )
            progressRow(
                title: "Listening",
                systemImage: "headphones",
                percent: presentation.listeningPercent,
                position: presentation.listeningPositionLabel
            )
        }
    }

    private func progressRow(
        title: String,
        systemImage: String,
        percent: Int,
        position: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PrismediaColor.textPrimary)
                Spacer(minLength: PrismediaSpacing.large)
                Text("\(percent)%")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(PrismediaColor.textPrimary)
            }
            ProgressView(value: Double(percent), total: 100)
                .tint(artworkPrimaryAccent)
            if let position {
                Text(position)
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.textSecondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityValue("\(percent) percent")
    }

    private var actions: some View {
        GlassEffectContainer(spacing: PrismediaSpacing.medium) {
            VStack(spacing: PrismediaSpacing.medium) {
                HStack(spacing: PrismediaSpacing.medium) {
                    PrismediaButton(
                        "Continue Reading",
                        systemImage: "book.fill",
                        form: .fillIcon,
                        action: onContinueReading
                    )
                    .accessibilityIdentifier("combined-book-progress.continue-reading")

                    PrismediaButton(
                        "Continue Listening",
                        systemImage: "headphones",
                        form: .fillIcon,
                        action: onContinueListening
                    )
                    .accessibilityIdentifier("combined-book-progress.continue-listening")
                }

                PrismediaButton(
                    "Continue Combined",
                    systemImage: "book.pages",
                    variant: .prominent,
                    form: .fill,
                    primaryTint: artworkPrimaryAccent,
                    action: onContinueCombined
                )
                .accessibilityHint(
                    "Opens the reader and starts the audiobook near the furthest saved position"
                )
                .accessibilityIdentifier("combined-book-progress.continue-combined")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var progressOptions: some View {
        Menu {
            Section("Reading") {
                Button("Start Reading Over", systemImage: "arrow.counterclockwise", action: onStartReadingOver)
                Button(
                    presentation.readingStatus == .completed ? "Mark Unread" : "Mark Read",
                    systemImage: presentation.readingStatus == .completed ? "circle" : "checkmark.circle",
                    action: onToggleReadingCompletion
                )
            }
            Section("Listening") {
                Button("Start Listening Over", systemImage: "arrow.counterclockwise", action: onStartListeningOver)
                Button(
                    presentation.listeningStatus == .completed ? "Mark Unlistened" : "Mark Listened",
                    systemImage: presentation.listeningStatus == .completed ? "circle" : "checkmark.circle",
                    action: onToggleListeningCompletion
                )
            }
        } label: {
            Label("Progress Options", systemImage: "ellipsis")
                .labelStyle(.iconOnly)
                .padding(PrismediaSpacing.small)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel("Progress Options")
    }
}

#if DEBUG
    #Preview("Combined Book Progress") {
        PreviewShell {
            BookCombinedProgressCard(
                presentation: BookCombinedProgressPresentation(
                    reading: ReadingProgressPresentation(
                        singleFileProgress: EntityProgressCapability(
                            currentEntityID: UUID(), unit: .cfi, index: 5_000, total: 10_000,
                            mode: .paged, completedAt: nil, updatedAt: nil, workIndex: nil,
                            workTotal: nil, location: "Text/chapter-5.xhtml"
                        )
                    ),
                    listening: AudiobookPlaybackPresentation(
                        totalDuration: 36_000, partCount: 12, resumeSeconds: 12_400,
                        isCompleted: false, isCurrentAudiobook: false, isPlaying: false
                    ),
                    combinedUsesReadingPosition: true,
                    isBusy: false
                ),
                onContinueReading: {}, onContinueListening: {}, onContinueCombined: {},
                onStartReadingOver: {}, onStartListeningOver: {},
                onToggleReadingCompletion: {}, onToggleListeningCompletion: {}
            )
            .padding(PrismediaSpacing.extraLarge)
        }
    }
#endif
