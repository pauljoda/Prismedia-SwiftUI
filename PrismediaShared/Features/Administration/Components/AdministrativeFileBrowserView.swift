import SwiftUI

struct AdministrativeFileBrowserView: View {
    @State private var entries: [AdministrativeFileEntry] = []
    @State private var isLoading = true
    @State private var message: String?
    let location: AdministrativeFileLocation
    let service: any AdministrationServicing

    var body: some View {
        List(entries) { entry in
            if entry.isDirectory {
                NavigationLink(
                    value: AdministrativeFileLocation(
                        rootID: entry.rootID, rootLabel: location.rootLabel, path: entry.path)
                ) {
                    row(entry)
                }
            } else {
                row(entry)
            }
        }
        .overlay {
            if isLoading && entries.isEmpty {
                PrismediaLoadingView("Loading folder…")
            } else if isLoading {
                ProgressView("Loading folder…")
            } else if entries.isEmpty {
                ContentUnavailableView(
                    "Empty Folder", systemImage: "folder", description: Text("No visible files or folders are here."))
            }
        }
        .navigationTitle(
            location.path.isEmpty ? location.rootLabel : URL(fileURLWithPath: location.path).lastPathComponent
        )
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Rescan", systemImage: "arrow.clockwise") { Task { await rescan() } }
                    .disabled(isLoading)
            }
        }
        .refreshable { await load() }
        .task(id: location) { await load() }
        .alert("Files", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }

    private func row(_ entry: AdministrativeFileEntry) -> some View {
        Label {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Text(entry.name)
                if let size = entry.sizeBytes {
                    Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)).font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            Image(systemName: entry.isDirectory ? "folder.fill" : "doc")
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do { entries = try await service.fileChildren(rootID: location.rootID, path: location.path).entries } catch {
            message = error.localizedDescription
        }
    }

    private func rescan() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await service.rescan(rootID: location.rootID, path: location.path)
            message = "Queued \(result.scansQueued) scan job\(result.scansQueued == 1 ? "" : "s")."
        } catch { message = error.localizedDescription }
    }
}

#if DEBUG
    #Preview {
        AdministrativeFileBrowserView(
            location: AdministrativeFileLocation(
                rootID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                rootLabel: "Movies",
                path: ""
            ),
            service: AdministrativePreviewService()
        )
    }
#endif
