import SwiftUI

struct BookChapterRow: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
    @Environment(\.artworkSecondaryText) private var artworkSecondaryText

    let chapter: BookChapterMapping
    let number: Int
    let readingProgressLabel: String?
    let listeningProgressLabel: String?
    let onRead: () -> Void
    let onListen: () -> Void
    let onCombined: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.medium) {
                Text(number, format: .number.precision(.integerLength(2)))
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(artworkSecondaryText)

                Text(chapter.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(PrismediaColor.textPrimary)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }

            HStack(alignment: .center, spacing: PrismediaSpacing.medium) {
                currentProgress

                Spacer(minLength: PrismediaSpacing.small)

                ViewThatFits(in: .horizontal) {
                    actionButtons(compact: false)
                        .fixedSize()
                    actionButtons(compact: true)
                }
            }
        }
        .padding(.vertical, PrismediaSpacing.medium)
        .padding(.horizontal, PrismediaSpacing.large)
        .padding(.leading, CGFloat(min(chapter.depth, 3)) * PrismediaSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if chapter.isCurrentReading || chapter.isCurrentAudio {
                artworkPrimaryAccent.opacity(PrismediaOpacity.backdropSpectrum)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("entity-detail.book-chapter.\(chapter.id)")
    }

    @ViewBuilder
    private var currentProgress: some View {
        if chapter.isCurrentReading || chapter.isCurrentAudio {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                if chapter.isCurrentReading {
                    progressLabel(
                        title: "Reading",
                        detail: readingProgressLabel ?? "Here",
                        systemImage: "book.pages.fill",
                        color: artworkPrimaryAccent
                    )
                }
                if chapter.isCurrentAudio {
                    progressLabel(
                        title: "Listening",
                        detail: listeningProgressLabel ?? "Here",
                        systemImage: "waveform",
                        color: PrismediaColor.spectrumOrange
                    )
                }
            }
        }
    }

    private func progressLabel(
        title: String,
        detail: String,
        systemImage: String,
        color: Color
    ) -> some View {
        Label("\(title) · \(detail)", systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .lineLimit(1)
    }

    private func actionButtons(compact: Bool) -> some View {
        HStack(spacing: PrismediaSpacing.extraSmall) {
            if chapter.readTarget != nil {
                actionButton(
                    title: "Read",
                    systemImage: "book.pages",
                    hint: "Opens this chapter in the native reader",
                    compact: compact,
                    action: onRead
                )
            }
            if chapter.audioTrack != nil {
                actionButton(
                    title: "Listen",
                    systemImage: chapter.isCurrentAudio ? "headphones.circle.fill" : "headphones",
                    hint: "Plays this audiobook chapter",
                    compact: compact,
                    action: onListen
                )
            }
            if case .some(.epub) = chapter.readTarget, chapter.audioTrack != nil {
                actionButton(
                    title: "Combined",
                    systemImage: "square.2.layers.3d",
                    hint: "Opens this chapter and starts its companion audiobook chapter",
                    compact: compact,
                    action: onCombined
                )
            }
        }
    }

    private func actionButton(
        title: String,
        systemImage: String,
        hint: String,
        compact: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            if compact {
                Image(systemName: systemImage)
            } else {
                Label(title, systemImage: systemImage)
                    .font(.caption.weight(.semibold))
            }
        }
        .buttonStyle(.glass)
        .buttonBorderShape(compact ? .circle : .capsule)
        .frame(
            minWidth: PrismediaLayout.minimumHitTarget,
            minHeight: PrismediaLayout.minimumHitTarget
        )
        .contentShape(.rect)
        .accessibilityLabel(title)
        .accessibilityHint(hint)
    }
}

#if DEBUG
    #Preview("Book Chapter Row · Combined") {
        BookChapterRow(
            chapter: BookChapterMapping(
                id: "chapter-7",
                title: "Chapter 7: The Long Way Home",
                order: 6,
                depth: 0,
                readTarget: .epub(location: "Text/chapter-7.xhtml"),
                audioTrack: MusicTrack(
                    id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
                    title: "Chapter 7"
                ),
                isCurrentReading: true,
                isCurrentAudio: true
            ),
            number: 7,
            readingProgressLabel: "42% read",
            listeningProgressLabel: "1:12:08 of 8:43:19",
            onRead: {},
            onListen: {},
            onCombined: {}
        )
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }
#endif
