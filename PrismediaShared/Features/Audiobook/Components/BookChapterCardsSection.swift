import SwiftUI

struct BookChapterCardsSection: View {
    @Environment(\.artworkSecondaryText) private var artworkSecondaryText

    let chapters: [BookChapterMapping]
    let isLoading: Bool
    let errorMessage: String?
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
            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(minimum: 260),
                        spacing: PrismediaSpacing.medium,
                        alignment: .topLeading
                    )
                ],
                alignment: .leading,
                spacing: PrismediaSpacing.medium
            ) {
                ForEach(chapters.enumerated(), id: \.element.id) { index, chapter in
                    BookChapterCard(
                        chapter: chapter,
                        number: index + 1,
                        onRead: { onRead(chapter) },
                        onListen: { onListen(chapter) },
                        onCombined: { onCombined(chapter) }
                    )
                }
            }
        }
    }
}
