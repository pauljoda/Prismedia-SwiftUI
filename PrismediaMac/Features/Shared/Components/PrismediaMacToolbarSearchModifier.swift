#if os(macOS)
    import SwiftUI

    struct PrismediaMacToolbarSearchModifier: ViewModifier {
        let isEnabled: Bool
        @Binding var text: String
        let prompt: LocalizedStringKey
        let onSubmit: () -> Void

        func body(content: Content) -> some View {
            if isEnabled {
                content.toolbar {
                    ToolbarItem(
                        id: "prismedia.search",
                        placement: .automatic
                    ) {
                        TextField(prompt, text: $text)
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 180, idealWidth: 240, maxWidth: 320)
                            .onSubmit(onSubmit)
                            .accessibilityIdentifier("prismedia.toolbar-search")
                    }
                }
            } else {
                content
            }
        }
    }

    extension View {
        func prismediaMacToolbarSearch(
            isEnabled: Bool = true,
            text: Binding<String>,
            prompt: LocalizedStringKey,
            onSubmit: @escaping () -> Void
        ) -> some View {
            modifier(
                PrismediaMacToolbarSearchModifier(
                    isEnabled: isEnabled,
                    text: text,
                    prompt: prompt,
                    onSubmit: onSubmit
                )
            )
        }
    }

    #if DEBUG
        #Preview("Mac Toolbar Search") {
            @Previewable @State var query = ""

            PreviewShell(signedIn: true) {
                NavigationStack {
                    Text("Search results")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .modifier(
                            PrismediaMacToolbarSearchModifier(
                                isEnabled: true,
                                text: $query,
                                prompt: "Search your library",
                                onSubmit: {}
                            )
                        )
                }
            }
            .frame(width: 720, height: 420)
        }
    #endif
#endif
