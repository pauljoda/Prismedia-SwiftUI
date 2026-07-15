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
            if isNew {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(PrismediaColor.accent)
                    .frame(width: 44, height: 44)
            } else {
                RemotePosterImage(
                    path: reference.artworkPath,
                    fallbackSeed: reference.title,
                    systemImage: kind == .person ? "person.crop.square" : "tag"
                )
                .frame(width: 44, height: 44)
                .clipShape(.rect(cornerRadius: PrismediaRadius.compact))
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
    #Preview("Entity Reference Search") {
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
#endif
