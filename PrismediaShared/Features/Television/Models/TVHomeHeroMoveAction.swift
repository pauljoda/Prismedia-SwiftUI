enum TVHomeHeroMoveAction: Equatable, Sendable {
    case none
    case select(index: Int)
    case focusTabs
}
