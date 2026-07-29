import SwiftUI

struct BookChapterListSection: View {
    @Environment(\.artworkSecondaryText) private var artworkSecondaryText
    @State private var isExpanded = true

    let chapters: [BookChapterMapping]
    let isLoading: Bool
    let errorMessage: String?
    let progressLabel: String?
    let horizontalPadding: CGFloat
    let onRead: (BookChapterMapping) -> Void
    let onListen: (BookChapterMapping) -> Void
    let onCombined: (BookChapterMapping) -> Void
    let onRetry: () -> Void

    @ViewBuilder
    var body: some View {
        if isLoading || errorMessage != nil || !chapters.isEmpty {
            LazyVStack(alignment: .leading, spacing: 0) {
                #if os(tvOS)
                    Button {
                        isExpanded.toggle()
                    } label: {
                        HStack(spacing: PrismediaSpacing.medium) {
                            header
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.down")
                                .rotationEffect(.degrees(isExpanded ? 0 : -90))
                                .foregroundStyle(artworkSecondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)

                    if isExpanded {
                        content
                            .padding(.top, PrismediaSpacing.large)
                    }
                #else
                    DisclosureGroup(isExpanded: $isExpanded) {
                        content
                            .padding(.top, PrismediaSpacing.large)
                    } label: {
                        header
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(.rect)
                    }
                #endif
            }
            .padding(.horizontal, horizontalPadding)
            .accessibilityIdentifier("entity-detail.book-chapters")
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
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
                        progressLabel: progressLabel,
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
                        isCurrentProgress: true
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
                        isCurrentProgress: false
                    ),
                ],
                isLoading: false,
                errorMessage: nil,
                progressLabel: "42% read",
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
