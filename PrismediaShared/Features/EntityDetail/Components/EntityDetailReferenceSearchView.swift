import SwiftUI

struct EntityDetailReferenceSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: [EntityDetailReferenceDraft]
    @State private var searchText = ""
    @State private var results: [EntityDetailReferenceDraft] = []
    @State private var isSearching = false
    @State private var errorMessage: String?

    let title: String
    let kind: EntityKind
    let mode: EntityDetailReferenceSelectionMode
    let searchService: EntityDetailReferenceSearchService

    var body: some View {
        List {
            if let errorMessage {
                ContentUnavailableView(
                    "Couldn’t Load \(title)",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else if isSearching && results.isEmpty {
                HStack {
                    Spacer()
                    ProgressView("Searching")
                    Spacer()
                }
            } else {
                ForEach(availableResults) { result in
                    Button {
                        select(result)
                    } label: {
                        resultLabel(result, isNew: false)
                    }
                    .buttonStyle(.plain)
                }

                if canCreate {
                    Button {
                        select(.new(title: searchText, kind: kind))
                    } label: {
                        resultLabel(.new(title: searchText, kind: kind), isNew: true)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("entity-detail.edit.\(kind.rawValue).create")
                }

                if !isSearching && availableResults.isEmpty && !canCreate {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
        .navigationTitle("Select \(title)")
        .searchable(text: $searchText, prompt: "Search \(title.lowercased())")
        .toolbar {
            if mode == .multiple {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task(id: searchText) {
            await search()
        }
        .accessibilityIdentifier("entity-detail.edit.\(kind.rawValue).search")
    }

    private var availableResults: [EntityDetailReferenceDraft] {
        results.filter { !EntityDetailReferenceSelectionPolicy.contains($0, in: selection) }
    }

    private var canCreate: Bool {
        EntityDetailReferenceSelectionPolicy.canCreate(
            title: searchText,
            results: results,
            selection: selection
        )
    }

    private func select(_ reference: EntityDetailReferenceDraft) {
        switch mode {
        case .single:
            selection = [reference]
            dismiss()
        case .multiple:
            guard !EntityDetailReferenceSelectionPolicy.contains(reference, in: selection) else { return }
            selection.append(reference)
        }
    }

    private func search() async {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try? await Task.sleep(for: .milliseconds(200))
        }
        guard !Task.isCancelled else { return }
        isSearching = true
        errorMessage = nil
        do {
            results = try await searchService.search(kind: kind, query: searchText)
        } catch is CancellationError {
            return
        } catch {
            results = []
            errorMessage = error.localizedDescription
        }
        isSearching = false
    }

    private func resultLabel(_ reference: EntityDetailReferenceDraft, isNew: Bool) -> some View {
        HStack(spacing: PrismediaSpacing.small) {
            if let thumbnail = reference.sourceThumbnail {
                EntityThumbnailCompactArtworkView(item: thumbnail, width: 44)
            } else {
                EntityThumbnailCompactArtworkView(
                    title: reference.title,
                    kind: reference.kind,
                    artworkPath: reference.artworkPath,
                    width: 44
                )
            }

            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Text(isNew ? "Add \u{201c}\(reference.title)\u{201d}" : reference.title)
                    .foregroundStyle(PrismediaColor.textPrimary)
                if isNew {
                    Text("Create new \(kind.displayLabel.lowercased())")
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(.rect)
    }
}

#if DEBUG
    #Preview("Entity Reference Search · Person") {
        @Previewable @State var selection: [EntityDetailReferenceDraft] = []
        let person = EntityThumbnail(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            kind: .person,
            title: "Mara Voss"
        )

        PreviewShell {
            NavigationStack {
                EntityDetailReferenceSearchView(
                    selection: $selection,
                    title: "People",
                    kind: .person,
                    mode: .multiple,
                    searchService: EntityDetailReferenceSearchService(
                        loader: StaticEntityGridLoader(items: [person])
                    )
                )
            }
        }
    }

    #Preview("Entity Reference Search · Studio") {
        @Previewable @State var selection: [EntityDetailReferenceDraft] = []
        let studio = EntityThumbnail(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            kind: .studio,
            title: "Northlight Studio"
        )

        PreviewShell {
            NavigationStack {
                EntityDetailReferenceSearchView(
                    selection: $selection,
                    title: "Studio",
                    kind: .studio,
                    mode: .single,
                    searchService: EntityDetailReferenceSearchService(
                        loader: StaticEntityGridLoader(items: [studio])
                    )
                )
            }
        }
    }

    #Preview("Entity Reference Search · Tag") {
        @Previewable @State var selection: [EntityDetailReferenceDraft] = []
        let tag = EntityThumbnail(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            kind: .tag,
            title: "Atmospheric"
        )

        PreviewShell {
            NavigationStack {
                EntityDetailReferenceSearchView(
                    selection: $selection,
                    title: "Tags",
                    kind: .tag,
                    mode: .multiple,
                    searchService: EntityDetailReferenceSearchService(
                        loader: StaticEntityGridLoader(items: [tag])
                    )
                )
            }
        }
    }
#endif
