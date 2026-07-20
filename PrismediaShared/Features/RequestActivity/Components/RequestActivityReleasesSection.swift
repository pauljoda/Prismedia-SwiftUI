import SwiftUI

#if os(iOS) || os(macOS)
    /// The embedded release-review block: candidate count header, per-release rows with
    /// Download / Blocklist actions, and the manual .torrent upload fallback — mirroring
    /// the web releases section.
    struct RequestActivityReleasesSection: View {
        let candidates: [RequestActivityReleaseCandidate]
        let canPickRelease: Bool
        let isBusy: Bool
        let onQueue: (RequestActivityReleaseCandidate) -> Void
        let onBlocklist: (RequestActivityReleaseCandidate) -> Void
        let onUploadTorrent: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                HStack(spacing: PrismediaSpacing.small) {
                    Text("Releases")
                        .font(.headline)
                        .foregroundStyle(PrismediaColor.textPrimary)
                    Text(String(candidates.count))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(PrismediaColor.textMuted)
                }
                .accessibilityAddTraits(.isHeader)

                if candidates.isEmpty {
                    RequestActivityStatePlaceholder(
                        title: "No releases found",
                        message:
                            "No indexer returned a matching release for this title. You can upload a .torrent manually below.",
                        systemImage: "magnifyingglass"
                    )
                } else {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                        ForEach(candidates) { candidate in
                            RequestActivityCandidateRow(
                                candidate: candidate,
                                isDisabled: isBusy || !canPickRelease,
                                variant: .download,
                                onQueue: onQueue,
                                onBlocklist: onBlocklist
                            )
                        }
                    }
                }

                if canPickRelease {
                    torrentUploadFallback
                }
            }
        }

        private var torrentUploadFallback: some View {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: PrismediaSpacing.medium) {
                    torrentUploadCopy
                    Spacer(minLength: PrismediaSpacing.small)
                    torrentUploadButton
                }
                VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                    torrentUploadCopy
                    torrentUploadButton
                }
            }
            .padding(PrismediaSpacing.medium)
            .prismediaPanel()
        }

        private var torrentUploadCopy: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Text("Have a .torrent file?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PrismediaColor.textPrimary)
                Text(
                    "Open a release page above, download its .torrent, then upload it here to download directly."
                )
                .font(.caption)
                .foregroundStyle(PrismediaColor.textMuted)
            }
        }

        private var torrentUploadButton: some View {
            PrismediaButton("Upload .torrent", systemImage: "doc.badge.plus") {
                onUploadTorrent()
            }
            .controlSize(.small)
            .disabled(isBusy)
        }
    }

    #if DEBUG
        #Preview("Releases Section") {
            ScrollView {
                VStack(spacing: PrismediaSpacing.large) {
                    RequestActivityReleasesSection(
                        candidates: [
                            RequestActivityPreviewFixtures.candidate,
                            RequestActivityPreviewFixtures.rejectedCandidate,
                        ],
                        canPickRelease: true,
                        isBusy: false,
                        onQueue: { _ in },
                        onBlocklist: { _ in },
                        onUploadTorrent: {}
                    )
                    RequestActivityReleasesSection(
                        candidates: [],
                        canPickRelease: true,
                        isBusy: false,
                        onQueue: { _ in },
                        onBlocklist: { _ in },
                        onUploadTorrent: {}
                    )
                }
                .padding()
            }
        }
    #endif
#endif
