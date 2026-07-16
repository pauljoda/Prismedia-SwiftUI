public enum AppDestinationContent: Hashable, Sendable {
    case dashboard
    case account
    case playbackStatistics
    case entityList(EntityListDestination)
    case administration(AdministrativeDestination)
    #if os(iOS) || os(macOS)
        case manage(ManageDestination)
    #endif
}
