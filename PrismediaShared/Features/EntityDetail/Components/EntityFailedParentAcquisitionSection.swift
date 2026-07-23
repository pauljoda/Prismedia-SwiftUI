import SwiftUI

#if os(iOS) || os(macOS)
    struct EntityFailedParentAcquisitionSection<Content: View>: View {
        @State private var isExpanded: Bool
        let activeSummary: String
        @ViewBuilder let content: Content

        init(
            activeSummary: String,
            isExpanded: Bool = false,
            @ViewBuilder content: () -> Content
        ) {
            self.activeSummary = activeSummary
            _isExpanded = State(initialValue: isExpanded)
            self.content = content()
        }

        var body: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                content
                    .padding(.top, PrismediaSpacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } label: {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.small) {
                        title
                        Spacer(minLength: PrismediaSpacing.medium)
                        summary
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        title
                        summary
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
            }
            .padding(PrismediaSpacing.medium)
            .background(
                PrismediaColor.controlFill,
                in: PrismediaStableRoundedRectangle(cornerRadius: PrismediaRadius.control)
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("entity-detail.acquisition.failed-parent")
        }

        private var title: some View {
            Label("Parent Release Attempt Failed", systemImage: "exclamationmark.circle")
                .font(.headline)
                .foregroundStyle(PrismediaColor.textSecondary)
        }

        private var summary: some View {
            Text(activeSummary)
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(PrismediaColor.accent)
        }
    }

    #if DEBUG
        #Preview("Failed Parent Acquisition Section") {
            EntityFailedParentAcquisitionSection(
                activeSummary: "2 episodes active instead"
            ) {
                Text("Parent lifecycle controls")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .preferredColorScheme(.dark)
        }
    #endif
#endif
