import SwiftUI

struct AdministrativeLibraryRootRow: View {
    let root: AdministrativeLibraryRoot
    let isWorking: Bool
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onRescan: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
            Image(systemName: root.enabled ? "folder.fill" : "folder")
                .foregroundStyle(root.enabled ? PrismediaColor.accent : PrismediaColor.textSecondary)
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Text(root.label).font(.headline)
                Text(root.path).font(.caption.monospaced()).foregroundStyle(.secondary).prismediaTextSelection()
                HStack(spacing: PrismediaSpacing.small) {
                    ForEach(mediaLabels, id: \.self) { Text($0).font(.caption2) }
                    if root.isNsfw { Text("NSFW").font(.caption2).foregroundStyle(PrismediaColor.warning) }
                    if root.autoIdentify { Text("Auto ID").font(.caption2) }
                }
                .foregroundStyle(.secondary)
                Text(
                    root.lastScannedAt.map { "Last scanned \($0.formatted(.relative(presentation: .named)))" }
                        ?? "Never scanned"
                )
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
            Spacer()
            Menu("Actions", systemImage: "ellipsis.circle") {
                Button("Edit", systemImage: "pencil", action: onEdit)
                Button(root.enabled ? "Disable" : "Enable", systemImage: "power", action: onToggle)
                Button("Rescan", systemImage: "arrow.clockwise", action: onRescan)
                Divider()
                Button("Remove Library", systemImage: "trash", role: .destructive, action: onDelete)
            }
            .labelStyle(.iconOnly)
            .disabled(isWorking)
        }
        .contentShape(.rect)
    }

    private var mediaLabels: [String] {
        [
            root.scanVideos ? "Video" : nil,
            root.scanImages ? "Images" : nil,
            root.scanAudio ? "Audio" : nil,
            root.scanBooks ? "Books" : nil,
        ].compactMap { $0 }
    }
}

#if DEBUG
    #Preview {
        AdministrativeLibraryRootRow(
            root: AdministrativeLibraryRoot(
                id: UUID(),
                path: "/media/movies",
                label: "Movies",
                enabled: true,
                scanVideos: true,
                lastScannedAt: .now
            ),
            isWorking: false,
            onEdit: {},
            onToggle: {},
            onRescan: {},
            onDelete: {}
        )
        .padding()
    }
#endif
