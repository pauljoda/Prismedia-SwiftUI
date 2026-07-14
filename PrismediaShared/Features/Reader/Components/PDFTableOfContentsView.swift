#if os(iOS) || os(macOS)
    import SwiftUI

    struct PDFTableOfContentsView: View {
        let items: [PDFReaderOutlineItem]
        let currentPage: Int
        let onSelect: (Int) -> Void
        let onClose: () -> Void

        var body: some View {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No Table of Contents",
                        systemImage: "list.bullet.indent",
                        description: Text("This PDF does not include an outline.")
                    )
                } else {
                    List {
                        OutlineGroup(items, children: \.children) { item in
                            if let pageIndex = item.pageIndex {
                                Button {
                                    onSelect(pageIndex)
                                } label: {
                                    FullWidthButtonLabel {
                                        HStack {
                                            Text(item.title)
                                                .foregroundStyle(.primary)
                                            Spacer()
                                            Text("\(pageIndex + 1)")
                                                .monospacedDigit()
                                                .foregroundStyle(.secondary)
                                                .accessibilityIdentifier("pdf-reader.contents-page")
                                        }
                                    }
                                }
                                .accessibilityLabel("\(item.title), page \(pageIndex + 1)")
                                .accessibilityAddTraits(pageIndex == currentPage ? .isSelected : [])
                                .accessibilityIdentifier("pdf-reader.contents-row")
                            } else {
                                Text(item.title)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Table of Contents")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark", action: onClose)
                        .accessibilityIdentifier("pdf-reader.contents-close")
                }
            }
        }
    }

    #if DEBUG
        #Preview("PDF Table of Contents") {
            NavigationStack {
                PDFTableOfContentsView(
                    items: [
                        PDFReaderOutlineItem(
                            id: "0",
                            title: "Opening",
                            pageIndex: 0,
                            children: [
                                PDFReaderOutlineItem(id: "0.0", title: "First Signal", pageIndex: 2)
                            ]
                        ),
                        PDFReaderOutlineItem(id: "1", title: "Afterword", pageIndex: 8),
                    ],
                    currentPage: 2,
                    onSelect: { _ in },
                    onClose: {}
                )
            }
        }
    #endif
#endif
