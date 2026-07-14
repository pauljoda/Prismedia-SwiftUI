import Foundation

#if os(iOS) || os(macOS)
    enum IdentifyBrowseFilter: String, CaseIterable, Identifiable, Sendable {
        case unorganized
        case all

        var id: String { rawValue }
        var label: String { self == .unorganized ? "Unorganized" : "Show All" }
    }
#endif
