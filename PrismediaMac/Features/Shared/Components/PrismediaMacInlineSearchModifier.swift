#if os(macOS)
    import SwiftUI

    struct PrismediaMacInlineSearchModifier: ViewModifier {
        let isEnabled: Bool
        @Binding var text: String
        let prompt: LocalizedStringKey
        let onSubmit: () -> Void

        func body(content: Content) -> some View {
            if isEnabled {
                content.safeAreaInset(edge: .top, spacing: 0) {
                    HStack(spacing: PrismediaSpacing.small) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(PrismediaColor.textMuted)

                        TextField(prompt, text: $text)
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 180, idealWidth: 260, maxWidth: 360)
                            .onSubmit(onSubmit)
                            .accessibilityIdentifier("prismedia.inline-search")

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, PrismediaSpacing.extraLarge)
                    .padding(.vertical, PrismediaSpacing.small)
                    .background(PrismediaColor.groupedContentBackground.opacity(0.94))
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(PrismediaColor.borderSubtle)
                            .frame(height: PrismediaLayout.hairline)
                    }
                }
            } else {
                content
            }
        }
    }

    extension View {
        func prismediaMacInlineSearch(
            isEnabled: Bool = true,
            text: Binding<String>,
            prompt: LocalizedStringKey,
            onSubmit: @escaping () -> Void
        ) -> some View {
            modifier(
                PrismediaMacInlineSearchModifier(
                    isEnabled: isEnabled,
                    text: text,
                    prompt: prompt,
                    onSubmit: onSubmit
                )
            )
        }
    }

    #if DEBUG
        #Preview("Mac Inline Search") {
            @Previewable @State var query = ""

            PreviewShell(signedIn: true) {
                Text("Collection results")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .modifier(
                        PrismediaMacInlineSearchModifier(
                            isEnabled: true,
                            text: $query,
                            prompt: "Search collections",
                            onSubmit: {}
                        )
                    )
            }
            .frame(width: 620, height: 360)
        }
    #endif
#endif
