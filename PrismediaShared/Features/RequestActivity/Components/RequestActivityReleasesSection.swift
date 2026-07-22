import SwiftUI

#if os(iOS) || os(macOS)
    /// The embedded release-review block: candidate count header, per-release rows with
    /// Download / Blocklist actions, and the manual .torrent upload fallback — mirroring
    /// the web releases section.
    struct RequestActivityReleasesSection: View {
        @State private var visibleCount = 10
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
                        ForEach(visibleCandidates) { candidate in
                            RequestActivityCandidateRow(
                                candidate: candidate,
                                isDisabled: isBusy || !canPickRelease,
                                variant: .download,
                                onQueue: onQueue,
                                onBlocklist: onBlocklist
                            )
                        }

                        if remainingCount > 0 {
                            loadMoreButton
                        }
                    }
                }

                if canPickRelease {
                    torrentUploadFallback
                }
            }
            .onChange(of: candidates.count) {
                visibleCount = pageSize
            }
        }

        private var visibleCandidates: ArraySlice<RequestActivityReleaseCandidate> {
            candidates.prefix(visibleCount)
        }

        private var remainingCount: Int {
            max(0, candidates.count - visibleCount)
        }

        private var nextPageCount: Int {
            min(pageSize, remainingCount)
        }

        private var loadMoreButton: some View {
            PrismediaButton(
                "Load \(nextPageCount) more releases",
                systemImage: "chevron.down",
                form: .fill
            ) {
                visibleCount += pageSize
            }
            .frame(maxWidth: .infinity)
            .prismediaCompactActionControlSize()
            .padding(.top, PrismediaSpacing.small)
        }

        private var pageSize: Int { 10 }

        private var torrentUploadFallback: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                torrentUploadCopy
                torrentUploadButton
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
            PrismediaButton(
                "Upload .torrent",
                systemImage: "doc.badge.plus",
                form: .fill
            ) {
                onUploadTorrent()
            }
            .frame(maxWidth: .infinity)
            .prismediaCompactActionControlSize()
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
