import Foundation

#if os(iOS) || os(macOS)
    struct IdentifyEntryPresentation: Identifiable {
        let entityID: UUID
        let session: IdentifySession

        var id: UUID {
            entityID
        }
    }
#endif
