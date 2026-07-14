import Foundation

@MainActor
public struct DocumentReaderUseCase: Sendable {
    public let book: EntityDetail
    private let service: any BookReaderServicing

    public init(book: EntityDetail, service: any BookReaderServicing) {
        self.book = book
        self.service = service
    }

    public var progress: EntityProgressCapability? {
        book.capabilities.lazy.compactMap { capability in
            guard case .progress(let value) = capability else { return nil }
            return value
        }.first
    }

    public func loadSourceData() async throws -> Data {
        try await service.loadSourceData(id: book.id)
    }
}
