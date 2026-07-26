import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestWorkspaceSectionBar: View {
        @Binding var selection: RequestWorkspaceSection

        var body: some View {
            ScrollView(.horizontal) {
                HStack(spacing: PrismediaSpacing.extraLarge) {
                    ForEach(RequestWorkspaceSection.allCases) { candidate in
                        Button {
                            selection = candidate
                        } label: {
                            VStack(spacing: PrismediaSpacing.small) {
                                Label(candidate.title, systemImage: candidate.systemImage)
                                    .font(
                                        .callout.weight(
                                            selection == candidate ? .semibold : .regular
                                        )
                                    )
                                    .foregroundStyle(
                                        selection == candidate
                                            ? PrismediaColor.textPrimary
                                            : PrismediaColor.textSecondary
                                    )

                                Rectangle()
                                    .fill(
                                        selection == candidate
                                            ? PrismediaColor.materialSpectrumViolet
                                            : .clear
                                    )
                                    .frame(height: 2)
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selection == candidate ? .isSelected : [])
                    }
                }
                .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
            }
            .scrollIndicators(.hidden)
            .accessibilityIdentifier("request.section")
        }
    }

    #if DEBUG
        #Preview("Request Section Bar") {
            @Previewable @State var selection = RequestWorkspaceSection.discover

            RequestWorkspaceSectionBar(selection: $selection)
                .background(PrismediaColor.background)
        }
    #endif
#endif
