import SwiftUI

struct AdministrativeLibraryFolderList: View {
    @State private var selection = AdministrativeLibraryFolderSelection()
    let path: String
    let service: any LibraryAdministrationServicing
    let cancel: () -> Void
    let select: (String) -> Void

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    Text("Server folder").font(.subheadline).foregroundStyle(.secondary)
                    Text(selection.folder?.path ?? (path.isEmpty ? "Loading…" : path))
                        .font(.body.monospaced())
                        .fixedSize(horizontal: false, vertical: true)
                        .prismediaTextSelection()
                    PrismediaButton("Use This Folder", systemImage: "checkmark", form: .fill) {
                        if let selected = selection.selectedPath { select(selected) }
                    }
                    .disabled(selection.selectedPath == nil)
                }
            }
            if let error = selection.errorMessage {
                Section {
                    Text(error).foregroundStyle(PrismediaColor.destructive)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Retry", systemImage: "arrow.clockwise") { Task { await load() } }
                }
            }
            if let folder = selection.folder {
                if let parent = folder.parentPath {
                    Section {
                        NavigationLink(value: parent) {
                            Label("Parent Folder", systemImage: "arrow.up")
                        }
                    }
                }
                Section("Folders") {
                    if folder.directories.isEmpty {
                        Text("No subfolders").foregroundStyle(.secondary)
                    }
                    ForEach(folder.directories) { directory in
                        NavigationLink(value: directory.path) {
                            Label(directory.name, systemImage: "folder")
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            } else if selection.isLoading {
                Section { ProgressView("Loading folders…") }
            }
        }
        .prismediaScreenBackground()
        .navigationTitle("Choose Folder")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                PrismediaToolbarActionButton("Cancel", systemImage: "xmark", action: cancel)
            }
        }
        .task { await load() }
    }

    private func load() async {
        let request = selection.begin()
        do {
            let folder = try await service.browse(path: path.isEmpty ? nil : path)
            selection.succeed(folder, request: request, isCancelled: Task.isCancelled)
        } catch {
            selection.fail(error, request: request, isCancelled: Task.isCancelled)
        }
    }
}

#if DEBUG
    #Preview {
        NavigationStack {
            AdministrativeLibraryFolderList(
                path: "", service: Step3AdministrationPreviewService(), cancel: {}, select: { _ in })
        }
    }
#endif
