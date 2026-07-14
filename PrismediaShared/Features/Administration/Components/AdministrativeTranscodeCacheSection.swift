import SwiftUI

struct AdministrativeTranscodeCacheSection: View {
    let status: AdministrativeTranscodeCacheStatus?
    let isWorking: Bool
    let onClear: () async -> Void

    var body: some View {
        Section {
            LabeledContent("Current usage", value: cacheDescription)
            Button(role: .destructive) {
                Task { await onClear() }
            } label: {
                FullWidthButtonLabel {
                    Label("Clear transcode cache", systemImage: "trash")
                }
            }
            .disabled(isWorking || status?.usedBytes == 0)
        } header: {
            Text("Storage")
        } footer: {
            Text("Clearing prepared streams is safe; Prismedia recreates them when needed.")
        }
    }

    private var cacheDescription: String {
        guard let status else { return "Unavailable" }
        let used = ByteCountFormatter.string(fromByteCount: status.usedBytes, countStyle: .file)
        guard status.maxBytes > 0 else { return used }
        let maximum = ByteCountFormatter.string(fromByteCount: status.maxBytes, countStyle: .file)
        return "\(used) of \(maximum)"
    }
}

#if DEBUG
    #Preview("Transcode Cache") {
        Form {
            AdministrativeTranscodeCacheSection(
                status: AdministrativeTranscodeCacheStatus(
                    usedBytes: 512_000_000,
                    maxBytes: 4_000_000_000
                ),
                isWorking: false,
                onClear: {}
            )
        }
    }
#endif
