import Foundation

public enum AcquisitionStatusPresentationTone: Hashable, Sendable {
    case downloading
    case searching
    case queued
    case cleanup
    case attention
    case failed
    case done
    case muted
    case wanted
}
