import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestKindSelector: View {
        @Binding var selection: RequestKindDefinition?
        let isDisabled: Bool

        @ViewBuilder
        var body: some View {
            #if os(macOS)
                Section {
                    ScrollView(.horizontal) {
                        HStack(spacing: PrismediaSpacing.small) {
                            ForEach(RequestKindDefinition.allCases) { kind in
                                Button {
                                    selection = kind
                                } label: {
                                    Label {
                                        Text(kind.label)
                                            .foregroundStyle(
                                                selection == kind
                                                    ? PrismediaColor.textPrimary
                                                    : PrismediaColor.textSecondary
                                            )
                                    } icon: {
                                        Image(systemName: kind.systemImage)
                                            .foregroundStyle(kindAccent(for: kind))
                                    }
                                        .font(.callout.weight(.medium))
                                        .padding(.horizontal, PrismediaSpacing.medium)
                                        .frame(minHeight: PrismediaLayout.minimumHitTarget)
                                        .background(
                                            selection == kind
                                                ? PrismediaColor.controlFill
                                                : PrismediaColor.groupedContentBackground,
                                            in: .capsule
                                        )
                                        .overlay {
                                            Capsule()
                                                .stroke(
                                                    selection == kind
                                                        ? kindAccent(for: kind)
                                                        : PrismediaColor.borderSubtle,
                                                    lineWidth: PrismediaLayout.hairline
                                                )
                                        }
                                        .contentShape(.capsule)
                                }
                                .buttonStyle(.plain)
                                .disabled(isDisabled)
                                .accessibilityAddTraits(selection == kind ? .isSelected : [])
                            }
                        }
                        .padding(.vertical, PrismediaSpacing.extraSmall)
                    }
                    .scrollIndicators(.hidden)
                    .accessibilityIdentifier("request.kind")
                } header: {
                    Text("What would you like to add?")
                } footer: {
                    Text("Available sources and search fields update for the selected media type.")
                }
            #else
                Section {
                    Picker(selection: $selection) {
                        Label("Choose Type", systemImage: "square.grid.2x2")
                            .tag(nil as RequestKindDefinition?)

                        ForEach(RequestKindDefinition.allCases) { kind in
                            Label {
                                Text(kind.label)
                            } icon: {
                                Image(systemName: kind.systemImage)
                                    .foregroundStyle(kindAccent(for: kind))
                            }
                                .tag(Optional(kind))
                        }
                    } label: {
                        Text("Entity Type")
                    }
                    .pickerStyle(.menu)
                    .disabled(isDisabled)
                    .accessibilityHint("Updates the available search providers and fields")
                    .accessibilityIdentifier("request.kind")
                } header: {
                    Text("Request Details")
                } footer: {
                    Text("Choose what you want to request. Available providers and search fields update for that type.")
                }
            #endif
        }

        private func kindAccent(for kind: RequestKindDefinition) -> Color {
            switch kind {
            case .book, .author: PrismediaColor.materialSpectrumCyan
            case .audiobook: PrismediaColor.materialSpectrumGreen
            case .movie: PrismediaColor.materialSpectrumOrange
            case .series: PrismediaColor.materialSpectrumYellow
            case .artist: PrismediaColor.materialSpectrumViolet
            case .album: PrismediaColor.materialSpectrumMagenta
            }
        }
    }

    #if DEBUG
        #Preview("Request Kind Selector · Compact") {
            @Previewable @State var selection: RequestKindDefinition? = .movie
            List {
                RequestKindSelector(selection: $selection, isDisabled: false)
            }
            .preferredColorScheme(.dark)
        }

        #Preview("Request Kind Selector · Accessibility") {
            @Previewable @State var selection: RequestKindDefinition? = .book
            List {
                RequestKindSelector(selection: $selection, isDisabled: false)
            }
            .environment(\.dynamicTypeSize, .accessibility3)
            .preferredColorScheme(.dark)
        }
    #endif
#endif
