import Foundation

enum EntityAcquisitionCommand: Equatable, Sendable {
    case start(UUID)
    case pause(UUID)
    case resume(UUID)
    case searchAgain(UUID)
    case searchForRelease(UUID)
    case syncContainer(UUID)
    case searchMissingChildren(UUID)
    case unmonitor(UUID)
}
