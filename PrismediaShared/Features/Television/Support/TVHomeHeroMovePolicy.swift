/// Pure directional-command policy for the television home hero.
///
/// Up navigation is independent of carousel size so a single hero can always
/// return focus to the selected tab. Horizontal paging remains unavailable
/// until there is more than one item and always produces a valid index.
enum TVHomeHeroMovePolicy {
    static func action(
        for direction: TVHomeHeroMoveDirection,
        isFocused: Bool,
        selectedIndex: Int,
        itemCount: Int
    ) -> TVHomeHeroMoveAction {
        guard isFocused else { return .none }

        switch direction {
        case .up:
            return .focusTabs
        case .left:
            return pageAction(offset: -1, selectedIndex: selectedIndex, itemCount: itemCount)
        case .right:
            return pageAction(offset: 1, selectedIndex: selectedIndex, itemCount: itemCount)
        case .other:
            return .none
        }
    }

    private static func pageAction(
        offset: Int,
        selectedIndex: Int,
        itemCount: Int
    ) -> TVHomeHeroMoveAction {
        guard itemCount > 1 else { return .none }
        let boundedIndex = min(max(0, selectedIndex), itemCount - 1)
        let nextIndex = (boundedIndex + offset + itemCount) % itemCount
        return .select(index: nextIndex)
    }
}
