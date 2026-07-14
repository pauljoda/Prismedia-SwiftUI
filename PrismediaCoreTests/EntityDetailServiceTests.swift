import XCTest

@testable import PrismediaCore

@MainActor
final class EntityDetailServiceTests: XCTestCase {
    private let link = EntityLink(
        entityID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        kind: .movie
    )

    func testLoadPublishesContentForRequestedEntity() async throws {
        let detail = try makeDetail(title: "Arrival")
        let loader = EntityDetailLoaderStub(responses: [.success(detail)])
        var feature = EntityDetailTestHarness(link: link, loader: loader)

        XCTAssertTrue(feature.state.phase.isLoading)
        XCTAssertFalse(feature.canMutate)

        await feature.load()

        guard case .content(let loaded) = feature.state.phase else {
            return XCTFail("Expected loaded entity detail.")
        }
        XCTAssertEqual(loaded, detail)
        let requestedIDs = await loader.requestedEntityIDs()
        XCTAssertEqual(requestedIDs, [link.entityID])
    }

    func testFailurePublishesActionableMessage() async {
        let loader = EntityDetailLoaderStub(responses: [.failure(.offline)])
        var feature = EntityDetailTestHarness(link: link, loader: loader)

        await feature.load()

        guard case .failure(let message) = feature.state.phase else {
            return XCTFail("Expected failure state.")
        }
        XCTAssertEqual(message, "The server is unavailable.")
    }

    func testRetryTransitionsThroughLoadingAndRecovers() async throws {
        let detail = try makeDetail(title: "Recovered")
        let loader = EntityDetailLoaderStub(responses: [
            .failure(.offline),
            .success(detail),
        ])
        var feature = EntityDetailTestHarness(link: link, loader: loader)

        await feature.load()
        guard case .failure = feature.state.phase else {
            return XCTFail("Expected the initial request to fail.")
        }

        await feature.load()

        guard case .content(let loaded) = feature.state.phase else {
            return XCTFail("Expected retry to recover.")
        }
        XCTAssertEqual(loaded.title, "Recovered")
        let requestedIDs = await loader.requestedEntityIDs()
        XCTAssertEqual(requestedIDs.count, 2)
    }

    func testEmptyAndUnknownCapabilitiesStillPublishContent() async throws {
        let detail = try makeDetail(
            title: "Future Entity",
            capabilities: #"[{"kind":"future-native-surface","mode":"ambient"}]"#
        )
        let loader = EntityDetailLoaderStub(responses: [.success(detail)])
        var feature = EntityDetailTestHarness(link: link, loader: loader)

        await feature.load()

        guard case .content(let loaded) = feature.state.phase else {
            return XCTFail("Expected unknown capabilities to remain renderable.")
        }
        guard case .unknown(let capability) = loaded.capabilities.first else {
            return XCTFail("Expected unknown capability to be preserved.")
        }
        XCTAssertEqual(capability.kind, "future-native-surface")
    }

    func testNewerLoadRequestRejectsAnOlderResponse() throws {
        var state = EntityDetailState()
        let olderRequest = try XCTUnwrap(state.beginLoad())
        let newerRequest = try XCTUnwrap(state.beginLoad())
        let staleDetail = try makeDetail(title: "Stale")
        let currentDetail = try makeDetail(title: "Current")

        state.finishLoad(.content(currentDetail), request: newerRequest)
        state.finishLoad(.content(staleDetail), request: olderRequest)

        guard case .content(let loaded) = state.phase else {
            return XCTFail("Expected the newest response to remain visible.")
        }
        XCTAssertEqual(loaded.title, "Current")
    }

    func testCancelledLoadLeavesThePendingLoadingStateUntouched() async throws {
        let service = EntityDetailService(
            loader: CancelledEntityDetailLoader(),
            mutator: nil
        )
        var state = EntityDetailState()
        let request = try XCTUnwrap(state.beginLoad())

        let outcome = await service.load(id: link.entityID)
        state.finishLoad(outcome, request: request)

        XCTAssertTrue(state.phase.isLoading)
    }

