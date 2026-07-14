import Foundation

public enum RequestActivityTone: Hashable, Sendable {
    case downloading
    case searching
    case queued
    case cleanup
    case attention
    case failed
    case done
    case muted
}
