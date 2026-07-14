import Foundation

#if os(iOS) || os(macOS)
    struct IdentifyNextFlow {
        static func next(after current: UUID?, in ids: [UUID]) -> UUID? {
            guard !ids.isEmpty else { return nil }
            guard let current, let index = ids.firstIndex(of: current) else { return ids.first }
            return ids[(index + 1) % ids.count]
        }

        static func previous(before current: UUID?, in ids: [UUID]) -> UUID? {
            guard !ids.isEmpty else { return nil }
            guard let current, let index = ids.firstIndex(of: current) else { return ids.last }
            return ids[(index - 1 + ids.count) % ids.count]
        }
    }
#endif
