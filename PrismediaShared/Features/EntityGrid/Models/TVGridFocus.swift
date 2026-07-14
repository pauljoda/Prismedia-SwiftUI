#if os(tvOS)
    import Foundation

    enum TVGridFocus: Hashable {
        case sort
        case filter
        case display
        case item(UUID)
    }
#endif
