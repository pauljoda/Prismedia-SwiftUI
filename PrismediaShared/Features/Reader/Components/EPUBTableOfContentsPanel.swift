#if os(iOS) || os(macOS)
    import SwiftUI

    struct EPUBTableOfContentsPanel: View {
        let items: [EPUBTableOfContentsItem]
        let onSelect: (EPUBTableOfContentsItem) -> Void
        let onClose: () -> Void

        var body: some View {
            NavigationStack {
                Group {
                    if items.isEmpty {
                        ContentUnavailableView(
                            "No Table of Contents",
                            systemImage: "list.bullet.indent",
                            description: Text("This publication does not include a readable contents list.")
                        )
                    } else {
                        List {
                            OutlineGroup(items, children: \.outlineChildren) { item in
                                Button {
                                    onSelect(item)
                                    onClose()
                                } label: {
                                    FullWidthButtonLabel {
                                        Text(item.title)
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(item.location == nil)
                                .accessibilityIdentifier("epub-reader.contents-row")
                            }
                        }
                    }
                }
                .navigationTitle("Contents")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", action: onClose)
                    }
                }
            }
            .accessibilityIdentifier("epub-reader.contents")
        }
    }

    #if DEBUG
        #Preview("EPUB Contents") {
            EPUBTableOfContentsPanel(
                items: [
                    EPUBTableOfContentsItem(
                        title: "Part One",
                        location: "Text/part-one.xhtml",
                        children: [
                            EPUBTableOfContentsItem(
                                title: "The Signal",
                                location: "Text/part-one.xhtml#signal"
                            )
                        ]
                    )
                ],
                onSelect: { _ in },
                onClose: {}
            )
        }
    #endif
#endif
