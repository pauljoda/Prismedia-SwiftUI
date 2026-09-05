import SwiftUI

struct AdministrativeFileActions: View {
    let entry: AdministrativeFileEntry
    var includesDetails = true
    let perform: (AdministrativeFileAction) -> Void

    var body: some View {
        if includesDetails {
            Button("Details", systemImage: "info.circle") { perform(.details) }
        }
        Button("Download", systemImage: "arrow.down.circle") { perform(.download) }
        Button("Rename", systemImage: "pencil") { perform(.rename) }
        Button("Move", systemImage: "folder") { perform(.move) }
        Button(
            entry.excluded ? "Include in Scans" : "Exclude from Scans",
            systemImage: entry.excluded ? "eye" : "eye.slash"
        ) { perform(.toggleExclusion) }
        Divider()
        Button("Delete Permanently", systemImage: "trash", role: .destructive) { perform(.delete) }
    }
}
