import SwiftUI

#if os(iOS) || os(macOS)
    struct AdministrativeFileTransferStatusView: View {
        let title: String
        let detail: String
        let progress: Double?
        let cancel: @MainActor () -> Void

        var body: some View {
            VStack(spacing: PrismediaSpacing.large) {
                Image(systemName: "arrow.up.arrow.down.circle")
                    .font(.largeTitle)
                Text(title).font(.headline)
                if let progress {
                    ProgressView(value: progress)
                } else {
                    ProgressView()
                }
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Cancel", role: .cancel, action: cancel)
            }
            .padding(PrismediaSpacing.extraLarge)
            .frame(minWidth: 320, idealWidth: 420)
        }
    }

    #if DEBUG
        #Preview("Archive Progress") {
            AdministrativeFileTransferStatusView(
                title: "Compressing Folder",
                detail: "9 of 20 files",
                progress: 0.45,
                cancel: {}
            )
        }
    #endif
#endif
