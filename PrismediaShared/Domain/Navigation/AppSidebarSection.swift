public struct AppSidebarSection: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let items: [AppSidebarItem]

    public init(id: String, title: String, items: [AppSidebarItem]) {
        self.id = id
        self.title = title
        self.items = items
    }
}
