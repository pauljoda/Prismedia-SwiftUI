import SwiftUI

struct AdministrativeFileEntryRow: View {
    let entry: AdministrativeFileEntry
    let isBusy: Bool
    let open: () -> Void
    let perform: (AdministrativeFileAction) -> Void

    var body: some View {
        HStack(spacing: PrismediaSpacing.medium) {
            Button(action: open) {
                HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
                    Image(systemName: entry.isDirectory ? "folder.fill" : "doc")
                        .foregroundStyle(PrismediaColor.textSecondary)
                    VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                        Text(entry.name).fixedSize(horizontal: false, vertical: true)
                        if !metadata.isEmpty {
                            Text(metadata).font(.caption).foregroundStyle(PrismediaColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if entry.excluded {
                            Label("Excluded from Scans", systemImage: "eye.slash")
                                .font(.caption).foregroundStyle(PrismediaColor.warning)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(isBusy)
            .accessibilityElement(children: .combine)
            .accessibilityHint(entry.isDirectory ? "Opens folder" : "Shows file details")
            .accessibilityIdentifier("administration.files.row.\(entry.path)")
            .contextMenu { AdministrativeFileActions(entry: entry, perform: perform) }
            PrismediaButton("Actions for \(entry.name)", systemImage: "ellipsis", form: .compactIcon) {
                AdministrativeFileActions(entry: entry, perform: perform)
            }
            .disabled(isBusy)
        }
        .padding(.vertical, PrismediaSpacing.small)
    }

    private var metadata: String {
        [
            entry.sizeBytes.map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) },
            entry.modifiedAt?.formatted(date: .abbreviated, time: .omitted),
        ]
        .compactMap { $0 }.joined(separator: " · ")
    }
}
