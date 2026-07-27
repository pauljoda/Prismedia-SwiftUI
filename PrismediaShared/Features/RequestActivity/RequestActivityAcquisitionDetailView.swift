import SwiftUI

#if os(iOS) || os(macOS)
    /// Sheet chrome around the shared acquisition management sections: navigation stack,
    /// grouped list styling, and the close control.
    struct RequestActivityAcquisitionDetailView: View {
        @Environment(\.dismiss) private var dismiss

        let acquisitionID: UUID
        let service: any RequestActivityServicing
        let onEnterReleaseDate: (@MainActor @Sendable () -> Void)?

        init(
            acquisitionID: UUID,
            service: any RequestActivityServicing,
            onEnterReleaseDate: (@MainActor @Sendable () -> Void)? = nil
        ) {
            self.acquisitionID = acquisitionID
            self.service = service
            self.onEnterReleaseDate = onEnterReleaseDate
        }

        var body: some View {
            NavigationStack {
                RequestActivityAcquisitionManagementSections(
                    acquisitionID: acquisitionID,
                    service: service,
                    style: .list,
                    onEnterReleaseDate: onEnterReleaseDate
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: dismiss.callAsFunction) {
                            Image(systemName: "xmark")
                        }
                        .accessibilityLabel("Close")
                    }
                }
            }
        }
    }

    #if DEBUG
        #Preview("Request Activity Acquisition") {
            RequestActivityAcquisitionDetailView(
                acquisitionID: RequestActivityPreviewFixtures.acquisitionID,
                service: PreviewRequestActivityService(scenario: .content)
            )
        }
    #endif
#endif
