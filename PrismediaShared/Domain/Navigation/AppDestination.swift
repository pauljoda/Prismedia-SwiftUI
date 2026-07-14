public struct AppDestination: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let systemImage: String
    public let content: AppDestinationContent

    public init(
        id: String,
        title: String,
        systemImage: String,
        content: AppDestinationContent
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.content = content
    }
}
