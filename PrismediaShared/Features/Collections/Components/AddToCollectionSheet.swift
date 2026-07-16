#if os(iOS) || os(macOS)
    import SwiftUI

    /// Collection picker for entity grids, detail pages, and compact actions.
    struct AddToCollectionSheet: View {
        @Environment(\.dismiss) private var dismiss
        @Environment(PrismediaAppEnvironment.self) private var environment

        let items: [CollectionEntityReference]
        let onCompletion: (EntityGridMutationResult) -> Void
        private let loadsCollections: Bool

        @State private var collections: [EntityThumbnail] = []
        @State private var searchText = ""
        @State private var loading = true
        @State private var pendingCollectionID: UUID?
        @State private var addedCollectionIDs = Set<UUID>()
        @State private var errorMessage: String?

        init(
            items: [CollectionEntityReference],
            onCompletion: @escaping (EntityGridMutationResult) -> Void = { _ in }
        ) {
            self.items = items
            self.onCompletion = onCompletion
            loadsCollections = true
        }

        #if DEBUG
            init(
                items: [CollectionEntityReference],
                previewCollections: [EntityThumbnail],
                previewIsLoading: Bool = false
            ) {
                self.items = items
                onCompletion = { _ in }
                loadsCollections = false
                _collections = State(initialValue: previewCollections)
                _loading = State(initialValue: previewIsLoading)
            }
        #endif

        var body: some View {
            NavigationStack {
                Group {
                    if loading {
                        PrismediaLoadingView("Loading collections…")
                    } else if collections.isEmpty {
                        ContentUnavailableView(
                            "No Collections",
                            systemImage: "rectangle.stack",
                            description: Text("Create a collection first, then it will appear here.")
                        )
                    } else {
                        collectionList
                    }
                }
                .navigationTitle("Add to Collection")
                #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                #endif
                .searchable(text: $searchText, prompt: "Filter collections")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .task {
                guard loadsCollections else { return }
                await loadCollections()
            }
            .alert("Couldn’t Add to Collection", isPresented: errorPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
        }

        private var collectionList: some View {
            List(filteredCollections) { collection in
                Button {
                    Task { await add(to: collection) }
                } label: {
                    HStack(spacing: PrismediaSpacing.medium) {
                        RemotePosterImage(
                            path: collection.bestCoverPath,
                            fallbackSeed: collection.title,
                            systemImage: "rectangle.stack"
                        )
                        .frame(
                            width: PrismediaLayout.minimumHitTarget,
                            height: PrismediaLayout.minimumHitTarget
                        )
                        .clipShape(RoundedRectangle(cornerRadius: PrismediaRadius.compact, style: .continuous))

                        Text(collection.title)
                            .foregroundStyle(.primary)

                        Spacer()

                        if pendingCollectionID == collection.id {
                            ProgressView()
                        } else if addedCollectionIDs.contains(collection.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(PrismediaColor.accent)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(pendingCollectionID != nil || addedCollectionIDs.contains(collection.id))
                .accessibilityIdentifier("add-to-collection.option.\(collection.id.uuidString)")
            }
            .listStyle(.plain)
        }

        private var filteredCollections: [EntityThumbnail] {
            let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !term.isEmpty else { return collections }
            return collections.filter { $0.title.localizedCaseInsensitiveContains(term) }
        }

        private var errorPresented: Binding<Bool> {
            Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        }

        private func loadCollections() async {
            guard let client = environment.client else {
                loading = false
                return
            }
            do {
                collections = try await client.loadCollectionOptions().sorted {
                    $0.title.localizedStandardCompare($1.title) == .orderedAscending
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            loading = false
        }

        private func add(to collection: EntityThumbnail) async {
            guard let client = environment.client else { return }
            pendingCollectionID = collection.id
            defer { pendingCollectionID = nil }
            do {
                var succeededIDs = Set<UUID>()
                var failures: [EntityGridMutationFailure] = []
                for item in items {
                    do {
                        if try await client.addToCollection(collectionID: collection.id, item: item) {
                            succeededIDs.insert(item.entityID)
                        } else {
                            failures.append(failure(for: item, message: "The server did not add this item."))
                        }
                    } catch {
                        failures.append(failure(for: item, message: error.localizedDescription))
                    }
                }
                let result = EntityGridMutationResult(
                    succeededIDs: succeededIDs,
                    failures: failures
                )
                onCompletion(result)
                if failures.isEmpty {
                    addedCollectionIDs.insert(collection.id)
                } else {
                    errorMessage = failureMessage(failures)
                }
            }
        }

        private func failure(
            for item: CollectionEntityReference,
            message: String
        ) -> EntityGridMutationFailure {
            EntityGridMutationFailure(
                entityID: item.entityID,
                title: item.entityType.displayLabel,
                message: message
            )
        }

        private func failureMessage(_ failures: [EntityGridMutationFailure]) -> String {
            let count = failures.count
            let details = failures.prefix(3).map { "\($0.title): \($0.message)" }.joined(separator: "\n")
            return "\(count) item\(count == 1 ? "" : "s") could not be added.\n\(details)"
        }
    }

    #if DEBUG
        #Preview("Add to Collection · Populated") {
            let item = CollectionEntityReference(
                entityType: .audioLibrary,
                entityID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
            )
            let collections = [
                EntityThumbnail(
                    id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                    kind: .collection,
                    title: "Weekend Favorites"
                ),
                EntityThumbnail(
                    id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                    kind: .collection,
                    title: "Watch With Friends"
                ),
            ]

            PreviewShell {
                AddToCollectionSheet(
                    items: [item],
                    previewCollections: collections
                )
            }
        }

        #Preview("Add to Collection · Empty") {
            PreviewShell {
                AddToCollectionSheet(
                    items: [],
                    previewCollections: []
                )
            }
        }

        #Preview("Add to Collection · Loading") {
            PreviewShell {
                AddToCollectionSheet(
                    items: [],
                    previewCollections: [],
                    previewIsLoading: true
                )
            }
        }
    #endif
#endif
