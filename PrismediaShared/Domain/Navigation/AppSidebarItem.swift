public struct AppSidebarItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let systemImage: String
    public let selection: AppSidebarSelection

    public init(
        id: String,
        title: String,
        systemImage: String,
        selection: AppSidebarSelection
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.selection = selection
    }
}
