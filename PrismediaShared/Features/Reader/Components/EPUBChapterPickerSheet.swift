#if os(iOS) || os(macOS)
    import SwiftUI

    struct EPUBChapterPickerSheet: View {
        @Environment(\.dismiss) private var dismiss
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

        let chapters: [EPUBChapter]
        let selectedIndex: Int
        let onSelect: (Int) -> Void

        var body: some View {
            NavigationStack {
                List {
                    ForEach(Array(chapters.enumerated()), id: \.element.id) { index, _ in
                        Button {
                            onSelect(index)
                            dismiss()
                        } label: {
                            FullWidthButtonLabel {
                                HStack {
                                    Text("Chapter \(index + 1)")
                                    Spacer()
                                    if index == selectedIndex {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(artworkPrimaryAccent)
                                    }
                                }
                            }
                        }
                        .accessibilityAddTraits(index == selectedIndex ? .isSelected : [])
                    }
                }
                .navigationTitle("Chapters")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
            .accessibilityIdentifier("epub-reader.chapters")
        }
    }

    #if DEBUG
        #Preview("EPUB Chapters") {
            EPUBChapterPickerSheet(
                chapters: [
                    EPUBChapter(
                        id: "one",
                        location: "chapter-1.xhtml",
                        fileURL: URL(fileURLWithPath: "/tmp/chapter-1.xhtml")
                    ),
                    EPUBChapter(
                        id: "two",
                        location: "chapter-2.xhtml",
                        fileURL: URL(fileURLWithPath: "/tmp/chapter-2.xhtml")
                    ),
                ],
                selectedIndex: 0,
                onSelect: { _ in }
            )
        }
    #endif
#endif
