import SwiftUI

/// Every pair a "Fill in order from here" step proposes, shown before any of them enters the draft.
/// Accepted pairs are saved as filled in order, so they link reading and listening exactly as listed.
struct BookChapterMappingFillReview: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

    let proposal: [BookChapterAudioMapping]
    let audioChapters: [BookAudioChapter]
    let readableChapters: [ReadableBookChapter]
    let onDiscard: () -> Void
    let onAccept: () -> Void

    var body: some View {
        let audioTitles = Dictionary(
            audioChapters.map { ($0.identity, $0.title) },
            uniquingKeysWith: { first, _ in first }
        )
        let readableTitles = Dictionary(
            readableChapters.map { ($0.id, $0.title) },
            uniquingKeysWith: { first, _ in first }
        )

        VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                Text("Review \(proposal.count) pairs filled in order")
                    .font(.headline)
                    .foregroundStyle(PrismediaColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(
                    "Each audio chapter is paired with the next readable chapter. Check every pair: saved pairs link reading and listening exactly as listed."
                )
                .font(.subheadline)
                .foregroundStyle(PrismediaColor.textSecondary)
            }

            LazyVStack(spacing: 0) {
                ForEach(Array(proposal.enumerated()), id: \.element.audioChapterIdentity) { index, pair in
                    let audioTitle = audioTitles[pair.audioChapterIdentity] ?? String(localized: "Audio chapter")
                    let readableTitle = readableTitles[pair.readableChapterKey] ?? pair.readableChapterKey
                    HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.medium) {
                        Text(index + 1, format: .number.precision(.integerLength(2)))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(PrismediaColor.textMuted)
                        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                            Label(audioTitle, systemImage: "waveform")
                                .foregroundStyle(PrismediaColor.textSecondary)
                            Label(readableTitle, systemImage: "book")
                                .foregroundStyle(PrismediaColor.textPrimary)
                        }
                        .font(.subheadline)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, PrismediaSpacing.small)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Audio chapter \(audioTitle) pairs with \(readableTitle)")

                    if index < proposal.count - 1 {
                        Divider()
                            .overlay(PrismediaColor.borderSubtle)
                    }
                }
            }
            .accessibilityLabel("Pairs filled in order")

            ViewThatFits(in: .horizontal) {
                HStack(spacing: PrismediaSpacing.medium) {
                    actions
                }
                VStack(spacing: PrismediaSpacing.medium) {
                    actions
                }
            }
        }
        .padding(PrismediaSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .prismediaPanel()
        .accessibilityIdentifier("book-chapter-mapping.fill-review")
    }

    @ViewBuilder
    private var actions: some View {
        PrismediaButton("Discard", systemImage: "xmark", form: .fill, action: onDiscard)

        PrismediaButton(
            "Use These Pairs",
            systemImage: "checkmark",
            variant: .prominent,
            form: .fill,
            primaryTint: artworkPrimaryAccent,
            action: onAccept
        )
        .disabled(proposal.isEmpty)
    }
}

#if DEBUG
    #Preview("Chapter Mapping · Fill Review") {
        let track = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let first = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        let second = UUID(uuidString: "00000000-0000-0000-0000-000000000102")!
        PreviewShell {
            ScrollView {
                BookChapterMappingFillReview(
                    proposal: [
                        BookChapterAudioMapping(
                            readableChapterKey: "one", audioTrackID: track, origin: .ordered, audioMarkerID: first
                        ),
                        BookChapterAudioMapping(
                            readableChapterKey: "two", audioTrackID: track, origin: .ordered, audioMarkerID: second
                        ),
                    ],
                    audioChapters: [
                        BookAudioChapter(
                            audioTrackID: track, audioMarkerID: first, title: "Opening Credits",
                            startSeconds: 0, endSeconds: 40
                        ),
                        BookAudioChapter(
                            audioTrackID: track, audioMarkerID: second, title: "Chapter 1",
                            startSeconds: 40, endSeconds: 1_900
                        ),
                    ],
                    readableChapters: [
                        ReadableBookChapter(
                            id: "one", title: "Prologue", order: 0, depth: 0, target: .epub(location: "Text/one.xhtml")
                        ),
                        ReadableBookChapter(
                            id: "two", title: "Chapter 1: A New Beginning", order: 1, depth: 0,
                            target: .epub(location: "Text/two.xhtml")
                        ),
                    ],
                    onDiscard: {},
                    onAccept: {}
                )
                .padding(PrismediaSpacing.extraLarge)
            }
        }
    }
#endif
