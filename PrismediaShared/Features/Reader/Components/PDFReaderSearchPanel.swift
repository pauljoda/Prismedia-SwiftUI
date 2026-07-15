#if os(iOS) || os(macOS)
    import Foundation
    import SwiftUI

    struct PDFReaderSearchPanel: View {
        @Environment(\.dismiss) private var dismiss

        @Binding var query: String
        let selectedResult: Int?
        let resultCount: Int
        let isSearching: Bool
        let onSearch: () -> Void
        let onPrevious: () -> Void
        let onNext: () -> Void

        var body: some View {
            NavigationStack {
                VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                    HStack {
                        TextField("Search PDF", text: $query)
                            .prismediaTextInputStyle(surface: .embedded)
                            .onSubmit(onSearch)
                            .accessibilityIdentifier("pdf-reader.search-field")

                        Button("Search", systemImage: "magnifyingglass", action: onSearch)
                            .labelStyle(.iconOnly)
                            .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    HStack {
                        if isSearching {
                            ProgressView("Searching…")
                                .controlSize(.small)
                        } else {
                            Text(resultLabel)
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("pdf-reader.search-results")
                        }

                        Spacer()

                        Button("Previous Result", systemImage: "chevron.up", action: onPrevious)
                            .labelStyle(.iconOnly)
                            .disabled(resultCount == 0 || isSearching)

                        Button("Next Result", systemImage: "chevron.down", action: onNext)
                            .labelStyle(.iconOnly)
                            .disabled(resultCount == 0 || isSearching)
                    }

                    Spacer()
                }
                .padding()
                .navigationTitle("Search PDF")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
            .accessibilityIdentifier("pdf-reader.search-sheet")
        }

        private var resultLabel: String {
            guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return "Enter text to search"
            }
            guard let selectedResult, resultCount > 0 else { return "No results" }
            return "Result \(selectedResult + 1) of \(resultCount)"
        }
    }

    #if DEBUG
        #Preview("PDF Search") {
            @Previewable @State var query = "signal"
            PDFReaderSearchPanel(
                query: $query,
                selectedResult: 1,
                resultCount: 4,
                isSearching: false,
                onSearch: {},
                onPrevious: {},
                onNext: {}
            )
        }
    #endif
#endif
