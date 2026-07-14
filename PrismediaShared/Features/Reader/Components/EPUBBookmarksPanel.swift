#if os(iOS) && canImport(ReadiumNavigator)
    import SwiftUI

    struct EPUBBookmarksPanel: View {
        @State private var openingBookmarkID: UUID?
        @State private var showsOpenError = false

        @Binding var state: EPUBBookmarksState
        let canAddBookmark: Bool
        let onAdd: () -> EPUBBookmark?
        let onOpen: (EPUBBookmark) async -> Bool
        let onClose: () -> Void

        var body: some View {
            NavigationStack {
                List {
                    Section {
                        Button("Add Current Location", systemImage: "bookmark.badge.plus", action: addBookmark)
                            .disabled(!canAddBookmark)
                            .accessibilityIdentifier("epub-reader.add-bookmark")
                    }

                    if state.bookmarks.isEmpty {
                        ContentUnavailableView(
                            "No Bookmarks",
                            systemImage: "bookmark",
                            description: Text(
                                "Bookmarks you add will include this book’s chapter, page, date, and time.")
                        )
                    } else {
                        Section("Saved Locations") {
                            ForEach(state.bookmarks) { bookmark in
                                EPUBBookmarkRow(
                                    bookmark: bookmark,
                                    isToggle: state.toggleBookmarkID == bookmark.id,
                                    onOpen: { open(bookmark) },
                                    onSetToggle: { setToggle(bookmark) }
                                )
                                .swipeActions {
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        delete(bookmark)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Bookmarks")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", action: onClose)
                    }
                }
            }
            .accessibilityIdentifier("epub-reader.bookmarks")
            .alert("Couldn’t Open Bookmark", isPresented: $showsOpenError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("That saved location is no longer available in this edition of the book.")
            }
        }

        private func addBookmark() {
            guard let bookmark = onAdd() else { return }
            state.bookmarks.insert(bookmark, at: 0)
        }

        private func open(_ bookmark: EPUBBookmark) {
            guard openingBookmarkID == nil else { return }
            openingBookmarkID = bookmark.id
            Task {
                let didOpen = await onOpen(bookmark)
                openingBookmarkID = nil
                if didOpen {
                    onClose()
                } else {
                    showsOpenError = true
                }
            }
        }

        private func setToggle(_ bookmark: EPUBBookmark) {
            state.toggleBookmarkID = state.toggleBookmarkID == bookmark.id ? nil : bookmark.id
        }

        private func delete(_ bookmark: EPUBBookmark) {
            state.bookmarks.removeAll { $0.id == bookmark.id }
            if state.toggleBookmarkID == bookmark.id {
                state.toggleBookmarkID = nil
            }
        }
    }

    #if DEBUG
        #Preview("EPUB Bookmarks") {
            @Previewable @State var state = EPUBBookmarksState(
                bookmarks: [
                    EPUBBookmark(
                        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                        locator: "appendix-a",
                        chapterTitle: "Appendix A",
                        chapterPage: 10,
                        chapterPageCount: 51,
                        createdAt: Date(timeIntervalSince1970: 1_700_000_000)
                    )
                ],
                toggleBookmarkID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")
            )
            EPUBBookmarksPanel(
                state: $state,
                canAddBookmark: true,
                onAdd: { nil },
                onOpen: { _ in false },
                onClose: {}
            )
        }
    #endif
#endif
