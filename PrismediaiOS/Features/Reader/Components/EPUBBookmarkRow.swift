#if os(iOS) && canImport(ReadiumNavigator)
    import SwiftUI

    struct EPUBBookmarkRow: View {
        let bookmark: EPUBBookmark
        let isToggle: Bool
        let onOpen: () -> Void
        let onSetToggle: () -> Void

        var body: some View {
            HStack(spacing: PrismediaSpacing.medium) {
                Button(action: onOpen) {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        Text(bookmark.chapterTitle)
                            .font(.headline)
                            .lineLimit(1)

                        Text("Page \(bookmark.chapterPage) of \(bookmark.chapterPageCount)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)

                        Text(bookmark.createdAt, format: .dateTime.month(.abbreviated).day().year().hour().minute())
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    "Open bookmark, \(bookmark.chapterTitle), page \(bookmark.chapterPage) of \(bookmark.chapterPageCount)"
                )

                Button(
                    isToggle ? "Clear Toggle bookmark" : "Use as Toggle bookmark",
                    systemImage: isToggle ? "arrow.left.arrow.right.circle.fill" : "arrow.left.arrow.right.circle",
                    action: onSetToggle
                )
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .accessibilityIdentifier("epub-reader.bookmark-toggle")
            }
        }
    }

    #if DEBUG
        #Preview("EPUB Bookmark Row") {
            EPUBBookmarkRow(
                bookmark: EPUBBookmark(
                    id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                    locator: "appendix-a",
                    chapterTitle: "Appendix A",
                    chapterPage: 10,
                    chapterPageCount: 51,
                    createdAt: Date(timeIntervalSince1970: 1_700_000_000)
                ),
                isToggle: true,
                onOpen: {},
                onSetToggle: {}
            )
            .padding()
        }
    #endif
#endif
