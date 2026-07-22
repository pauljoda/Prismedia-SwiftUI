import SwiftUI
import UniformTypeIdentifiers

#if canImport(Accessibility)
    import Accessibility
#endif

#if os(iOS) || os(macOS)
    struct EntityManualContentUploadSection: View {
        @State private var files: [RequestActivityManualUploadFile] = []
        @State private var isImporting = false
        @State private var isReadingSelection = false
        @State private var phase = RequestActivityManualUploadPhase.idle
        @State private var errorMessage: String?
        @Binding private var isParentBusy: Bool

        #if os(iOS)
            @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        #endif
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

        let entityID: UUID
        let kind: EntityKind
        let bookRendition: RequestActivityBookRendition?
        let service: any RequestActivityServicing
        let onUploaded: @MainActor (RequestActivityAcquisitionDetail) async -> Void

        init(
            entityID: UUID,
            kind: EntityKind,
            bookRendition: RequestActivityBookRendition?,
            service: any RequestActivityServicing,
            isParentBusy: Binding<Bool>,
            onUploaded: @escaping @MainActor (RequestActivityAcquisitionDetail) async -> Void
        ) {
            self.entityID = entityID
            self.kind = kind
            self.bookRendition = bookRendition
            self.service = service
            _isParentBusy = isParentBusy
            self.onUploaded = onUploaded
        }

        #if DEBUG
            init(
                entityID: UUID,
                kind: EntityKind,
                service: any RequestActivityServicing,
                previewFiles: [RequestActivityManualUploadFile] = [],
                previewPhase: RequestActivityManualUploadPhase = .idle,
                errorMessage: String? = nil,
                isReadingSelection: Bool = false
            ) {
                self.init(
                    entityID: entityID,
                    kind: kind,
                    bookRendition: nil,
                    service: service,
                    isParentBusy: .constant(previewPhase.isBusy),
                    onUploaded: { _ in }
                )
                _files = State(initialValue: previewFiles)
                _phase = State(initialValue: previewPhase)
                _errorMessage = State(initialValue: errorMessage)
                _isReadingSelection = State(initialValue: isReadingSelection)
            }
        #endif

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    Text("Manual Acquisition")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    Text("Choose local content to use for this item. Prismedia will validate it, upload it securely, then continue through the normal import lifecycle.")
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textMuted)
                }

                if files.isEmpty {
                    if showsDropTarget {
                        RequestActivityManualDropTarget(
                            title: "Drop acquisition files",
                            message: "Add one or more files. Folders are not accepted.",
                            isDisabled: controlsDisabled,
                            onDrop: receive
                        )
                    }
                } else {
                    RequestActivityManualFileSummary(files: files, onRemove: remove)
                }

                if let errorMessage {
                    RequestActivityManualErrorMessage(message: errorMessage)
                }

                utilityActions
                if !files.isEmpty { submitButton }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.data, .item],
                allowsMultipleSelection: true,
                onCompletion: handleImport
            )
        }

        private var utilityActions: some View {
            HStack(spacing: PrismediaSpacing.small) {
                PrismediaButton(
                    files.isEmpty ? "Choose Files" : "Replace Files",
                    systemImage: "doc.badge.plus",
                    form: .fill,
                    isLoading: isReadingSelection,
                    loadingTitle: "Reading Files…"
                ) {
                    isImporting = true
                }
                if !files.isEmpty {
                    PrismediaButton("Remove All", systemImage: "xmark", form: .fill) {
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
                "Upload and Import",
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
            case .preparing: "Preparing Files…"
            case .uploading(let progress): "Uploading \(Int((progress * 100).rounded()))%…"
            case .finishing: "Starting Import…"
            case .idle: "Upload and Import"
            }
        }

        private var submissionAccessibilityValue: String {
            switch phase {
            case .preparing: "Preparing files"
            case .uploading(let progress): "Uploading, \(Int((progress * 100).rounded())) percent"
            case .finishing: "Upload complete, starting import"
            case .idle: ""
            }
        }

        private var controlsDisabled: Bool {
            isParentBusy || isReadingSelection || phase.isBusy
        }

        private var selectionIsValid: Bool {
            (try? RequestActivityManualUploadPolicy.validateContent(
                files,
                kind: kind,
                bookRendition: bookRendition
            )) != nil
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
                    let selection = try await RequestActivityManualFileSelectionService().load(urls)
                    files = selection
                    try RequestActivityManualUploadPolicy.validateContent(
                        selection,
                        kind: kind,
                        bookRendition: bookRendition
                    )
                    errorMessage = nil
                } catch {
                    setError(error.localizedDescription)
                }
            }
        }

        private func submit() async {
            guard !controlsDisabled else { return }
            do {
                try RequestActivityManualUploadPolicy.validateContent(
                    files,
                    kind: kind,
                    bookRendition: bookRendition
                )
                isParentBusy = true
                phase = .preparing
                errorMessage = nil
                defer {
                    phase = .idle
                    isParentBusy = false
                }
                let upload = RequestActivityManualContentUpload(entityID: entityID, files: files)
                phase = .uploading(0)
                let detail = try await service.uploadRequestActivityContent(upload) { value in
                    phase = .uploading(value)
                }
                phase = .finishing
                await onUploaded(detail)
                files = []
                postAnnouncement("Upload complete. Importing.")
            } catch is CancellationError {
                return
            } catch {
                setError(error.localizedDescription)
            }
        }

        private func remove(_ file: RequestActivityManualUploadFile) {
            files.removeAll { $0.id == file.id }
            errorMessage = nil
        }

        private func clearSelection() {
            files = []
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
        #Preview("Manual Content Upload") {
            EntityManualContentUploadSection(
                entityID: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
                kind: .book,
                service: PreviewRequestActivityService(scenario: .content)
            )
            .padding()
            .preferredColorScheme(.dark)
        }
    #endif
#endif
