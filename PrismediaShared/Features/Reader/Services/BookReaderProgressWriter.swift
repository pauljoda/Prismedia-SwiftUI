import Foundation
import ImageIO
import Observation

/// Serializes progress writes so a slower earlier request cannot overwrite a
/// later page turn on the server.
@MainActor
final class BookReaderProgressWriter {
    private let service: any BookReaderServicing
    private let barrier: BookReaderWriteBarrier?
    private var queuedWrite: (bookID: UUID, request: EntityProgressUpdateRequest)?
    private var drainTask: Task<Void, Never>?
    private var accessTask: Task<Void, Never>?
    private var accessedBookID: UUID?
    private var activityClock = ConsumptionActivityClock()

    /// - Parameters:
    ///   - service: Sends the progress reports.
    ///   - barrier: The opening page's barrier, which learns about every queued write so the page can
    ///     wait for the closing position before it reads progress again.
    init(service: any BookReaderServicing, barrier: BookReaderWriteBarrier? = nil) {
        self.service = service
        self.barrier = barrier
    }

    func beginActivity(bookID: UUID) {
        if accessedBookID != bookID {
            accessedBookID = bookID
            let service = self.service
            let sessionID = UUID().uuidString.lowercased()
            accessTask = Task {
                try? await service.recordReadingAccess(id: bookID, sessionID: sessionID)
            }
        }
        activityClock.start()
    }

    func queue(
        bookID: UUID,
        request: EntityProgressUpdateRequest,
        stoppingActivity: Bool = false
    ) {
        let activitySeconds = stoppingActivity
            ? activityClock.stop()
            : activityClock.take()
        let accumulatedActivity =
            (queuedWrite?.request.activitySeconds ?? 0) + (activitySeconds ?? 0)
        queuedWrite = (
            bookID,
            request.recordingActivity(
                seconds: accumulatedActivity > 0 ? accumulatedActivity : nil,
                kind: .reading
            )
        )
        guard drainTask == nil else { return }
        let write = Task { await drain() }
        drainTask = write
        barrier?.track(write)
    }

    func flush() async {
        await accessTask?.value
        accessTask = nil
        while let drainTask {
            await drainTask.value
        }
    }

    private func drain() async {
        while let next = queuedWrite {
            queuedWrite = nil
            try? await service.updateReadingProgress(id: next.bookID, request: next.request)
        }
        drainTask = nil
    }
}
