import Foundation

/// Lets the page that opened a reader wait for the reader's queued progress writes before it reads
/// the Book's progress again. A reader queues its closing position and dismisses at once, so without
/// this the page's refresh can reach the server before that position does.
@MainActor
public final class BookReaderWriteBarrier {
    // MARK: - Variables

    private var pendingWrites: [Task<Void, Never>] = []

    // MARK: - Initializers

    public init() {}

    // MARK: - Actions - Writes

    /// Records a write the reader has queued.
    func track(_ write: Task<Void, Never>) {
        pendingWrites.append(write)
    }

    /// Returns once every write queued so far, and any queued while waiting, has finished.
    public func settle() async {
        while !pendingWrites.isEmpty {
            let writes = pendingWrites
            pendingWrites.removeAll()
            for write in writes {
                await write.value
            }
        }
    }
}
