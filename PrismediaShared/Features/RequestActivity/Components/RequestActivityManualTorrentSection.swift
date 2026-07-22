import SwiftUI
import UniformTypeIdentifiers

#if canImport(Accessibility)
    import Accessibility
#endif

#if os(iOS) || os(macOS)
    struct RequestActivityManualTorrentSection: View {
        @State private var selectedFile: RequestActivityManualUploadFile?
        @State private var isImporting = false
        @State private var isReadingSelection = false
        @State private var phase = RequestActivityManualUploadPhase.idle
        @State private var errorMessage: String?
        @Binding private var isParentBusy: Bool

        #if os(iOS)
            @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        #endif
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

        let acquisitionID: UUID
        let service: any RequestActivityServicing
        let isDisabled: Bool
        let onUploaded: @MainActor (RequestActivityAcquisitionDetail) async -> Void

        init(
            acquisitionID: UUID,
            service: any RequestActivityServicing,
            isDisabled: Bool,
            isParentBusy: Binding<Bool>,
            onUploaded: @escaping @MainActor (RequestActivityAcquisitionDetail) async -> Void
        ) {
            self.acquisitionID = acquisitionID
            self.service = service
            self.isDisabled = isDisabled
            _isParentBusy = isParentBusy
            self.onUploaded = onUploaded
        }

        #if DEBUG
            init(
                acquisitionID: UUID,
                service: any RequestActivityServicing,
                previewFile: RequestActivityManualUploadFile? = nil,
                previewPhase: RequestActivityManualUploadPhase = .idle,
                errorMessage: String? = nil,
                isReadingSelection: Bool = false,
                isDisabled: Bool = false
            ) {
                self.init(
                    acquisitionID: acquisitionID,
                    service: service,
                    isDisabled: isDisabled,
                    isParentBusy: .constant(previewPhase.isBusy),
                    onUploaded: { _ in }
                )
                _selectedFile = State(initialValue: previewFile)
                _phase = State(initialValue: previewPhase)
                _errorMessage = State(initialValue: errorMessage)
                _isReadingSelection = State(initialValue: isReadingSelection)
            }
        #endif

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    Text("Have a .torrent file?")
                        .font(.subheadline.weight(.semibold))
                    Text("Use a downloaded .torrent when a release page cannot hand the release to Prismedia directly.")
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textMuted)
                }

                if let selectedFile {
                    RequestActivityManualFileSummary(files: [selectedFile]) { _ in clearSelection() }
                } else if showsDropTarget {
                    RequestActivityManualDropTarget(
                        title: "Drop a .torrent file",
                        message: "One file will be sent to your configured torrent client.",
                        isDisabled: controlsDisabled,
                        onDrop: receive
                    )
                }

                if let errorMessage {
                    RequestActivityManualErrorMessage(message: errorMessage)
                }

                utilityActions
                if selectedFile != nil { submitButton }
            }
            .padding(PrismediaSpacing.medium)
            .prismediaCard(cornerRadius: PrismediaRadius.control)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [UTType(filenameExtension: "torrent") ?? .data],
                allowsMultipleSelection: false,
                onCompletion: handleImport
            )
        }

        private var utilityActions: some View {
            VStack(spacing: PrismediaSpacing.small) {
                PrismediaButton(
                    selectedFile == nil ? "Choose Torrent" : "Replace Torrent",
                    systemImage: "doc.badge.plus",
                    form: .fill,
                    isLoading: isReadingSelection,
                    loadingTitle: "Reading File…"
                ) {
                    isImporting = true
                }
                if selectedFile != nil {
                    PrismediaButton("Remove", systemImage: "xmark", form: .fill) {
                        clearSelection()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .prismediaCompactActionControlSize()
            .disabled(controlsDisabled)
        }

        private var submitButton: some View {
            PrismediaButton(
                "Upload Torrent",
                systemImage: "arrow.up.doc",
                variant: .prominent,
                form: .fill,
                primaryTint: artworkPrimaryAccent,
                isLoading: phase.isBusy,
                loadingTitle: phaseTitle
            ) {
                Task { await submit() }
            }
            .frame(maxWidth: .infinity)
            .prismediaCompactActionControlSize()
            .disabled(controlsDisabled || !selectionIsValid)
            .accessibilityValue(submissionAccessibilityValue)
        }

        private var phaseTitle: String {
            switch phase {
            case .preparing: "Reading Torrent…"
            case .uploading: "Sending to Client…"
            case .finishing: "Starting Download…"
            case .idle: "Upload Torrent"
            }
        }

        private var submissionAccessibilityValue: String {
            switch phase {
            case .preparing: "Reading torrent file"
            case .uploading: "Sending torrent to the configured client"
            case .finishing: "Torrent queued, starting download"
            case .idle: ""
            }
        }

        private var controlsDisabled: Bool {
            isDisabled || isParentBusy || isReadingSelection || phase.isBusy
        }

        private var selectionIsValid: Bool {
            (try? RequestActivityManualUploadPolicy.validateTorrent(selectedFile)) != nil
        }

        private var showsDropTarget: Bool {
            #if os(macOS)
                true
            #else
                horizontalSizeClass == .regular
            #endif
        }

        private func handleImport(_ result: Result<[URL], any Error>) {
            switch result {
            case .success(let urls):
                guard !urls.isEmpty else { return }
                receive(urls)
            case .failure(let error):
                setError(error.localizedDescription)
            }
        }

        private func receive(_ urls: [URL]) {
            Task {
                isReadingSelection = true
                defer { isReadingSelection = false }
                do {
                    let files = try await RequestActivityManualFileSelectionService().load(Array(urls.prefix(1)))
                    let file = files.first
                    selectedFile = file
                    try RequestActivityManualUploadPolicy.validateTorrent(file)
                    errorMessage = nil
                } catch {
                    setError(error.localizedDescription)
                }
            }
        }

        private func submit() async {
            guard !controlsDisabled else { return }
            do {
                try RequestActivityManualUploadPolicy.validateTorrent(selectedFile)
                guard let selectedFile else { return }
                isParentBusy = true
                phase = .preparing
                errorMessage = nil
                defer {
                    phase = .idle
                    isParentBusy = false
                }
                let targetAcquisitionID = acquisitionID
                let upload = try await Task.detached(priority: .userInitiated) {
                    let accessing = selectedFile.url.startAccessingSecurityScopedResource()
                    defer { if accessing { selectedFile.url.stopAccessingSecurityScopedResource() } }
                    return RequestActivityManualTorrentUpload(
                        acquisitionID: targetAcquisitionID,
                        fileName: selectedFile.fileName,
                        data: try Data(contentsOf: selectedFile.url)
                    )
                }.value
                phase = .uploading(0)
                let detail = try await service.uploadRequestActivityTorrent(upload)
                phase = .finishing
                await onUploaded(detail)
                self.selectedFile = nil
                postAnnouncement("Torrent queued. Download started.")
            } catch is CancellationError {
                return
            } catch {
                setError(error.localizedDescription)
            }
        }

        private func clearSelection() {
            selectedFile = nil
            errorMessage = nil
        }

        private func setError(_ message: String) {
            errorMessage = message
            postAnnouncement("Manual acquisition error. \(message)")
        }

        private func postAnnouncement(_ message: String) {
            #if canImport(Accessibility)
                AccessibilityNotification.Announcement(message).post()
            #endif
        }
    }

    #if DEBUG
        #Preview("Manual Torrent") {
            RequestActivityManualTorrentSection(
                acquisitionID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                service: PreviewRequestActivityService(scenario: .releases)
            )
            .padding()
            .preferredColorScheme(.dark)
        }
    #endif
#endif
