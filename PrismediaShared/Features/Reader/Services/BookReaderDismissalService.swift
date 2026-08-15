import Foundation

@MainActor
struct BookReaderDismissalService {
    @discardableResult
    func close(
        prepare: () -> Void = {},
        dismiss: () -> Void,
        flush: @escaping @MainActor () async -> Void
    ) -> Task<Void, Never> {
        prepare()
        dismiss()
        return Task { await flush() }
    }
}