    func testRatingMutationPublishesServerUpdatedDetail() async throws {
        let initial = try makeDetail(title: "Arrival", capabilities: #"[{"kind":"rating","value":2}]"#)
        let shallowMutation = try makeDetail(title: "Arrival", capabilities: #"[{"kind":"rating","value":5}]"#)
        let refreshed = try makeDetail(title: "Arrival", capabilities: #"[{"kind":"rating","value":5}]"#)
        let service = EntityDetailMutationServiceStub(
            loadResponses: [.success(initial), .success(refreshed)],
            mutationResponses: [.success(shallowMutation)]
        )
        var feature = EntityDetailTestHarness(link: link, loader: service, mutator: service)
        XCTAssertTrue(feature.canMutate)
        await feature.load()

        await feature.updateRating(5)

        XCTAssertFalse(feature.state.isMutating)
        XCTAssertNil(feature.state.mutationErrorMessage)
        let mutations = await service.mutations()
        let requestedEntityIDs = await service.requestedEntityIDs()
        XCTAssertEqual(mutations, [.rating(5)])
        XCTAssertEqual(requestedEntityIDs, [link.entityID, link.entityID])
        guard case .content(let detail) = feature.state.phase,
            case .rating(let rating) = detail.capabilities.first
        else {
            return XCTFail("Expected the server-updated rating detail.")
        }
        XCTAssertEqual(rating.value, 5)
    }

    func testFavoriteAndOrganizedTogglesUseCurrentServerFlags() async throws {
        let initial = try makeDetail(
            title: "Arrival",
            capabilities: #"[{"kind":"flags","isFavorite":false,"isNsfw":false,"isOrganized":true,"isWanted":false}]"#
        )
        let favoriteMutation = try makeDetail(
            title: "Arrival",
            capabilities: #"[{"kind":"flags","isFavorite":true,"isNsfw":false,"isOrganized":true,"isWanted":false}]"#
        )
        let favoriteRefreshed = try makeDetail(
            title: "Arrival",
            capabilities: #"[{"kind":"flags","isFavorite":true,"isNsfw":false,"isOrganized":true,"isWanted":false}]"#
        )
        let organizedMutation = try makeDetail(
            title: "Arrival",
            capabilities: #"[{"kind":"flags","isFavorite":true,"isNsfw":false,"isOrganized":false,"isWanted":false}]"#
        )
        let organizedRefreshed = try makeDetail(
            title: "Arrival",
            capabilities: #"[{"kind":"flags","isFavorite":true,"isNsfw":false,"isOrganized":false,"isWanted":false}]"#
        )
        let service = EntityDetailMutationServiceStub(
            loadResponses: [.success(initial), .success(favoriteRefreshed), .success(organizedRefreshed)],
            mutationResponses: [.success(favoriteMutation), .success(organizedMutation)]
        )
        var feature = EntityDetailTestHarness(link: link, loader: service, mutator: service)
        await feature.load()

        await feature.toggleFavorite()
        await feature.toggleOrganized()

        let mutations = await service.mutations()
        XCTAssertEqual(
            mutations,
            [
                .flags(isFavorite: true, isOrganized: nil),
                .flags(isFavorite: nil, isOrganized: false),
            ])
    }

    func testFailedMutationPreservesContentAndPublishesActionableError() async throws {
        let initial = try makeDetail(title: "Arrival", capabilities: #"[{"kind":"rating","value":2}]"#)
        let service = EntityDetailMutationServiceStub(
            loadResponses: [.success(initial)],
            mutationResponses: [.failure(.offline)]
        )
        var feature = EntityDetailTestHarness(link: link, loader: service, mutator: service)
        await feature.load()

        await feature.updateRating(5)

        XCTAssertFalse(feature.state.isMutating)
        XCTAssertEqual(
            feature.state.mutationErrorMessage,
            "The server is unavailable."
        )
        guard case .content(let detail) = feature.state.phase,
            case .rating(let rating) = detail.capabilities.first
        else {
            return XCTFail("Expected the original content to remain visible.")
        }
        XCTAssertEqual(rating.value, 2)
    }

    func testSuccessfulSaveMergesUserMetadataWhileFullRefreshIsPending() throws {
        let initial = try makeDetail(
            title: "Arrival",
            capabilities: #"[{"kind":"description","value":"A complete detail."},{"kind":"rating","value":2}]"#,
            relationships: groupJSON(
                kind: "person",
                label: "Cast",
                id: "33333333-3333-3333-3333-333333333333"
            )
        )
        let shallowMutation = try makeDetail(
            title: "Arrival",
            capabilities: #"[{"kind":"rating","value":5}]"#
        )
        var state = EntityDetailState()
        let loadRequest = try XCTUnwrap(state.beginLoad())
        state.finishLoad(.content(initial), request: loadRequest)
        let mutationRequest = try XCTUnwrap(state.beginMutation(canMutate: true))

        let saved = state.finishMutationSave(
            .content(shallowMutation),
            request: mutationRequest
        )

        XCTAssertTrue(saved)
        XCTAssertTrue(state.isMutating)
        guard case .content(let detail) = state.phase else {
            return XCTFail("Expected merged detail while refresh is pending.")
        }
        XCTAssertEqual(detail.relationships.count, 1)
        XCTAssertTrue(
            detail.capabilities.contains {
                if case .description = $0 { return true }
                return false
            })
        XCTAssertTrue(
            detail.capabilities.contains {
                if case .rating(let rating) = $0 { return rating.value == 5 }
                return false
            })
    }

    func testSuccessfulMutationRefreshesFullDetailAfterMergingNarrowResponse() async throws {
        let initial = try makeDetail(
            title: "Arrival",
            capabilities: #"[{"kind":"description","value":"A complete detail."},{"kind":"rating","value":2}]"#,
            childrenByKind: groupJSON(kind: "video", label: "Videos", id: "22222222-2222-2222-2222-222222222222"),
            relationships: groupJSON(kind: "person", label: "Cast", id: "33333333-3333-3333-3333-333333333333")
        )
        let shallowMutation = try makeDetail(
            title: "Arrival",
            capabilities: #"[{"kind":"rating","value":5}]"#
        )
        let refreshed = try makeDetail(
            title: "Arrival",
            capabilities: #"[{"kind":"description","value":"A complete detail."},{"kind":"rating","value":5}]"#,
            childrenByKind: groupJSON(kind: "video", label: "Videos", id: "22222222-2222-2222-2222-222222222222"),
            relationships: groupJSON(kind: "person", label: "Cast", id: "33333333-3333-3333-3333-333333333333")
        )
        let service = EntityDetailMutationServiceStub(
            loadResponses: [.success(initial), .success(refreshed)],
            mutationResponses: [.success(shallowMutation)]
        )
        var feature = EntityDetailTestHarness(link: link, loader: service, mutator: service)
        await feature.load()

        await feature.updateRating(5)

        guard case .content(let detail) = feature.state.phase else {
            return XCTFail("Expected refreshed full detail content.")
        }
        XCTAssertEqual(
            detail.childrenByKind.first?.entities.first?.id.uuidString.lowercased(),
            "22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(
            detail.relationships.first?.entities.first?.id.uuidString.lowercased(),
            "33333333-3333-3333-3333-333333333333")
        XCTAssertTrue(
            detail.capabilities.contains {
                if case .description = $0 { return true }
                return false
            })
        XCTAssertTrue(
            detail.capabilities.contains {
                if case .rating(let rating) = $0 { return rating.value == 5 }
                return false
            })
    }

    func testRefreshFailureAfterSuccessfulMutationKeepsOriginalDetailVisible() async throws {
        let initial = try makeDetail(
            title: "Arrival",
            capabilities: #"[{"kind":"rating","value":2}]"#,
            relationships: groupJSON(kind: "person", label: "Cast", id: "33333333-3333-3333-3333-333333333333")
        )
        let shallowMutation = try makeDetail(title: "Arrival", capabilities: #"[{"kind":"rating","value":5}]"#)
        let service = EntityDetailMutationServiceStub(
            loadResponses: [.success(initial), .failure(.offline)],
            mutationResponses: [.success(shallowMutation)]
        )
        var feature = EntityDetailTestHarness(link: link, loader: service, mutator: service)
        await feature.load()

        await feature.updateRating(5)

        XCTAssertFalse(feature.state.isMutating)
        XCTAssertEqual(
            feature.state.mutationErrorMessage,
            "The change was saved, but the latest details couldn’t be refreshed."
        )
        guard case .content(let detail) = feature.state.phase else {
            return XCTFail("Expected merged full detail to remain visible.")
        }
        XCTAssertEqual(detail.relationships.count, 1)
        XCTAssertTrue(
            detail.capabilities.contains {
                if case .rating(let rating) = $0 { return rating.value == 5 }
                return false
            })
    }

    private func makeDetail(
        title: String,
        capabilities: String = "[]",
        childrenByKind: String = "[]",
        relationships: String = "[]"
    ) throws -> EntityDetail {
        let json = """
            {
              "id": "\(link.entityID.uuidString)",
              "kind": "movie",
              "title": "\(title)",
              "parentEntityId": null,
              "sortOrder": null,
              "hasSourceMedia": true,
              "capabilities": \(capabilities),
              "childrenByKind": \(childrenByKind),
              "relationships": \(relationships)
            }
            """
        return try PrismediaJSON.decoder().decode(EntityDetail.self, from: Data(json.utf8))
    }

    private func groupJSON(kind: String, label: String, id: String) -> String {
        """
        [{
          "kind": "\(kind)",
          "label": "\(label)",
          "entities": [{
            "id": "\(id)",
            "kind": "\(kind)",
            "title": "Related entity",
            "meta": [],
            "hoverImages": [],
            "genres": [],
            "referenceCounts": []
          }]
        }]
        """
    }
}

@MainActor
private struct EntityDetailTestHarness {
    var state: EntityDetailState
    let link: EntityLink
    let service: EntityDetailService

    init(
        link: EntityLink,
        loader: any EntityDetailLoading,
        mutator: (any EntityDetailMutating)? = nil
    ) {
        state = EntityDetailState()
        self.link = link
        service = EntityDetailService(loader: loader, mutator: mutator)
    }

    var canMutate: Bool {
        service.canMutate
    }

    mutating func load() async {
        guard let request = state.beginLoad() else { return }
        let outcome = await service.load(id: link.entityID)
        state.finishLoad(outcome, request: request)
    }

    @discardableResult
    mutating func updateRating(_ value: Int?) async -> Bool {
        await mutate(.rating(value))
    }

    @discardableResult
    mutating func toggleFavorite() async -> Bool {
        guard let mutation = state.favoriteToggleMutation else { return false }
        return await mutate(mutation)
    }

    @discardableResult
    mutating func toggleOrganized() async -> Bool {
        guard let mutation = state.organizedToggleMutation else { return false }
        return await mutate(mutation)
    }

    private mutating func mutate(_ mutation: EntityDetailMutation) async -> Bool {
        guard let request = state.beginMutation(canMutate: service.canMutate) else {
            return false
        }

        let saveOutcome = await service.save(mutation, id: link.entityID)
        guard state.finishMutationSave(saveOutcome, request: request) else {
            return false
        }

        let refreshOutcome = await service.load(id: link.entityID)
        state.finishMutationRefresh(refreshOutcome, request: request)
        return true
    }
}

private actor EntityDetailLoaderStub: EntityDetailLoading {
    enum Response: Sendable {
        case success(EntityDetail)
        case failure(EntityDetailLoaderStubError)
    }

    private var responses: [Response]
    private var entityIDs: [UUID] = []

    init(responses: [Response]) {
        self.responses = responses
    }

    func loadEntity(id: UUID) async throws -> EntityDetail {
        entityIDs.append(id)
        guard !responses.isEmpty else { throw EntityDetailLoaderStubError.offline }
        switch responses.removeFirst() {
        case .success(let detail): return detail
        case .failure(let error): throw error
        }
    }

    func requestedEntityIDs() -> [UUID] {
        entityIDs
    }
}

private struct CancelledEntityDetailLoader: EntityDetailLoading {
    func loadEntity(id: UUID) async throws -> EntityDetail {
        throw CancellationError()
    }
}

private actor EntityDetailMutationServiceStub: EntityDetailLoading, EntityDetailMutating {
    enum Mutation: Equatable, Sendable {
        case rating(Int?)
        case flags(isFavorite: Bool?, isOrganized: Bool?)
    }

    private var loadResponses: [Result<EntityDetail, EntityDetailLoaderStubError>]
    private var mutationResponses: [Result<EntityDetail, EntityDetailLoaderStubError>]
    private var recordedMutations: [Mutation] = []
    private var requestedIDs: [UUID] = []

    init(
        loadResponses: [Result<EntityDetail, EntityDetailLoaderStubError>],
        mutationResponses: [Result<EntityDetail, EntityDetailLoaderStubError>]
    ) {
        self.loadResponses = loadResponses
        self.mutationResponses = mutationResponses
    }

    func loadEntity(id: UUID) async throws -> EntityDetail {
        requestedIDs.append(id)
        guard !loadResponses.isEmpty else { throw EntityDetailLoaderStubError.offline }
        return try loadResponses.removeFirst().get()
    }

    func updateRating(id: UUID, value: Int?) async throws -> EntityDetail {
        recordedMutations.append(.rating(value))
        return try nextResponse().get()
    }

    func updateFlags(id: UUID, isFavorite: Bool?, isOrganized: Bool?) async throws -> EntityDetail {
        recordedMutations.append(.flags(isFavorite: isFavorite, isOrganized: isOrganized))
        return try nextResponse().get()
    }

    func mutations() -> [Mutation] { recordedMutations }
    func requestedEntityIDs() -> [UUID] { requestedIDs }

    private func nextResponse() -> Result<EntityDetail, EntityDetailLoaderStubError> {
        guard !mutationResponses.isEmpty else { return .failure(.offline) }
        return mutationResponses.removeFirst()
    }
}

private enum EntityDetailLoaderStubError: Error, LocalizedError, Sendable {
    case offline

    var errorDescription: String? {
        "The server is unavailable."
    }
}
