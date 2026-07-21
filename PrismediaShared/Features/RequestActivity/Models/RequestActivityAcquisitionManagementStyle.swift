import Foundation

#if os(iOS) || os(macOS)
    /// How the acquisition management sections render.
    enum RequestActivityAcquisitionManagementStyle: Equatable, Sendable {
        /// The request-activity sheet's original chrome: a `List` with grouped sections,
        /// navigation title, pull-to-refresh, and a toolbar action menu.
        case list
        /// Web-parity stacked layout for embedding inside the entity detail acquisition
        /// panel: status badge with inline actions and status-branched content.
        case embedded
    }
#endif
