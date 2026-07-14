#if os(iOS) || os(macOS)
    import SwiftUI

    /// Keeps transport-control symbol changes from inheriting surrounding glass
    /// or presentation animations.
    func withoutMusicControlAnimation(_ action: () -> Void) {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction, action)
    }
#endif
