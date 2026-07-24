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
                        Label(kind.label, systemImage: kind.systemImage)
                            .tag(Optional(kind))
                    }
                } label: {
                    Label("Entity Type", systemImage: selection?.systemImage ?? "square.grid.2x2")
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
