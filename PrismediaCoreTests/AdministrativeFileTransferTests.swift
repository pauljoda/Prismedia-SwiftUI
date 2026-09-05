import Foundation
import XCTest

@testable import PrismediaCore

final class AdministrativeFileTransferTests: XCTestCase {
    @MainActor
    func testUploadCancelledBeforeStartingDoesNotSendFiles() async {
        let service = FileTransferServiceStub()
        let selected = items
        let root = rootID
        let operation = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return await FileUploadUseCase(service: service).upload(selected, rootID: root, targetPath: "") { _ in }
        }
        let result = await operation.value
        XCTAssertTrue(result.isCancelled)
        XCTAssertTrue(result.successfulPaths.isEmpty)
        let calls = await service.uploadCalls
        XCTAssertEqual(calls, 0)
    }
    @MainActor
    func testCancelledUploadPreservesConfirmedFilesAndDoesNotTryRemainingItems() async {
        for cancellation: any Error in [CancellationError(), URLError(.cancelled)] {
            let service = FileTransferServiceStub()
            await service.failUpload(at: 1, error: cancellation)
            let result = await FileUploadUseCase(service: service).upload(items, rootID: rootID, targetPath: "") { _ in
            }
            XCTAssertTrue(result.isCancelled)
            XCTAssertEqual(result.successfulPaths, ["one.txt"])
            XCTAssertTrue(result.failures.isEmpty)
            let calls = await service.uploadCalls
            XCTAssertEqual(calls, 2)
        }
    }

    @MainActor
    func testUploadFailureRemainsDistinctFromCancellationAndKeepsLaterSuccesses() async {
        let service = FileTransferServiceStub()
        await service.failUpload(at: 1, error: URLError(.cannotConnectToHost))
        let result = await FileUploadUseCase(service: service).upload(items, rootID: rootID, targetPath: "") { _ in }
        XCTAssertFalse(result.isCancelled)
        XCTAssertEqual(result.successfulPaths, ["one.txt", "three.txt"])
        XCTAssertEqual(result.failures.map(\.relativePath), ["two.txt"])
    }

    @MainActor
    func testCancelledSessionDoesNotStartWork() async {
        let service = FileTransferServiceStub()
        let session = AdministrativeFileTransferSession(request: .download(entry), service: service)
        session.cancel()
        await session.run()
        XCTAssertEqual(session.phase, .cancelled)
        XCTAssertFalse(session.isWorking)
        XCTAssertFalse(session.isCancelling)
        let calls = await service.downloadCalls
        XCTAssertEqual(calls, 0)
    }

    @MainActor
    func testCancelledDownloadDiscardsLateResponseAndExcludesDuplicateRequests() async {
        let service = FileTransferServiceStub()
        await service.holdDownload()
        let session = AdministrativeFileTransferSession(request: .download(entry), service: service)
        let operation = Task { await session.run() }
        while !(await service.isDownloadHeld) { await Task.yield() }
        await session.run()
        session.cancel()
        await service.finishDownload()
        await operation.value
        XCTAssertEqual(session.phase, .cancelled)
        XCTAssertFalse(session.isCancelling)
        XCTAssertNil(session.download)
        XCTAssertNil(session.errorMessage)
        let calls = await service.downloadCalls
        let discarded = await service.discardedDownloads
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(discarded.count, 1)
    }

    @MainActor
    func testReadyDownloadIsRetainedUntilPresentationClosesThenDiscardedOnce() async {
        let service = FileTransferServiceStub()
        let session = AdministrativeFileTransferSession(request: .download(entry), service: service)
        await session.run()
        XCTAssertEqual(session.phase, .ready)
        XCTAssertNotNil(session.download)
        await session.close()
        await session.close()
        XCTAssertNil(session.download)
        let discarded = await service.discardedDownloads
        XCTAssertEqual(discarded.count, 1)
    }

    @MainActor
    func testDownloadFailureCanRetryAndCancellationIsNotAnError() async {
        let service = FileTransferServiceStub()
        await service.failDownload(URLError(.notConnectedToInternet))
        let session = AdministrativeFileTransferSession(request: .download(entry), service: service)
        await session.run()
        XCTAssertEqual(session.phase, .failed)
        XCTAssertNotNil(session.errorMessage)
        await service.failDownload(nil)
        await session.run()
        XCTAssertEqual(session.phase, .ready)
        XCTAssertNil(session.errorMessage)
        await session.close()
        await service.failDownload(URLError(.cancelled))
        let cancelled = AdministrativeFileTransferSession(request: .download(entry), service: service)
        await cancelled.run()
        XCTAssertEqual(cancelled.phase, .cancelled)
        XCTAssertNil(cancelled.errorMessage)
    }

    func testDownloadStorageOnlyDiscardsItsOwnTemporaryDirectory() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storage = AdministrativeDownloadStorage(directory: directory)
        let download = try storage.store(Data("test".utf8), suggestedName: "example.txt")
        XCTAssertEqual(try Data(contentsOf: download.localURL), Data("test".utf8))
        try storage.discard(download)
        XCTAssertFalse(FileManager.default.fileExists(atPath: download.localURL.deletingLastPathComponent().path))
        let outside = directory.appending(path: "keep.txt")
        try Data("keep".utf8).write(to: outside)
        XCTAssertThrowsError(try storage.discard(.init(localURL: outside, suggestedFileName: "keep.txt")))
        XCTAssertEqual(try Data(contentsOf: outside), Data("keep".utf8))
    }

    private let rootID = UUID()
    private var entry: AdministrativeFileEntry {
        .init(
            rootID: rootID, path: "example.txt", name: "example.txt", kind: "file",
            sizeBytes: 4, mimeType: "text/plain", modifiedAt: nil, excluded: false)
    }
    private var items: [AdministrativeFileUploadItem] {
        ["one.txt", "two.txt", "three.txt"].map {
            .init(localURL: URL(fileURLWithPath: "/fixture/" + $0), relativePath: $0)
        }
    }
}

