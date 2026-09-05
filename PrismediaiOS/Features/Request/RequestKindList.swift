import SwiftUI

#if os(iOS)
    /// The request entry step exposes media choices directly instead of hiding
    /// the only available action in a menu above an empty state.
    struct RequestKindList: View {
        @Binding var selection: RequestKindDefinition?

        var body: some View {
            List {
                Section {
                    ForEach(RequestKindDefinition.discoverable) { kind in
                        Button {
                            selection = kind
                        } label: {
                            HStack {
                                Label {
                                    Text(kind.pluralLabel)
                                        .foregroundStyle(PrismediaColor.textPrimary)
                                } icon: {
                                    Image(systemName: kind.entityKind.thumbnailFallbackSystemImage)
                                        .foregroundStyle(PrismediaColor.entityAccent(for: kind.entityKind))
                                }
                                Spacer(minLength: PrismediaSpacing.small)
                                Image(systemName: "chevron.forward")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                                    .accessibilityHidden(true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Search for a title to request")
                        .accessibilityIdentifier("request.kind.\(kind.id)")
                    }
                } header: {
                    Text("What would you like to add?")
                }
            }
            .prismediaScreenBackground()
            .accessibilityIdentifier("request.kind-selection")
        }
    }

    #if DEBUG
        #Preview("Request · Choose Media") {
            @Previewable @State var selection: RequestKindDefinition?
            NavigationStack {
                RequestKindList(selection: $selection)
                    .navigationTitle("Request")
            }
            .preferredColorScheme(.dark)
        }
    #endif
#endif
