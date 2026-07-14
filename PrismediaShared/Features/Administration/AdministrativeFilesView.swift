import SwiftUI

struct AdministrativeFilesView: View {
    @State private var roots: [AdministrativeFileRoot] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    private let service: any AdministrationServicing

    init(service: any AdministrationServicing) { self.service = service }

    var body: some View {
        NavigationStack {
            List(roots) { root in
                NavigationLink(value: AdministrativeFileLocation(rootID: root.id, rootLabel: root.label, path: "")) {
                    Label {
                        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                            Text(root.label)
                            Text(root.path).font(.caption).foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: root.enabled ? "externaldrive.fill" : "externaldrive.badge.xmark")
                    }
                }
            }
            .prismediaScreenBackground()
            .overlay {
                if isLoading && roots.isEmpty {
                    PrismediaLoadingView("Loading roots…")
                } else if isLoading {
                    ProgressView("Loading roots…")
                } else if roots.isEmpty {
                    ContentUnavailableView(
                        "No Library Roots", systemImage: "externaldrive",
                        description: Text("Add a watched root in server settings."))
                }
            }
            .navigationTitle("Files")
            .navigationDestination(for: AdministrativeFileLocation.self) { location in
                AdministrativeFileBrowserView(location: location, service: service)
            }
            .refreshable { await load() }
            .alert(
                "Files Unavailable",
                isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
        .task { await load() }
        .accessibilityIdentifier("administration.files")
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do { roots = try await service.fileRoots() } catch { errorMessage = error.localizedDescription }
    }
}

#if DEBUG
    #Preview { AdministrativeFilesView(service: AdministrativePreviewService()) }
#endif
