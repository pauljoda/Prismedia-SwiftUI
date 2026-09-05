import Foundation
import Observation

/// Owns one user-initiated transfer, its cancellation and its temporary export.
@MainActor @Observable
final class AdministrativeFileTransferSession: Identifiable {
    let id = UUID()
    let request: AdministrativeFileTransferRequest
    private(set) var phase: AdministrativeFileTransferPhase = .idle
    private(set) var title = "Preparing Transfer"
    private(set) var detail = ""
    private(set) var progress: Double?
    private(set) var download: AdministrativeDownloadedFile?
    private(set) var errorMessage: String?
    private(set) var cleanupError: String?
    private(set) var isCancelling = false
    private(set) var uploadResult: AdministrativeFileUploadResult?
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var isClosed = false
    private let service: any FileTransferServicing

    init(request: AdministrativeFileTransferRequest, service: any FileTransferServicing) {
        self.request = request
        self.service = service
    }

    var isWorking: Bool { phase == .idle || phase == .working }
    var canRetry: Bool { phase == .failed && !request.isUpload }

    func run() async {
        guard !isClosed, task == nil, phase == .idle || canRetry else { return }
        phase = .working
        errorMessage = nil
        progress = nil
        isCancelling = false
        let operation = Task { await perform() }
        task = operation
        await withTaskCancellationHandler {
            await operation.value
        } onCancel: {
            operation.cancel()
        }
        task = nil
    }

    func cancel() {
        guard isWorking else { return }
        if phase == .idle {
            phase = .cancelled
            title = "Transfer Cancelled"
            detail = "The transfer was not started."
            return
        }
        isCancelling = true
        task?.cancel()
    }

    /// Cancels outstanding work and releases only this session's temporary export.
    func close() async {
        guard !isClosed else { return }
        isClosed = true
        task?.cancel()
        await task?.value
        if let download {
            do {
                try await service.discardDownload(download)
                self.download = nil
            } catch { cleanupError = error.localizedDescription }
        }
    }

    private func perform() async {
        defer { isCancelling = false }
        do {
            switch request {
            case .upload(let urls, let location):
                title = "Preparing Upload"
                detail = "Reading selected files…"
                let collection = Task.detached { try AdministrativeUploadItemCollector().collect(urls) }
                let items = try await withTaskCancellationHandler {
                    try await collection.value
                } onCancel: {
                    collection.cancel()
                }
                let result = await FileUploadUseCase(service: service).upload(
                    items, rootID: location.rootID, targetPath: location.path
                ) { [self] value in
                    guard !isClosed else { return }
                    title = "Uploading Files"
                    detail = "\(value.completed) of \(value.total) files processed"
                    if let path = value.currentPath { detail += "\n" + path }
                    progress = value.total > 1 ? value.fraction : nil
                }
                uploadResult = result
                progress = nil
                if result.isCancelled {
                    phase = .cancelled
                    title = "Upload Cancelled"
                    detail =
                        "\(result.successfulPaths.count) of \(items.count) files confirmed uploaded. Check the folder before trying again."
                } else if !result.failures.isEmpty {
                    phase = .failed
                    title = "Some Files Couldn’t Upload"
                    detail =
                        "\(result.successfulPaths.count) of \(items.count) files uploaded. Successful files were kept."
                    errorMessage = result.failures.map { "\($0.relativePath): \($0.message)" }.joined(separator: "\n")
                } else {
                    phase = .completed
                    title = items.isEmpty ? "No Files to Upload" : "Upload Complete"
                    detail =
                        items.isEmpty
                        ? "The selection contains no uploadable files."
                        : (items.count == 1 ? "1 file uploaded." : "\(items.count) files uploaded.")
                }
            case .download(let entry):
                title = "Downloading File"
                detail = entry.name
                let file = try await service.downloadFile(rootID: entry.rootID, path: entry.path)
                try await accept(file)
            case .archive(let location, let name):
                title = "Preparing ZIP"
                detail = name
                let file = try await FileArchiveDownloadUseCase(service: service).prepareAndDownload(
                    rootID: location.rootID, path: location.path
                ) { [self] value in
                    guard !isClosed else { return }
                    title = value.ready ? "Downloading ZIP" : "Creating ZIP"
                    detail = value.ready ? value.fileName : "\(value.processedFiles) of \(value.totalFiles) files"
                    progress = value.ready ? nil : min(1, max(0, Double(value.progressPercent) / 100))
                }
                try await accept(file)
            }
        } catch {
            progress = nil
            if Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled {
                phase = .cancelled
                title = "Transfer Cancelled"
                detail =
                    request.isUpload
                    ? "Check the folder before trying again. Files already uploaded are kept."
                    : "Nothing was saved to Files."
                if case .archive = request {
                    detail += " The temporary server ZIP may finish preparing and will expire automatically."
                }
            } else {
                phase = .failed
                title = "Transfer Failed"
                errorMessage = error.localizedDescription
            }
        }
    }

    private func accept(_ file: AdministrativeDownloadedFile) async throws {
        guard !Task.isCancelled, !isClosed else {
            try await service.discardDownload(file)
            throw CancellationError()
        }
        download = file
        phase = .ready
        title = "Ready to Save"
        detail = file.suggestedFileName
        progress = nil
    }
}
