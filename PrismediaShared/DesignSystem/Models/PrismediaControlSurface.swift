enum PrismediaControlSurface: Hashable, Sendable {
    case floating
    case embedded

    var usesGlass: Bool {
        self == .floating
    }
}
