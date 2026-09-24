import Foundation

/// Chooses between the server-owned alignment and the legacy chapter map for one Book. Servers
/// from 3.8 serve the alignment projection; a qualifying server that lacks the route (a
/// route-missing 404) and older servers use the legacy chapter map.
struct BookAlignmentLoader: Sendable {
    // MARK: - Variables

    private let service: any BookAlignmentServicing

    // MARK: - Initializers

    init(service: any BookAlignmentServicing) {
        self.service = service
    }

    // MARK: - Actions - Loading

    /// Loads the Book's alignment in the connected server's shape.
    /// - Throws: `CancellationError`, or `BookAlignmentLoadError` naming the decided contract.
    func load(bookID: UUID) async throws -> BookAlignmentSnapshot {
        let version: PrismediaServerVersion?
        do {
            version = try await service.loadServerVersion()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw BookAlignmentLoadError(contract: nil, underlying: error)
        }

        if version?.servesBookAlignment == true {
            do {
                return .server(try await service.loadBookAlignment(bookID: bookID))
            } catch let error as PrismediaAPIError where error.isMissingRoute {
                // The server reports a qualifying version but predates the route.
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                throw BookAlignmentLoadError(contract: .serverAlignment, underlying: error)
            }
        }

        do {
            return .legacy(try await service.loadBookChapterMappings(bookID: bookID))
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw BookAlignmentLoadError(contract: .legacyCursor, underlying: error)
        }
    }

    // MARK: - Actions - Saving

    /// Replaces the Book's manual chapter mappings through the route shape of `contract`.
    func save(
        bookID: UUID,
        mappings: [BookChapterAudioMapping],
        contract: BookProgressContract
    ) async throws -> BookAlignmentSnapshot {
        switch contract {
        case .serverAlignment:
            return .server(try await service.saveBookChapterMappings(bookID: bookID, mappings: mappings))
        case .legacyCursor:
            return .legacy(try await service.replaceBookChapterMappings(bookID: bookID, mappings: mappings))
        }
    }
}
