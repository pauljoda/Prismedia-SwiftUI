public enum AppSidebarSelection: Hashable, Sendable {
    case destination(modeID: String, destinationID: String)
    case search
}
