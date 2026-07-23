import Foundation

enum EntityAcquisitionHistoryPolicy {
    static let entryLimit = 50

    static func reachedEntryLimit(_ count: Int) -> Bool {
        count >= entryLimit
    }
}
