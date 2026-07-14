import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityWantedRow: View {
        let item: RequestActivityWantedItem
        let list: RequestActivityWantedList
        let isActing: Bool
        let imageURL: URL?
        let referenceDate: Date
        let onSearchNow: (RequestActivityWantedItem) -> Void
        let onOpenEntity: (RequestActivityWantedItem) -> Void
        let onUnmonitor: (RequestActivityWantedItem) -> Void

        var body: some View {
            HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
                artwork
                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    heading
                    status
                    cadence
                    actions
                }
            }
            .padding(.vertical, PrismediaSpacing.extraSmall)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("request-activity.wanted.\(item.id.uuidString)")
        }

        private var artwork: some View {
            AsyncImage(url: imageURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Image(systemName: "shippingbox")
                        .resizable()
                        .scaledToFit()
                        .padding(PrismediaSpacing.medium)
                        .foregroundStyle(PrismediaColor.textMuted)
                }
            }
            .frame(width: 58, height: item.kind.prefersWideThumbnail ? 42 : 78)
            .background(PrismediaColor.controlFill)
            .compositingGroup()
            .clipShape(.rect(cornerRadius: PrismediaRadius.compact))
            .accessibilityHidden(true)
        }

        private var heading: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                Text(item.title)
                    .font(.headline)
                if let author = item.author {
                    Text(author)
                        .font(.subheadline)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
                HStack(spacing: PrismediaSpacing.small) {
                    Text(item.kind.displayLabel)
                    if list == .cutoffUnmet {
                        Text("\(item.ownedQuality ?? "—") → \(item.cutoffQuality ?? "—")")
                            .fontWeight(.semibold)
                    }
                }
                .font(.caption)
                .foregroundStyle(PrismediaColor.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        private var status: some View {
            let locked = RequestActivityWantedPolicy.isTransitionLocked(
                monitorStatus: item.monitorStatus,
                acquisitionStatus: item.acquisitionStatus
            )
            return VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Label(
                    RequestActivityWantedPolicy.statusLabel(for: item, list: list),
                    systemImage: locked ? "arrow.trianglehead.2.clockwise.rotate.90" : "magnifyingglass"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(locked ? PrismediaColor.textSecondary : PrismediaColor.accent)
                Text(
                    RequestActivityWantedPolicy.description(
                        monitorStatus: item.monitorStatus,
                        acquisitionStatus: item.acquisitionStatus,
                        list: list
                    )
                )
                .font(.caption)
                .foregroundStyle(PrismediaColor.textSecondary)
            }
        }

        private var cadence: some View {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PrismediaSpacing.small) { cadenceLabels }
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) { cadenceLabels }
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(PrismediaColor.textMuted)
        }

        @ViewBuilder
        private var cadenceLabels: some View {
            Text("Last \(RequestActivityFormatting.relative(item.lastSearchedAt, referenceDate: referenceDate))")
            Text("Next \(RequestActivityFormatting.nextSearch(item.nextSearchAt, referenceDate: referenceDate))")
            if item.barrenSearches > 0 {
                Text("\(item.barrenSearches) barren")
            }
        }

        @ViewBuilder
        private var actions: some View {
            if !RequestActivityWantedPolicy.isTransitionLocked(
                monitorStatus: item.monitorStatus,
                acquisitionStatus: item.acquisitionStatus
            ) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: PrismediaSpacing.small) { actionButtons }
                    VStack(alignment: .leading, spacing: PrismediaSpacing.small) { actionButtons }
                }
                .controlSize(.small)
            }
        }

        @ViewBuilder
        private var actionButtons: some View {
            PrismediaButton(
                "Search Now",
                systemImage: "arrow.clockwise",
                surface: .embedded
            ) {
                onSearchNow(item)
            }
            .disabled(isActing || item.acquisitionID == nil)
            if item.entityID != nil {
                PrismediaButton(
                    "Open in Library",
                    systemImage: "arrow.up.right.square",
                    surface: .embedded
                ) {
                    onOpenEntity(item)
                }
                .disabled(isActing)
            }
            PrismediaButton(
                "Unmonitor",
                systemImage: "bell.slash",
                variant: .destructive,
                surface: .embedded
            ) {
                onUnmonitor(item)
            }
            .disabled(isActing)
        }
    }

    #if DEBUG
        #Preview("Request Activity Wanted") {
            RequestActivityWantedRow(
                item: RequestActivityPreviewFixtures.wantedItem,
                list: .cutoffUnmet,
                isActing: false,
                imageURL: nil,
                referenceDate: RequestActivityPreviewFixtures.referenceDate,
                onSearchNow: { _ in },
                onOpenEntity: { _ in },
                onUnmonitor: { _ in }
            )
            .padding()
        }
    #endif
#endif
