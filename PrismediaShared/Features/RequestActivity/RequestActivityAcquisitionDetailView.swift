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
                    onEnterReleaseDate: enterReleaseDateBehindSheet
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

    extension RequestActivityAcquisitionDetailView {
        // MARK: - Actions - Release date

        /// Opens the release-date editor's entity underneath while this sheet is still up, then closes
        /// the sheet, so it slides away over that entity instead of leaving the editor unable to present
        /// above it. The hidden push skips its animation and the sheet closes on the next turn, so the
        /// entity is already in place and no part of the activity list shows as the sheet slides away.
        fileprivate var enterReleaseDateBehindSheet: (@MainActor @Sendable () -> Void)? {
            guard let onEnterReleaseDate else { return nil }
            let dismiss = dismiss
            return { @MainActor @Sendable in
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) { onEnterReleaseDate() }
                Task { @MainActor in dismiss() }
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
