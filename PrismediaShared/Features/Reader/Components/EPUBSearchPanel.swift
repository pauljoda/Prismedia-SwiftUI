#if os(iOS) && canImport(ReadiumNavigator)
    import SwiftUI

    struct EPUBSearchPanel: View {
        @Environment(\.dismiss) private var dismiss
        @State private var query = ""
        @State private var searchTask: Task<Void, Never>?
        @State private var searchGeneration = 0

        @Binding var results: [EPUBSearchResult]
        @Binding var isSearching: Bool
        let onSearch: (String) async -> [EPUBSearchResult]
        let onSelect: (EPUBSearchResult) async -> Void

        var body: some View {
            NavigationStack {
                Group {
                    if isSearching {
                        PrismediaLoadingView("Searching book…")
                    } else if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        ContentUnavailableView(
                            "Search This Book",
                            systemImage: "text.magnifyingglass",
                            description: Text("Enter a word or phrase to find it in the publication.")
                        )
                    } else if results.isEmpty {
                        ContentUnavailableView.search(text: query)
                    } else {
                        List(results) { result in
                            Button {
                                Task {
                                    await onSelect(result)
                                    dismiss()
                                }
                            } label: {
                                FullWidthButtonLabel {
                                    EPUBSearchResultRow(result: result)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("epub-reader.search-result")
                        }
                    }
                }
                .navigationTitle("Search")
                .searchable(text: $query, prompt: "Search book")
                .onSubmit(of: .search) {
                    performSearch()
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
            }
            .onDisappear {
                searchTask?.cancel()
                searchGeneration &+= 1
                isSearching = false
            }
            .accessibilityIdentifier("epub-reader.search")
        }

        private func performSearch() {
            searchTask?.cancel()
            searchGeneration &+= 1
            let generation = searchGeneration
            let submittedQuery = query
            isSearching = true
            searchTask = Task {
                let values = await onSearch(submittedQuery)
                guard !Task.isCancelled, generation == searchGeneration else { return }
                results = values
                isSearching = false
                searchTask = nil
            }
        }
    }

    #if DEBUG
        #Preview("EPUB Search") {
            @Previewable @State var results = [
                EPUBSearchResult(
                    id: "one",
                    title: "The First Signal",
                    before: "The lighthouse answered from beyond the quiet ",
                    highlight: "sea",
                    after: ".",
                    chapterPage: 10,
                    chapterPageCount: 51,
                    location: "chapter-1.xhtml"
                )
            ]
            @Previewable @State var isSearching = false
            EPUBSearchPanel(
                results: $results,
                isSearching: $isSearching,
                onSearch: { _ in results },
                onSelect: { _ in }
            )
        }
    #endif
#endif
