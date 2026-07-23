import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityWantedListView: View {
        @Binding var selectedIDs: Set<UUID>
        @Binding var selectedKind: EntityKind?
        @Binding var page: Int

        let items: [RequestActivityWantedItem]
        let list: RequestActivityWantedList
        let totalPages: Int
        let sourceIsEmpty: Bool
        let errorMessage: String?
        let isLoading: Bool
        let isActing: Bool
        let referenceDate: Date
        let resolveAssetURL: (String) -> URL?
        let onSearchNow: (RequestActivityWantedItem) -> Void
        let onOpenEntity: (RequestActivityWantedItem) -> Void
        let onUnmonitor: (RequestActivityWantedItem) -> Void

        var body: some View {
            List(selection: $selectedIDs) {
                RequestActivityInlineErrorSection(
                    message: errorMessage,
                    sourceIsEmpty: sourceIsEmpty
                )
                RequestActivityWantedFilters(kind: $selectedKind)
                ForEach(items) { item in
                    RequestActivityWantedRow(
                        item: item,
                        list: list,
                        isActing: isActing,
                        imageURL: item.posterURL.flatMap(resolveAssetURL),
                        referenceDate: referenceDate,
                        onSearchNow: onSearchNow,
                        onOpenEntity: onOpenEntity,
                        onUnmonitor: onUnmonitor
                    )
                    .tag(item.id)
                    .selectionDisabled(
                        RequestActivityWantedPolicy.isTransitionLocked(
                            monitorStatus: item.monitorStatus,
                            acquisitionStatus: item.acquisitionStatus
                        )
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Unmonitor", systemImage: "bell.slash", role: .destructive) {
                            onUnmonitor(item)
                        }
                        .disabled(isActing)
                    }
                }
                if totalPages > 1 {
                    RequestActivityPager(
                        page: page,
                        totalPages: totalPages,
                        isLoading: isLoading,
                        onPrevious: { page = max(1, page - 1) },
                        onNext: { page = min(totalPages, page + 1) }
                    )
                }
            }
        }
    }

    #if DEBUG
        #Preview("Request Activity Wanted · Missing") {
            RequestActivityWantedListView(
                selectedIDs: .constant([]),
                selectedKind: .constant(nil),
                page: .constant(1),
                items: [RequestActivityPreviewFixtures.wantedItem],
                list: .missing,
                totalPages: 1,
                sourceIsEmpty: false,
                errorMessage: nil,
                isLoading: false,
                isActing: false,
                referenceDate: RequestActivityPreviewFixtures.referenceDate,
                resolveAssetURL: { URL(string: $0) },
                onSearchNow: { _ in },
                onOpenEntity: { _ in },
                onUnmonitor: { _ in }
            )
        }

        #Preview("Request Activity Wanted · Cutoff · Accessibility") {
            RequestActivityWantedListView(
                selectedIDs: .constant([]),
                selectedKind: .constant(.book),
                page: .constant(1),
                items: [RequestActivityPreviewFixtures.wantedItem],
                list: .cutoffUnmet,
                totalPages: 3,
                sourceIsEmpty: false,
                errorMessage: "The latest page could not be refreshed.",
                isLoading: false,
                isActing: true,
                referenceDate: RequestActivityPreviewFixtures.referenceDate,
                resolveAssetURL: { URL(string: $0) },
                onSearchNow: { _ in },
                onOpenEntity: { _ in },
                onUnmonitor: { _ in }
            )
            .dynamicTypeSize(.accessibility3)
        }
    #endif
#endif
