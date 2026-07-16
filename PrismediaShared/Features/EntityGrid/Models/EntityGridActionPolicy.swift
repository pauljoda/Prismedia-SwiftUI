import Foundation

public struct EntityGridActionPolicy: Sendable {
    public let selectionEnabled: Bool
    public let builtInActions: Set<EntityGridBuiltInAction>
    public let customActions: [EntityGridCustomAction]

    public init(
        selectionEnabled: Bool,
        builtInActions: Set<EntityGridBuiltInAction> = [],
        customActions: [EntityGridCustomAction] = []
    ) {
        self.selectionEnabled = selectionEnabled
        self.builtInActions = builtInActions
        self.customActions = customActions
    }

    public static let disabled = EntityGridActionPolicy(selectionEnabled: false)

    public static func library(
        user: UserAccount,
        customActions: [EntityGridCustomAction] = []
    ) -> EntityGridActionPolicy {
        var actions: Set<EntityGridBuiltInAction> = [.addToCollection, .removeWanted]
        if user.allowSfw && user.allowNsfw {
            actions.insert(.toggleNsfw)
        }
        return EntityGridActionPolicy(
            selectionEnabled: true,
            builtInActions: actions,
            customActions: customActions
        )
    }

    public func availableBuiltInActions(
        for selectedItems: [EntityThumbnail]
    ) -> Set<EntityGridBuiltInAction> {
        guard selectionEnabled, !selectedItems.isEmpty else { return [] }
        var actions = builtInActions
        if collectionReferences(in: selectedItems).isEmpty {
            actions.remove(.addToCollection)
        }
        if !selectedItems.allSatisfy(\.isWanted) {
            actions.remove(.removeWanted)
        }
        return actions
    }

    public func collectionReferences(
        in selectedItems: [EntityThumbnail]
    ) -> [CollectionEntityReference] {
        guard builtInActions.contains(.addToCollection) else { return [] }
        return selectedItems.compactMap { item in
            guard Self.collectionEntityKinds.contains(item.kind) else { return nil }
            return CollectionEntityReference(entityType: item.kind, entityID: item.id)
        }
    }

    public func nsfwMutationValue(for selectedItems: [EntityThumbnail]) -> Bool {
        !selectedItems.allSatisfy(\.isNsfw)
    }

    public func availableCustomActions(
        for selectedItems: [EntityThumbnail]
    ) -> [EntityGridCustomAction] {
        guard selectionEnabled, !selectedItems.isEmpty else { return [] }
        return customActions.filter { $0.isAvailable(for: selectedItems) }
    }

    private static let collectionEntityKinds: Set<EntityKind> = [
        .video,
        .movie,
        .videoSeries,
        .gallery,
        .image,
        .book,
        .musicArtist,
        .audioLibrary,
        .audioTrack,
    ]
}
