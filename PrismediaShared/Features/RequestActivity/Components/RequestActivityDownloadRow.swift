import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityDownloadRow: View {
        let item: RequestActivityDownload
        let isActing: Bool
        let imageURL: URL?
        let onPrimaryAction: (RequestActivityDownload) -> Void
        let onManage: (RequestActivityDownload) -> Void
        let onOpenEntity: (RequestActivityDownload) -> Void
        let onRemove: (RequestActivityDownload) -> Void

        var body: some View {
            HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
                artwork
                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    heading
                    status
                    progress
                    telemetry
                    actions
                }
            }
            .padding(.vertical, PrismediaSpacing.extraSmall)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("request-activity.download.\(item.id.uuidString)")
        }

        private var artwork: some View {
            AsyncImage(url: imageURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Image(systemName: item.kind.prefersWideThumbnail ? "rectangle.stack" : "photo")
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
                    .foregroundStyle(PrismediaColor.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
                Text(item.kind.displayLabel)
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        private var status: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Label(
                    RequestActivityStatusPolicy.label(for: item.status),
                    systemImage: RequestActivityStatusPolicy.systemImage(for: item.status)
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(RequestActivityStatusPolicy.tone(for: item.status).foregroundStyle)
                if let description = RequestActivityStatusPolicy.description(
                    for: item.status,
                    message: item.statusMessage
                ) {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
            }
        }

        @ViewBuilder
        private var progress: some View {
            if RequestActivityStatusPolicy.showsDeterminateProgress(item.status), let value = item.progress {
                ProgressView(value: min(max(value, 0), 1)) {
                    Text(value, format: .percent.precision(.fractionLength(0)))
                }
                .accessibilityLabel("Download progress")
            } else if RequestActivityStatusPolicy.shouldPoll(item.status) {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Activity in progress")
            }
        }

        @ViewBuilder
        private var telemetry: some View {
            let parts = telemetryParts
            if !parts.isEmpty || item.clientName != nil {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: PrismediaSpacing.small) { telemetryLabels(parts) }
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) { telemetryLabels(parts) }
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(PrismediaColor.textSecondary)
            }
        }

        @ViewBuilder
        private func telemetryLabels(_ parts: [String]) -> some View {
            if let clientName = item.clientName {
                Label(clientName, systemImage: "externaldrive")
            }
            ForEach(parts, id: \.self) { part in
                Text(part)
            }
        }

        @ViewBuilder
        private var actions: some View {
            if !RequestActivityStatusPolicy.isTransitionLocked(item.status) {
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
                "Manage",
                systemImage: "slider.horizontal.3"
            ) {
                onManage(item)
            }
            .disabled(isActing)
            if let primary = RequestActivityStatusPolicy.primaryAction(
                for: item.status,
                hasEntity: item.entityID != nil
            ) {
                PrismediaButton(
                    primary.title,
                    systemImage: primary.systemImage
                ) {
                    onPrimaryAction(item)
                }
                .disabled(isActing)
                .accessibilityIdentifier("request-activity.download.primary")
            }
            if item.entityID != nil,
                RequestActivityStatusPolicy.primaryAction(for: item.status, hasEntity: true) != .view
            {
                PrismediaButton(
                    "Open in Library",
                    systemImage: "arrow.up.right.square"
                ) {
                    onOpenEntity(item)
                }
                .disabled(isActing)
            }
            PrismediaButton(
                "Remove",
                systemImage: "trash",
                variant: .destructive
            ) {
                onRemove(item)
            }
            .disabled(isActing)
        }

        private var subtitle: String? {
            let creator =
                item.kind == .video || item.kind == .videoSeason || item.kind == .videoSeries
                ? item.series ?? item.author
                : item.author ?? item.series
            guard let year = item.year else { return creator }
            return creator.map { "\($0) (\(year))" } ?? "(\(year))"
        }

        private var telemetryParts: [String] {
            var parts: [String] = []
            if let speed = item.downloadSpeedBytesPerSecond, speed > 0 {
                parts.append(RequestActivityFormatting.speed(speed))
            }
            if let total = item.totalSizeBytes, total > 0 {
                if let progress = item.progress {
                    parts.append(
                        "\(RequestActivityFormatting.bytes(Int64(Double(total) * progress))) / \(RequestActivityFormatting.bytes(total))"
                    )
                } else {
                    parts.append(RequestActivityFormatting.bytes(total))
                }
            }
            if let eta = item.etaSeconds, eta > 0 {
                parts.append("ETA \(RequestActivityFormatting.eta(eta))")
            }
            if !RequestActivityStatusPolicy.showsDeterminateProgress(item.status), let state = item.transferState {
                parts.append(state)
            }
            return parts
        }
    }

    #if DEBUG
        #Preview("Request Activity Download") {
            RequestActivityDownloadRow(
                item: RequestActivityPreviewFixtures.download,
                isActing: false,
                imageURL: nil,
                onPrimaryAction: { _ in },
                onManage: { _ in },
                onOpenEntity: { _ in },
                onRemove: { _ in }
            )
            .padding()
        }
    #endif
#endif
