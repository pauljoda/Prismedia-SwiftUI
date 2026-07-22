import SwiftUI

#if os(iOS) || os(macOS)
    /// The full-width embedded transfer section. The lifecycle owns actions while this
    /// section distinguishes preparation, live/stale telemetry, and probe unavailability.
    struct RequestActivityDownloadSection: View {
        let transfer: RequestActivityTransfer?
        let loadState: RequestActivityTransferLoadState

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                Text("Download")
                    .font(.headline)
                    .foregroundStyle(PrismediaColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                if let transfer {
                    RequestActivityTransferSummary(
                        transfer: transfer,
                        isStale: loadState == .stale
                    )
                } else if loadState == .unavailable || loadState == .stale {
                    RequestActivityStatePlaceholder(
                        title: "Transfer Information Unavailable",
                        message: "Prismedia could not reach the download client and will keep retrying.",
                        systemImage: "wifi.exclamationmark"
                    )
                } else {
                    PrismediaLoadingView("Preparing download…")
                        .frame(maxWidth: .infinity, minHeight: 220)
                        .prismediaPanel()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    #if DEBUG
        #Preview("Download Section") {
            VStack(spacing: PrismediaSpacing.large) {
                RequestActivityDownloadSection(
                    transfer: RequestActivityPreviewFixtures.transfer,
                    loadState: .current
                )
                .padding(PrismediaSpacing.extraLarge)
                .prismediaCard()
                RequestActivityDownloadSection(transfer: nil, loadState: .preparing)
            }
            .padding()
        }
    #endif
#endif
