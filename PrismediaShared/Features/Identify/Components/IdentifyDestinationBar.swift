import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyDestinationBar: View {
        @Bindable var session: IdentifySession
        let onOpenKind: (EntityKind) -> Void

        var body: some View {
            ScrollView(.horizontal) {
                HStack(spacing: PrismediaSpacing.extraLarge) {
                    destinationButton(
                        title: "Dashboard",
                        systemImage: "rectangle.grid.2x2",
                        pendingCount: session.queue.count,
                        isSelected: session.selectedKind == nil
                    ) {
                        session.selectedKind = nil
                    }

                    ForEach(session.kindSummaries) { summary in
                        destinationButton(
                            title: summary.kind.displayLabel,
                            systemImage: summary.kind.thumbnailFallbackSystemImage,
                            pendingCount: summary.pendingCount,
                            isSelected: session.selectedKind == summary.kind
                        ) {
                            onOpenKind(summary.kind)
                        }
                    }
                }
                .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
            }
            .scrollIndicators(.hidden)
            .accessibilityIdentifier("identify.destination-bar")
        }

        private func destinationButton(
            title: String,
            systemImage: String,
            pendingCount: Int,
            isSelected: Bool,
            action: @escaping () -> Void
        ) -> some View {
            Button(action: action) {
                VStack(spacing: PrismediaSpacing.small) {
                    HStack(spacing: PrismediaSpacing.extraSmall) {
                        Label(title, systemImage: systemImage)
                        if pendingCount > 0 {
                            Text(pendingCount, format: .number)
                                .font(.caption2.monospacedDigit().weight(.semibold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(PrismediaColor.controlFill, in: .capsule)
                        }
                    }
                    .font(.callout.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(
                        isSelected
                            ? PrismediaColor.textPrimary
                            : PrismediaColor.textSecondary
                    )

                    Rectangle()
                        .fill(
                            isSelected
                                ? PrismediaColor.materialSpectrumViolet
                                : .clear
                        )
                        .frame(height: 2)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }

    }

    #if DEBUG
        #Preview("Identify Destination Bar") {
            IdentifyDestinationBar(
                session: .init(
                    service: AdministrativePreviewService(),
                    browser: IdentifyPreviewEntityBrowser(),
                    initialQueue: [IdentifyPreviewFixtures.reviewItem],
                    initialProviders: [IdentifyPreviewFixtures.provider]
                ),
                onOpenKind: { _ in }
            )
            .background(PrismediaColor.background)
        }
    #endif
#endif
