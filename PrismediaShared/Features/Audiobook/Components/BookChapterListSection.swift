import SwiftUI

struct BookChapterListSection: View {
    @Environment(\.artworkSecondaryText) private var artworkSecondaryText

    let chapters: [BookChapterMapping]
    let isLoading: Bool
    let errorMessage: String?
    let readingProgressLabel: String?
    let listeningProgressLabel: String?
    let horizontalPadding: CGFloat
    let onRead: (BookChapterMapping) -> Void
    let onListen: (BookChapterMapping) -> Void
    let onCombined: (BookChapterMapping) -> Void
    let onRetry: () -> Void

    @ViewBuilder
    var body: some View {
        if isLoading || errorMessage != nil || !chapters.isEmpty {
            VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                header
                content
            }
            .padding(.horizontal, horizontalPadding)
            .accessibilityIdentifier("entity-detail.book-chapters")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
            Text("Read & Listen")
                .font(.caption.weight(.semibold))
                .foregroundStyle(artworkSecondaryText)
                .textCase(.uppercase)
            Text("Chapters")
                .font(.title3.bold())
                .foregroundStyle(PrismediaColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading, chapters.isEmpty {
            HStack(spacing: PrismediaSpacing.medium) {
                ProgressView()
                Text("Reading the EPUB contents…")
                    .font(.subheadline)
                    .foregroundStyle(artworkSecondaryText)
            }
            .padding(PrismediaSpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .prismediaPanel()
        } else if let errorMessage, chapters.isEmpty {
            ContentUnavailableView {
                Label("Couldn’t Load Chapters", systemImage: "books.vertical")
            } description: {
                Text(errorMessage)
            } actions: {
                PrismediaButton("Try Again", variant: .prominent, action: onRetry)
            }
            .frame(maxWidth: .infinity, minHeight: 180)
            .prismediaPanel()
        } else {
            LazyVStack(spacing: 0) {
                ForEach(chapters) { chapter in
                    BookChapterRow(
                        chapter: chapter,
                        number: chapter.order + 1,
                        readingProgressLabel: readingProgressLabel,
                        listeningProgressLabel: listeningProgressLabel,
                        onRead: { onRead(chapter) },
                        onListen: { onListen(chapter) },
                        onCombined: { onCombined(chapter) }
                    )

                    if chapter.id != chapters.last?.id {
                        Divider()
                            .overlay(PrismediaColor.borderSubtle)
                            .padding(.leading, PrismediaSpacing.large)
                    }
                }
            }
            .prismediaPanel()
        }
    }
}

#if DEBUG
    #Preview("Book Chapters · Mapped List") {
        ScrollView {
            BookChapterListSection(
                chapters: [
                    BookChapterMapping(
                        id: "chapter-1",
                        title: "Chapter 1: A New Beginning",
                        order: 0,
                        depth: 0,
                        readTarget: .epub(location: "Text/chapter-1.xhtml"),
                        audioTrack: MusicTrack(
                            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                            title: "Chapter 1"
                        ),
                        isCurrentReading: true,
                        isCurrentAudio: true
                    ),
                    BookChapterMapping(
                        id: "chapter-2",
                        title: "Chapter 2: The Crossing",
                        order: 1,
                        depth: 0,
                        readTarget: .epub(location: "Text/chapter-2.xhtml"),
                        audioTrack: MusicTrack(
                            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                            title: "Chapter 2"
                        ),
                        isCurrentReading: false,
                        isCurrentAudio: false
                    ),
                ],
                isLoading: false,
                errorMessage: nil,
                readingProgressLabel: "42% read",
                listeningProgressLabel: "1:12:08 of 8:43:19",
                horizontalPadding: PrismediaSpacing.large,
                onRead: { _ in },
                onListen: { _ in },
                onCombined: { _ in },
                onRetry: {}
            )
            .padding(.vertical, PrismediaSpacing.extraLarge)
        }
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }
#endif
