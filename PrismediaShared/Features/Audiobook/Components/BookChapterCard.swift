import SwiftUI

struct BookChapterCard: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
    @Environment(\.artworkSecondaryText) private var artworkSecondaryText

    let chapter: BookChapterMapping
    let number: Int
    let onRead: () -> Void
    let onListen: () -> Void
    let onCombined: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.medium) {
                Text(number, format: .number.precision(.integerLength(2)))
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(artworkSecondaryText)

                Text(chapter.title)
                    .font(.headline)
                    .foregroundStyle(PrismediaColor.textPrimary)
                    .lineLimit(3)

                Spacer(minLength: 0)
            }

            currentStatus

            Spacer(minLength: 0)

            HStack(spacing: PrismediaSpacing.small) {
                if chapter.readTarget != nil {
                    actionButton(
                        title: "Read",
                        systemImage: "book.pages",
                        hint: "Opens this chapter in the native reader",
                        action: onRead
                    )
                }
                if chapter.audioTrack != nil {
                    actionButton(
                        title: chapter.isCurrentAudio ? "Play or pause" : "Listen",
                        systemImage: chapter.isCurrentAudio ? "headphones.circle.fill" : "headphones",
                        hint: "Plays this audiobook chapter",
                        action: onListen
                    )
                }
                if case .some(.epub) = chapter.readTarget, chapter.audioTrack != nil {
                    actionButton(
                        title: "Read and listen",
                        systemImage: "square.2.layers.3d",
                        hint: "Opens this chapter and starts its companion audiobook chapter",
                        action: onCombined
                    )
                }
            }
        }
        .padding(PrismediaSpacing.large)
        .frame(maxWidth: .infinity, minHeight: 168, alignment: .topLeading)
        .prismediaCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("entity-detail.book-chapter.\(chapter.id)")
    }

    @ViewBuilder
    private var currentStatus: some View {
        if chapter.isCurrentReading || chapter.isCurrentAudio {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                if chapter.isCurrentReading {
                    Label("Reading here", systemImage: "book.pages.fill")
                        .foregroundStyle(artworkPrimaryAccent)
                }
                if chapter.isCurrentAudio {
                    Label("Listening here", systemImage: "waveform")
                        .foregroundStyle(PrismediaColor.spectrumOrange)
                }
            }
            .font(.caption.weight(.semibold))
        }
    }

    private func actionButton(
        title: String,
        systemImage: String,
        hint: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, systemImage: systemImage, action: action)
            .labelStyle(.iconOnly)
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .frame(
                minWidth: PrismediaLayout.minimumHitTarget,
                minHeight: PrismediaLayout.minimumHitTarget
            )
            .contentShape(.rect)
            .accessibilityHint(hint)
    }
}

#if DEBUG
    #Preview("Book Chapter Card · Combined") {
        BookChapterCard(
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
            onRead: {},
            onListen: {},
            onCombined: {}
        )
        .padding()
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }
#endif
