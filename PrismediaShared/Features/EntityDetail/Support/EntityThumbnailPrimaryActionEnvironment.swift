import SwiftUI

private struct EntityThumbnailPrimaryActionEnvironmentKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: ((EntityThumbnail) -> Void)? = nil
}

extension EnvironmentValues {
    var entityThumbnailPrimaryAction: ((EntityThumbnail) -> Void)? {
        get { self[EntityThumbnailPrimaryActionEnvironmentKey.self] }
        set { self[EntityThumbnailPrimaryActionEnvironmentKey.self] = newValue }
    }
}
