import SwiftUI

struct ComicReaderTableOfContentsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

    let chapters: [BookChapterSummary]
    let currentChapterID: UUID?
    let onSelect: (UUID) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if chapters.isEmpty {
                    ContentUnavailableView(
                        "No Table of Contents",
                        systemImage: "list.bullet.indent",
                        description: Text("This book does not include a readable chapter list.")
                    )
                } else {
                    List(chapters) { chapter in
                        chapterButton(chapter)
                    }
                }
            }
            .navigationTitle("Table of Contents")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .accessibilityIdentifier("comic-reader.contents")
    }

    private func chapterButton(_ chapter: BookChapterSummary) -> some View {
        Button {
            onSelect(chapter.id)
            dismiss()
        } label: {
            FullWidthButtonLabel {
                HStack {
                    Text(chapter.title)
                    Spacer()
                    if chapter.id == currentChapterID {
                        Image(systemName: "checkmark")
                            .foregroundStyle(artworkPrimaryAccent)
                    }
                }
            }
        }
        .accessibilityAddTraits(chapter.id == currentChapterID ? .isSelected : [])
        .accessibilityIdentifier("comic-reader.contents-row")
    }
}

#if DEBUG
    #Preview("Comic Reader Table of Contents") {
        ComicReaderTableOfContentsSheet(
            chapters: [
                BookChapterSummary(id: UUID(), title: "The First Signal", sortOrder: 0, pageCount: 24),
                BookChapterSummary(id: UUID(), title: "Static Between Stars", sortOrder: 1, pageCount: 18),
            ],
            currentChapterID: nil,
            onSelect: { _ in }
        )
        .preferredColorScheme(.dark)
    }
#endif
