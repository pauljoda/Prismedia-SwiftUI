import SwiftUI

struct BookCombinedProgressCard: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

    let presentation: BookCombinedProgressPresentation
    let onContinueReading: () -> Void
    let onContinueListening: () -> Void
    let onContinueCombined: () -> Void
    let onStartOver: () -> Void
    let onToggleCompletion: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
            header
            progress
            actions
        }
        .padding(PrismediaSpacing.extraLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .prismediaPanel()
        .disabled(presentation.isBusy || presentation.isLoading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("combined-book-progress")
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.medium) {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Text("Your progress")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PrismediaColor.textSecondary)
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
                    .accessibilityLabel(
                        presentation.isLoading ? "Loading progress" : "Updating progress"
                    )
            }
            progressOptions
        }
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            HStack {
                Label("Overall", systemImage: "book.pages")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PrismediaColor.textPrimary)
                Spacer(minLength: PrismediaSpacing.large)
                Text(presentation.isLoading ? "100%" : "\(presentation.percent)%")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(PrismediaColor.textPrimary)
                    .redacted(reason: presentation.isLoading ? .placeholder : [])
                    .frame(minWidth: 48, alignment: .trailing)
            }
            ProgressView(value: Double(presentation.percent), total: 100)
                .tint(artworkPrimaryAccent)
                .opacity(presentation.isLoading ? 0 : 1)
                .overlay {
                    if presentation.isLoading {
                        Capsule()
                            .fill(PrismediaColor.controlFill)
                            .redacted(reason: .placeholder)
                    }
                }
                .frame(height: 4)
            Text(presentation.positionLabel ?? "Book position")
                .font(.caption)
                .foregroundStyle(PrismediaColor.textSecondary)
                .lineLimit(2)
                .opacity(
                    presentation.positionLabel == nil && !presentation.isLoading ? 0 : 1
                )
                .redacted(reason: presentation.isLoading ? .placeholder : [])
                .accessibilityHidden(presentation.positionLabel == nil)
            Label(
                presentation.chapterLabel ?? "Current chapter",
                systemImage: "bookmark.fill"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(PrismediaColor.textSecondary)
            .lineLimit(2)
            .opacity(
                presentation.chapterLabel == nil && !presentation.isLoading ? 0 : 1
            )
            .redacted(reason: presentation.isLoading ? .placeholder : [])
            .accessibilityHidden(presentation.chapterLabel == nil)
            Label(
                presentation.activitySeconds.map {
                    "\(MusicPresentation.clockTime($0)) total activity"
                } ?? "Book activity",
                systemImage: "timer"
            )
            .font(.caption)
            .foregroundStyle(PrismediaColor.textSecondary)
            .opacity(
                presentation.activitySeconds == nil && !presentation.isLoading ? 0 : 1
            )
            .redacted(reason: presentation.isLoading ? .placeholder : [])
            .accessibilityHidden(presentation.activitySeconds == nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Book progress")
        .accessibilityValue(
            presentation.isLoading
                ? "Loading book progress"
                : presentation.chapterLabel.map {
                    "\(presentation.percent) percent, current chapter \($0)"
                } ?? "\(presentation.percent) percent"
        )
    }

    private var actions: some View {
        PrismediaGlassButtonStack(spacing: PrismediaSpacing.medium) {
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
                "Opens the reader and starts the audiobook near the saved Book position"
            )
            .accessibilityIdentifier("combined-book-progress.continue-combined")
        }
        .frame(maxWidth: .infinity)
    }

    private var progressOptions: some View {
        Menu {
            Button("Start Over", systemImage: "arrow.counterclockwise", action: onStartOver)
            Button(
                presentation.status == .completed ? "Mark Incomplete" : "Mark Complete",
                systemImage: presentation.status == .completed ? "circle" : "checkmark.circle",
                action: onToggleCompletion
            )
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
                    progress: EntityProgressCapability(
                        currentEntityID: UUID(), unit: .cfi, index: 5_000, total: 10_000,
                        mode: .paged, completedAt: nil, updatedAt: nil, workIndex: nil,
                        workTotal: nil, location: "Text/chapter-5.xhtml"
                    ),
                    reading: nil,
                    chapterLabel: "Chapter 5: The Long Way Home",
                    activitySeconds: 7_420,
                    isLoading: false,
                    isBusy: false
                ),
                onContinueReading: {}, onContinueListening: {}, onContinueCombined: {},
                onStartOver: {}, onToggleCompletion: {}
            )
            .padding(PrismediaSpacing.extraLarge)
        }
    }

    #Preview("Combined Book Progress · Loading") {
        PreviewShell {
            BookCombinedProgressCard(
                presentation: BookCombinedProgressPresentation(
                    progress: nil,
                    reading: nil,
                    activitySeconds: nil,
                    isLoading: true,
                    isBusy: true
                ),
                onContinueReading: {}, onContinueListening: {}, onContinueCombined: {},
                onStartOver: {}, onToggleCompletion: {}
            )
            .padding(PrismediaSpacing.extraLarge)
        }
    }
#endif
