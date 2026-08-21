import Foundation

/// Generic reader transport for manifest metadata and ordinal page resources.
public protocol EntityPageReaderServicing: EntityDetailLoading, Sendable {
    func loadEntityReaderManifest(id: UUID) async throws -> EntityReaderManifest
    func loadEntityReaderPageData(id: UUID, ordinal: Int) async throws -> Data
}

extension EntityPageReaderServicing {
    public func loadEntityReaderManifest(id: UUID) async throws -> EntityReaderManifest {
        throw BookReaderManifestError.noReadablePages
    }

    public func loadEntityReaderPageData(id: UUID, ordinal: Int) async throws -> Data {
        throw BookReaderManifestError.noReadablePages
    }
}
