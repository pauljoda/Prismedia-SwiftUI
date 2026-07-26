import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestKindSelector: View {
        @Binding var selection: RequestKindDefinition?
        let isDisabled: Bool

        var body: some View {
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
        }

        private func kindAccent(for kind: RequestKindDefinition) -> Color {
            PrismediaColor.entityAccent(for: kind == .audiobook ? .audio : kind.entityKind)
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
