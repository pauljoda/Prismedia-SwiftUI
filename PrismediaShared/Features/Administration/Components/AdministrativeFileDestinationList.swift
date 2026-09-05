import SwiftUI

#if os(iOS) || os(macOS)
    struct AdministrativeFileDestinationList: View {
        @State private var listing = AdministrativeCollectionLoadState<AdministrativeFileEntry>()
        @State private var loadedLocation: AdministrativeFileLocation?
        let entry: AdministrativeFileEntry
        let location: AdministrativeFileLocation
        let roots: [AdministrativeFileRoot]
        @Binding var targetRootID: UUID
        let allowsRootSelection: Bool
        let isMoving: Bool
        let errorMessage: String?
        let service: any FileAdministrationServicing
        let cancel: () -> Void
        let move: () -> Void

        var body: some View {
            List {
                Section {
                    Label(entry.name, systemImage: entry.isDirectory ? "folder" : "doc")
                        .fixedSize(horizontal: false, vertical: true)
                    if allowsRootSelection {
                        Picker("Library", selection: $targetRootID) {
                            ForEach(roots) { root in Text(root.label).tag(root.id) }
                        }
                    }
                } header: {
                    Text("Moving")
                } footer: {
                    Text("Choose a folder. The name stays the same.")
                }
                Section {
                    if let error = listing.errorMessage {
                        PrismediaRetryView(
                            title: "Couldn't Load Folders", message: error,
                            isRetrying: listing.isLoading, retry: { Task { await load() } })
                    }
                    if listing.isLoading && listing.items.isEmpty {
                        ProgressView("Loading folders…")
                    }
                    ForEach(listing.items.filter(\.isDirectory)) { folder in
                        NavigationLink(
                            value: AdministrativeFileLocation(
                                rootID: folder.rootID, rootLabel: location.rootLabel, path: folder.path)
                        ) {
                            Label(folder.name, systemImage: "folder")
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .disabled(isSourceOrDescendant(folder))
                    }
                    if !listing.isLoading && listing.errorMessage == nil
                        && !listing.items.contains(where: \.isDirectory)
                    {
                        Text("No subfolders").foregroundStyle(.secondary)
                    }
                } header: {
                    Text(location.path.isEmpty ? location.rootLabel : location.path)
                }
                Section {
                    if let errorMessage { Text(errorMessage).foregroundStyle(PrismediaColor.destructive) }
                    PrismediaButton(
                        "Move Here", systemImage: "folder", form: .fill,
                        isLoading: isMoving, loadingTitle: "Moving…", action: move
                    )
                    .disabled(!canMove || listing.isLoading || listing.errorMessage != nil)
                } footer: {
                    if !canMove { Text("This item is already in this folder.") }
                }
            }
            .disabled(isMoving)
            .prismediaScreenBackground()
            .navigationTitle("Move")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    PrismediaToolbarActionButton("Cancel", systemImage: "xmark", action: cancel).disabled(isMoving)
                }
            }
            .task(id: location) { await load() }
        }

        private var canMove: Bool {
            (try? AdministrativeFilePathPolicy.moveTargetPath(for: entry, into: location)) != nil
        }

        private func isSourceOrDescendant(_ folder: AdministrativeFileEntry) -> Bool {
            entry.isDirectory && entry.rootID == folder.rootID
                && (folder.path == entry.path || folder.path.hasPrefix(entry.path + "/"))
        }

        private func load() async {
            let requestedLocation = location
            let request = listing.begin(clearingItems: loadedLocation != requestedLocation)
            loadedLocation = requestedLocation
            do {
                let response = try await service.children(
                    rootID: requestedLocation.rootID, path: requestedLocation.path)
                listing.succeed(response.entries, request: request, isCancelled: Task.isCancelled)
            } catch { listing.fail(error, request: request, isCancelled: Task.isCancelled) }
        }
    }
#endif