private actor FileTransferServiceStub: FileTransferServicing {
    private(set) var uploadCalls = 0
    private(set) var downloadCalls = 0
    private(set) var discardedDownloads: [AdministrativeDownloadedFile] = []
    private var uploadFailure: (Int, any Error)?
    private var downloadError: (any Error)?
    private var shouldHoldDownload = false
    private var continuation: CheckedContinuation<AdministrativeDownloadedFile, any Error>?
    var isDownloadHeld: Bool { continuation != nil }

    func failUpload(at index: Int, error: any Error) { uploadFailure = (index, error) }
    func failDownload(_ error: (any Error)?) { downloadError = error }
    func holdDownload() { shouldHoldDownload = true }
    func finishDownload() {
        continuation?.resume(returning: file)
        continuation = nil
    }
    func upload(item: AdministrativeFileUploadItem, rootID: UUID, targetPath: String) async throws
        -> AdministrativeFileOperationResponse
    {
        let index = uploadCalls
        uploadCalls += 1
        if let (failureIndex, error) = uploadFailure, index == failureIndex { throw error }
        return .init(scansQueued: 1)
    }
    func downloadFile(rootID: UUID, path: String) async throws -> AdministrativeDownloadedFile {
        downloadCalls += 1
        if let downloadError { throw downloadError }
        if shouldHoldDownload {
            return try await withCheckedThrowingContinuation { continuation = $0 }
        }
        return file
    }
    func discardDownload(_ downloaded: AdministrativeDownloadedFile) async throws {
        discardedDownloads.append(downloaded)
    }
    func prepareArchive(rootID: UUID, path: String) async throws -> AdministrativeFileArchivePreparation {
        .init(
            id: UUID(), fileName: "folder.zip", ready: true, progressPercent: 100,
            processedFiles: 1, totalFiles: 1, error: nil)
    }
    func archiveStatus(id: UUID) async throws -> AdministrativeFileArchivePreparation {
        try await prepareArchive(rootID: UUID(), path: "")
    }
    func downloadArchive(_ preparation: AdministrativeFileArchivePreparation) async throws
        -> AdministrativeDownloadedFile
    { file }
    private var file: AdministrativeDownloadedFile {
        .init(localURL: URL(fileURLWithPath: "/fixture/example.txt"), suggestedFileName: "example.txt")
    }
}
