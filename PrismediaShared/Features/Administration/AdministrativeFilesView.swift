import SwiftUI

#if os(iOS) || os(macOS)
    struct AdministrativeFilesView: View {
        @State private var roots = AdministrativeCollectionLoadState<AdministrativeFileRoot>()
        @State private var path: [AdministrativeFileLocation] = []
        private let service: any FileAdministrationServicing

        init(service: any FileAdministrationServicing) { self.service = service }

        var body: some View {
            NavigationStack(path: $path) {
                List {
                    if let error = roots.errorMessage {
                        PrismediaRetryView(
                            title: "Couldn't Load Libraries", message: error, isRetrying: roots.isLoading,
                            retry: { Task { await load() } })
                    }
                    ForEach(roots.items) { root in
                        NavigationLink(
                            value: AdministrativeFileLocation(rootID: root.id, rootLabel: root.label, path: "")
                        ) {
                            AdministrativeFileRootRow(root: root)
                        }
                        .accessibilityIdentifier("administration.files.root.\(root.id.uuidString)")
                    }
                }
                .prismediaScreenBackground()
                .navigationTitle("Files")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        PrismediaToolbarActionButton("Refresh Libraries", systemImage: "arrow.clockwise") {
                            Task { await load() }
                        }
                        .disabled(roots.isLoading)
                    }
                }
                .navigationDestination(for: AdministrativeFileLocation.self) { location in
                    AdministrativeFileBrowserView(
                        location: location, roots: roots.items, service: service,
                        openDirectory: { path.append($0) })
                }
                .refreshable { await PrismediaRefreshAction.perform { await load() } }
                .overlay {
                    if roots.items.isEmpty && roots.errorMessage == nil {
                        if roots.isLoading {
                            PrismediaLoadingView("Loading libraries…")
                        } else {
                            ContentUnavailableView(
                                "No Library Roots", systemImage: "externaldrive",
                                description: Text("Add a library in Settings."))
                        }
                    }
                }
            }
            .task { await load() }
            .accessibilityIdentifier("administration.files")
        }

        private func load() async {
            let request = roots.begin()
            do {
                let loaded = try await service.roots()
                roots.succeed(loaded, request: request, isCancelled: Task.isCancelled)
                if let current = path.first, !Task.isCancelled,
                    !roots.items.contains(where: { $0.id == current.rootID })
                {
                    path.removeAll()
                }
            } catch {
                roots.fail(error, request: request, isCancelled: Task.isCancelled)
            }
        }
    }

    #if DEBUG
        #Preview("Files") { AdministrativeFilesView(service: Step4AdministrationPreviewService()) }
        #Preview("Files · Accessibility") {
            AdministrativeFilesView(service: Step4AdministrationPreviewService())
                .environment(\.dynamicTypeSize, .accessibility3)
        }
    #endif
#endif
