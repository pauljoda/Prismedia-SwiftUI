import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityHistoryList: View {
        let entries: [RequestActivityHistoryEntry]
        let sourceIsEmpty: Bool
        let errorMessage: String?
        let referenceDate: Date
        let onOpenEntity: (RequestActivityHistoryEntry) -> Void

        var body: some View {
            List {
                RequestActivityInlineErrorSection(
                    message: errorMessage,
                    sourceIsEmpty: sourceIsEmpty
                )
                ForEach(entries) { entry in
                    RequestActivityHistoryRow(
                        entry: entry,
                        referenceDate: referenceDate,
                        onOpenEntity: onOpenEntity
                    )
                }
            }
        }
    }

    #if DEBUG
        #Preview("Request Activity History List") {
            RequestActivityHistoryList(
                entries: [RequestActivityPreviewFixtures.historyEntry],
                sourceIsEmpty: false,
                errorMessage: nil,
                referenceDate: RequestActivityPreviewFixtures.referenceDate,
                onOpenEntity: { _ in }
            )
        }
    #endif
#endif
