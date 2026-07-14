import Foundation

enum EntityAcquisitionCommand: Equatable, Sendable {
    case start(UUID)
    case pause(UUID)
    case resume(UUID)
    case searchAgain(UUID)
    case unmonitor(UUID)
}
