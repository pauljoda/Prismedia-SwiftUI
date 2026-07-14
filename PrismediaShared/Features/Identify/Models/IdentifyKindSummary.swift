import Foundation

#if os(iOS) || os(macOS)
    struct IdentifyKindSummary: Identifiable, Hashable, Sendable {
        let kind: EntityKind
        let pendingCount: Int
        var id: String { kind.rawValue }
    }
#endif
