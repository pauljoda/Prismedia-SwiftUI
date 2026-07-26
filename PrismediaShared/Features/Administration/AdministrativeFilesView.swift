import SwiftUI

#if os(iOS) || os(macOS)
    struct AdministrativeFilesView: View {
        @State private var roots: [AdministrativeFileRoot] = []
        @State private var selectedRootID: UUID?
        @State private var path: [AdministrativeFileLocation] = []
        @State private var regularLocation: AdministrativeFileLocation?
        @State private var isLoading = true
        @State private var errorMessage: String?
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        private let service: any FileAdministrationServicing

        init(service: any FileAdministrationServicing) { self.service = service }

        var body: some View {
            #if os(macOS)
                macContent
            #else
                adaptiveContent
            #endif
        }

        #if os(macOS)
            private var macContent: some View {
                NavigationStack(path: $path) {
                    Group {
                        if let root = roots.first(where: { $0.id == selectedRootID }) {
                            AdministrativeFileBrowserView(
                                location: .init(rootID: root.id, rootLabel: root.label, path: ""),
                                roots: roots,
                                service: service,
                                navigatesInPlace: false,
                                openDirectory: { path.append($0) }
                            )
                            .navigationDestination(for: AdministrativeFileLocation.self) { child in
                                AdministrativeFileBrowserView(
                                    location: child,
                                    roots: roots,
                                    service: service,
                                    navigatesInPlace: false,
                                    openDirectory: { path.append($0) }
                                )
                            }
                        } else {
                            ContentUnavailableView(
                                "No Library Root",
                                systemImage: "externaldrive",
                                description: Text("Add a watched root in Libraries settings.")
                            )
                        }
                    }
                    .navigationTitle("Files")
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Picker("Library Root", selection: $selectedRootID) {
                                ForEach(roots) { root in
                                    Label(
                                        root.label,
                                        systemImage: root.enabled
                                            ? "externaldrive.fill"
                                            : "externaldrive.badge.xmark"
                                    )
                                    .tag(Optional(root.id))
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(minWidth: 180)
                        }

                        ToolbarItem(placement: .primaryAction) {
                            Button("Refresh Roots", systemImage: "arrow.clockwise") {
                                Task { await load() }
                            }
                            .labelStyle(.iconOnly)
                        }
                    }
                }
                .prismediaScreenBackground()
                .task { await load() }
                .onChange(of: selectedRootID) { path.removeAll() }
                .alert("Files Unavailable", isPresented: errorIsPresented) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage ?? "Unknown error")
                }
                .accessibilityIdentifier("administration.files")
            }
        #endif

        #if os(iOS)
            private var adaptiveContent: some View {
                NavigationSplitView {
                    List(roots, selection: $selectedRootID) { root in
                        NavigationLink(value: root.id) {
                            Label {
                                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                                    Text(root.label)
                                    Text(root.path)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(.rect)
                            } icon: {
                                Image(systemName: root.enabled ? "externaldrive.fill" : "externaldrive.badge.xmark")
                            }
                        }
                        .accessibilityIdentifier("administration.files.root.\(root.id.uuidString)")
                    }
                    .navigationTitle("Files")
                    .refreshable {
                        await PrismediaRefreshAction.perform {
                            await load()
                        }
                    }
                    .overlay {
                        if isLoading, roots.isEmpty {
                            PrismediaLoadingView("Loading roots…")
                        } else if roots.isEmpty {
                            ContentUnavailableView(
                                "No Library Roots",
                                systemImage: "externaldrive",
                                description: Text("Add a watched root in Libraries settings."))
                        }
                    }
                } detail: {
                    if let root = roots.first(where: { $0.id == selectedRootID }) {
                        NavigationStack(path: $path) {
                            AdministrativeFileBrowserView(
                                location: regularLocation
                                    ?? .init(rootID: root.id, rootLabel: root.label, path: ""),
                                roots: roots,
                                service: service,
                                navigatesInPlace: usesInPlaceNavigation,
                                openDirectory: openDirectory
                            )
                            .navigationDestination(for: AdministrativeFileLocation.self) { child in
                                AdministrativeFileBrowserView(
                                    location: child,
                                    roots: roots,
                                    service: service,
                                    navigatesInPlace: false,
                                    openDirectory: { path.append($0) }
                                )
                            }
                        }
                    } else {
                        ContentUnavailableView(
                            "Select a Library Root",
                            systemImage: "folder",
                            description: Text("Filesystem actions stay inside the selected watched root."))
                    }
                }
                .prismediaScreenBackground()
                .task { await load() }
                .onChange(of: selectedRootID) {
                    path.removeAll()
                    regularLocation = nil
                }
                .alert(
                    "Files Unavailable",
                    isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
                ) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage ?? "Unknown error")
                }
                .accessibilityIdentifier("administration.files")
            }
        #endif

        private func load() async {
            isLoading = true
            defer { isLoading = false }
            do {
                let loaded = try await service.roots()
                roots = loaded
                if selectedRootID == nil || !loaded.contains(where: { $0.id == selectedRootID }) {
                    selectedRootID = loaded.first?.id
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        private var usesInPlaceNavigation: Bool {
            #if os(iOS)
                horizontalSizeClass == .regular
            #else
                false
            #endif
        }

        private var errorIsPresented: Binding<Bool> {
            Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        }

        private func openDirectory(_ location: AdministrativeFileLocation) {
            if usesInPlaceNavigation {
                regularLocation = location
            } else {
                path.append(location)
            }
        }
    }

    #if DEBUG
        #Preview("Files · Regular") {
            AdministrativeFilesView(service: Step4AdministrationPreviewService())
                .frame(width: 1_100, height: 720)
        }

        #Preview("Files · Accessibility") {
            AdministrativeFilesView(service: Step4AdministrationPreviewService())
                .environment(\.dynamicTypeSize, .accessibility3)
        }
    #endif
#endif
