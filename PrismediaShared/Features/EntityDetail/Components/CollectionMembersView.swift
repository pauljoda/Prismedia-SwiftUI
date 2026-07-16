import SwiftUI

/// Platform-shared collection membership surface. The adaptive thumbnail grid
/// keeps native navigation and focus behavior while retaining mixed media in
/// the exact order supplied by the collection endpoint.
struct CollectionMembersView: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
    @Environment(\.artworkSecondaryText) private var artworkSecondaryText
    @Environment(PrismediaAppEnvironment.self) private var environment
    let collectionID: UUID
    let phase: CollectionMembersPhase
    let horizontalPadding: CGFloat
    let retry: @MainActor @Sendable () -> Void

    var body: some View {
        switch phase {
        case .idle, .loading:
            loadingView
        case .content(let members):
            if !members.isEmpty {
                membersGrid(members)
            } else {
                emptyView
            }
        case .failure(let message):
            failureView(message)
        }
    }

    private func membersGrid(_ members: [EntityThumbnail]) -> some View {
        let kinds = Array(Set(members.map(\.kind))).sorted { $0.rawValue < $1.rawValue }
        let query =
            kinds.count == 1
            ? EntityListQuery(kind: kinds.first)
            : EntityListQuery(kinds: kinds)

        return EntityGridView(
            configuration: EntityGridConfiguration(
                title: "Items",
                query: query,
                pageSize: 48,
                minimumColumnWidth: 150,
                defaultDisplayMode: .grid,
                availableDisplayModes: [.grid, .list],
                emptyTitle: "Empty Collection",
                emptyDescription: "This collection has no items.",
                preferencesID: "collection-\(collectionID.uuidString.lowercased())-items"
            ),
            loader: StaticEntityGridLoader(
                items: members,
                allowsNsfwContent: environment.allowsNsfwContent
            ),
            presentation: .embedded,
            horizontalContentPadding: horizontalPadding,
            actionPolicy: collectionActionPolicy,
            mutationService: environment.client
        ) { item, layout in
            EntityThumbnailNavigationSurface(item: item, layout: layout)
        }
    }

    private var collectionActionPolicy: EntityGridActionPolicy {
        guard let client = environment.client, let user = environment.session?.user else {
            return .disabled
        }
        let collectionID = collectionID
        let retry = retry
        let removal = EntityGridCustomAction(
            id: "remove-from-collection",
            label: "Remove from Collection",
            systemImage: "trash",
            isDestructive: true,
            confirmationTitle: "Remove Selected Collection Items?",
            confirmationMessage:
                "This removes membership only. The media remains in your libraries. Dynamic collections can only be changed through their rules."
        ) { items in
            do {
                let memberIDs = try await client.fetchCollectionMemberIDs(collectionID: collectionID)
                let result = await EntityGridActionService(mutations: client).removeFromCollection(
                    collectionID,
                    membersByEntityID: memberIDs,
                    items: items
                )
                if !result.succeededIDs.isEmpty { retry() }
                return result
            } catch {
                return EntityGridMutationResult(
                    failures: items.map {
                        EntityGridMutationFailure(
                            entityID: $0.id,
                            title: $0.title,
                            message: error.localizedDescription
                        )
                    }
                )
            }
        }
        return .library(user: user, customActions: [removal])
    }

    private var loadingView: some View {
        HStack(spacing: PrismediaSpacing.large) {
            ProgressView()
                .tint(artworkPrimaryAccent)
            Text("Loading collection items…")
                .font(.body)
                .foregroundStyle(artworkSecondaryText)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, horizontalPadding)
        .frame(minHeight: 180)
        .accessibilityIdentifier("entity-detail.collection.loading")
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "No Items",
            systemImage: "rectangle.stack",
            description: Text("This collection is empty.")
        )
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding(.horizontal, horizontalPadding)
        .accessibilityIdentifier("entity-detail.collection.empty")
    }

    private func failureView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Couldn’t Load Collection", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            PrismediaButton("Try Again", variant: .prominent, action: retry)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding(.horizontal, horizontalPadding)
        .accessibilityIdentifier("entity-detail.collection.failure")
    }
}

#if DEBUG

    #Preview("Collection · Mixed Media") {
        NavigationStack {
            ScrollView {
                CollectionMembersView(
                    collectionID: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
                    phase: .content(CollectionMembersPreviewFixture.mixed),
                    horizontalPadding: PrismediaSpacing.extraLarge,
                    retry: {}
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    #Preview("Collection · Loading") {
        CollectionMembersView(
            collectionID: UUID(),
            phase: .loading,
            horizontalPadding: PrismediaSpacing.extraLarge,
            retry: {}
        )
        .preferredColorScheme(.dark)
    }

    #Preview("Collection · Empty · Accessibility") {
        CollectionMembersView(
            collectionID: UUID(),
            phase: .content([]),
            horizontalPadding: PrismediaSpacing.extraLarge,
            retry: {}
        )
        .environment(\.dynamicTypeSize, .accessibility3)
    }

    #Preview("Collection · Error") {
        CollectionMembersView(
            collectionID: UUID(),
            phase: .failure("The server couldn’t return this collection."),
            horizontalPadding: PrismediaSpacing.extraLarge,
            retry: {}
        )
        .preferredColorScheme(.dark)
    }
#endif
