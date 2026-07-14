public enum EntityDestinationPlatform: Hashable, Sendable {
    case iOS
    case macOS
    case tvOS

    public static var current: Self {
        #if os(iOS)
            .iOS
        #elseif os(tvOS)
            .tvOS
        #else
            .macOS
        #endif
    }
}
