import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityFilesSection: View {
        let loadState: RequestActivityFilesLoadState
        let retry: () -> Void
        private let expansionOverride: Bool?
        @State private var isExpanded: Bool

        init(
            loadState: RequestActivityFilesLoadState,
            expansionOverride: Bool? = nil,
            retry: @escaping () -> Void
        ) {
            self.loadState = loadState
            self.expansionOverride = expansionOverride
            self.retry = retry
            _isExpanded = State(initialValue: expansionOverride ?? true)
        }

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                switch loadState.content {
                case .initialLoading:
                    PrismediaLoadingView("Loading files…")
                case let .initialFailure(message):
                    unavailable(title: "Files couldn’t be loaded", message: message, retryTitle: "Retry")
                case let .loaded(files):
                    loadedContent(files)
                case .waiting:
                    unavailable(
                        title: "Waiting for file information",
                        message: "Files will appear when the download client reports them."
                    )
                case .empty:
                    unavailable(title: "No files reported", message: "The completed acquisition contains no file entries.")
                case .unavailable:
                    unavailable(
                        title: "Import details unavailable",
                        message: "This legacy import has no saved source-to-library mapping."
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        private func loadedContent(_ files: RequestActivityFiles) -> some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    if files.phase?.value == .importing {
                        importProgress(files)
                    }
                    if loadState.showsStaleWarning {
                        staleWarning
                    }
                    ForEach(files.files, id: \.stableID) { file in
                        RequestActivityFileRow(file: file)
                        if file.stableID != files.files.last?.stableID { Divider() }
                    }
                }
                .padding(.top, PrismediaSpacing.small)
            } label: {
                HStack(spacing: PrismediaSpacing.small) {
                    Text(files.imported ? "Imported Files" : "Downloaded Files")
                        .font(.headline)
                    Text(files.files.count, format: .number)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(PrismediaColor.textMuted)
                }
                .foregroundStyle(PrismediaColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            }
            .onChange(of: files, initial: true) { _, files in
                isExpanded = expansionOverride ?? RequestActivityFilesPresentationPolicy.isExpandedByDefault(files)
            }
        }

        private func importProgress(_ files: RequestActivityFiles) -> some View {
            let progress = RequestActivityFilesPresentationPolicy.progress(for: files)
            return VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                ProgressView(value: Double(progress.processed), total: Double(max(progress.total, 1)))
                Text("\(progress.processed) of \(progress.total) files processed")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(PrismediaColor.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Import progress")
            .accessibilityValue("\(progress.processed) of \(progress.total) files processed")
        }

        private var staleWarning: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                Label("Saved file information may be out of date.", systemImage: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90")
                    .font(.callout)
                    .foregroundStyle(PrismediaColor.textSecondary)
                PrismediaButton("Retry Now", systemImage: "arrow.clockwise", form: .fill, action: retry)
            }
        }

        private func unavailable(title: String, message: String, retryTitle: String? = nil) -> some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                ContentUnavailableView(title, systemImage: "doc.text.magnifyingglass", description: Text(message))
                if let retryTitle {
                    PrismediaButton(retryTitle, systemImage: "arrow.clockwise", form: .fill, action: retry)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
#endif

#if DEBUG && (os(iOS) || os(macOS))
    #Preview("Acquisition Review · Files · Section Component") {
        RequestActivityFilesSection(loadState: .loaded(RequestActivityPreviewFixtures.files)) {}
            .padding()
            .background(PrismediaBackdrop())
            .preferredColorScheme(.dark)
    }
#endif
