import Foundation

public struct EntityGridCustomAction: Identifiable, Sendable {
    public let id: String
    public let label: String
    public let systemImage: String
    public let isDestructive: Bool
    public let confirmationTitle: String?
    public let confirmationMessage: String?
    private let availability: @Sendable ([EntityThumbnail]) -> Bool
    private let operation: @MainActor @Sendable ([EntityThumbnail]) async -> EntityGridMutationResult

    public init(
        id: String,
        label: String,
        systemImage: String,
        isDestructive: Bool = false,
        confirmationTitle: String? = nil,
        confirmationMessage: String? = nil,
        isAvailable: @escaping @Sendable ([EntityThumbnail]) -> Bool = { !$0.isEmpty },
        perform: @escaping @MainActor @Sendable ([EntityThumbnail]) async -> EntityGridMutationResult
    ) {
        self.id = id
        self.label = label
        self.systemImage = systemImage
        self.isDestructive = isDestructive
        self.confirmationTitle = confirmationTitle
        self.confirmationMessage = confirmationMessage
        availability = isAvailable
        operation = perform
    }

    public func isAvailable(for items: [EntityThumbnail]) -> Bool {
        availability(items)
    }

    @MainActor
    public func perform(with items: [EntityThumbnail]) async -> EntityGridMutationResult {
        await operation(items)
    }
}
