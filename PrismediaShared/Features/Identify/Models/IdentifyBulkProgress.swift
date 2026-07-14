import Foundation

#if os(iOS) || os(macOS)
    struct IdentifyBulkProgress: Hashable, Sendable {
        let completed: Int
        let total: Int
        var fraction: Double { total == 0 ? 0 : Double(completed) / Double(total) }
    }
#endif
