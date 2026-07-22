import SwiftUI

struct EntityChildAcquisitionActivityRow: View {
    let item: EntityChildAcquisitionActivityItem

    var body: some View {
        NavigationLink(value: EntityLink(thumbnail: item.entity)) {
            HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
                artwork
                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    Text(item.entity.title)
                        .font(.headline)
                        .foregroundStyle(PrismediaColor.textPrimary)
                        .lineLimit(2)

                    statusMetadata
                    progress

                    if let attentionDescription {
                        Text(attentionDescription)
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PrismediaColor.textMuted)
                    .padding(.top, PrismediaSpacing.extraSmall)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, PrismediaSpacing.extraSmall)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens this child’s details")
        .accessibilityIdentifier("entity-detail.acquisition.child-activity.\(item.id.uuidString)")
    }

    private var artwork: some View {
        EntityThumbnailCompactArtworkView(item: item.entity, width: 52)
    }

    private var statusMetadata: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PrismediaSpacing.small) {
                statusLabel
                timestamp
            }
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                statusLabel
                timestamp
            }
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        if item.isPreparingMetadata {
            Label("Preparing metadata", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                .font(.caption.weight(.semibold))
                .foregroundStyle(PrismediaColor.textSecondary)
        } else if let acquisition = item.acquisition {
            Label(
                RequestActivityStatusPolicy.label(for: acquisition.status),
                systemImage: RequestActivityStatusPolicy.systemImage(for: acquisition.status)
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(RequestActivityStatusPolicy.tone(for: acquisition.status).foregroundStyle)
        }
    }

    @ViewBuilder
    private var timestamp: some View {
        if let updatedAt = item.acquisition?.updatedAt ?? item.state.monitor?.updatedAt {
            Text("Updated \(updatedAt, format: .relative(presentation: .named))")
                .font(.caption)
                .foregroundStyle(PrismediaColor.textMuted)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private var progress: some View {
        if let acquisition = item.acquisition,
            RequestActivityStatusPolicy.showsDeterminateProgress(acquisition.status),
            let value = acquisition.progress
        {
            let clampedValue = min(max(value, 0), 1)
            ProgressView(value: clampedValue) {
                Text(RequestActivityStatusPolicy.label(for: acquisition.status))
            } currentValueLabel: {
                Text(clampedValue, format: .percent.precision(.fractionLength(0)))
                    .monospacedDigit()
            }
            .accessibilityValue(
                Text(clampedValue, format: .percent.precision(.fractionLength(0)))
            )
        }
    }

    private var attentionDescription: String? {
        guard let acquisition = item.acquisition else { return nil }
        guard EntityChildAcquisitionActivityPolicy.isAttentionRequired(item)
                || !RequestActivityStatusPolicy.isKnown(acquisition.status)
        else { return nil }
        return RequestActivityStatusPolicy.description(
            for: acquisition.status,
            message: acquisition.statusMessage
        )
    }
}

#if DEBUG && (os(iOS) || os(macOS))
    #Preview("Child Acquisition Activity Row") {
        PreviewShell {
            NavigationStack {
                EntityChildAcquisitionActivityRow(
                    item: EntityChildAcquisitionActivityPreviewFixtures.downloadingItem
                )
                .padding()
            }
        }
    }
#endif
