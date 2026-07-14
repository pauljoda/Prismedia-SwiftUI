import Foundation

public protocol EntityImageSourceLoading: Sendable {
    func loadEntitySourceData(id: UUID) async throws -> Data
}
