import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityDownloadList: View {
        @Binding var selectedIDs: Set<UUID>
        @Binding var selectedStatus: RequestActivityStatusFilter
        @Binding var selectedKind: EntityKind?
        @Binding var sort: RequestActivitySort

        let items: [RequestActivityDownload]
        let availableKinds: [EntityKind]
        let sourceIsEmpty: Bool
        let errorMessage: String?
        let isActing: Bool
        let resolveAssetURL: (String) -> URL?
        let onPrimaryAction: (RequestActivityDownload) -> Void
        let onManage: (RequestActivityDownload) -> Void
        let onOpenEntity: (RequestActivityDownload) -> Void
        let onRemove: (RequestActivityDownload) -> Void

        var body: some View {
            List(selection: $selectedIDs) {
                RequestActivityInlineErrorSection(
                    message: errorMessage,
                    sourceIsEmpty: sourceIsEmpty
                )
                RequestActivityDownloadFilters(
                    status: $selectedStatus,
                    kind: $selectedKind,
                    sort: $sort,
                    availableKinds: availableKinds
                )
                ForEach(items) { item in
                    RequestActivityDownloadRow(
                        item: item,
                        isActing: isActing,
                        imageURL: item.posterURL.flatMap(resolveAssetURL),
                        onPrimaryAction: onPrimaryAction,
                        onManage: onManage,
                        onOpenEntity: onOpenEntity,
                        onRemove: onRemove
                    )
                    .tag(item.id)
                    .selectionDisabled(RequestActivityStatusPolicy.isTransitionLocked(item.status))
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Remove", systemImage: "trash", role: .destructive) {
                            onRemove(item)
                        }
                        .disabled(
                            RequestActivityStatusPolicy.isTransitionLocked(item.status)
                                || isActing
                        )
                    }
                }
            }
        }
    }

    #if DEBUG
        #Preview("Request Activity Downloads · Content") {
            RequestActivityDownloadList(
                selectedIDs: .constant([]),
                selectedStatus: .constant(.all),
                selectedKind: .constant(nil),
                sort: .constant(.updatedNewest),
                items: [RequestActivityPreviewFixtures.download],
                availableKinds: [.book],
                sourceIsEmpty: false,
                errorMessage: nil,
                isActing: false,
                resolveAssetURL: { URL(string: $0) },
                onPrimaryAction: { _ in },
                onManage: { _ in },
                onOpenEntity: { _ in },
                onRemove: { _ in }
            )
        }

        #Preview("Request Activity Downloads · Refresh Error") {
            RequestActivityDownloadList(
                selectedIDs: .constant([]),
                selectedStatus: .constant(.all),
                selectedKind: .constant(nil),
                sort: .constant(.updatedNewest),
                items: [RequestActivityPreviewFixtures.download],
                availableKinds: [.book],
                sourceIsEmpty: false,
                errorMessage: "The latest status could not be refreshed.",
                isActing: true,
                resolveAssetURL: { URL(string: $0) },
                onPrimaryAction: { _ in },
                onManage: { _ in },
                onOpenEntity: { _ in },
                onRemove: { _ in }
            )
            .dynamicTypeSize(.accessibility3)
        }
    #endif
#endif
