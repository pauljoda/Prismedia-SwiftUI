public enum EntityGridPresentation: Hashable, Sendable {
    case screen
    case embedded

    public var ownsVerticalScrollContainer: Bool {
        self == .screen
    }

    public var controlPlacement: EntityGridControlPlacement {
        switch self {
        case .screen: .navigationToolbar
        case .embedded: .inline
        }
    }
}
