import SwiftUI

/// Library search. On regular width the field sits at the top of the content, so
/// the bottom stays clear for the floating mini player; compact width keeps the
/// system's placement.
struct EntityGridSearchModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var text: String
    var prompt: LocalizedStringKey = "Search your library"
    let onSubmit: () -> Void

    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    func body(content: Content) -> some View {
        if isEnabled {
            #if os(macOS)
                content.prismediaMacInlineSearch(
                    text: $text,
                    prompt: prompt,
                    onSubmit: onSubmit
                )
            #else
                content
                    .suppressesMusicMiniPlayerWhileSearching()
                    .searchable(text: $text, placement: placement, prompt: Text(prompt))
                    .onSubmit(of: .search, onSubmit)
            #endif
        } else {
            content
        }
    }

    #if !os(macOS)
        private var placement: SearchFieldPlacement {
            #if os(iOS)
                horizontalSizeClass == .regular ? .navigationBarDrawer(displayMode: .always) : .automatic
            #else
                .automatic
            #endif
        }
    #endif
}
#Preview("Entity Grid Search") {
    @Previewable @State var text = ""
    NavigationStack {
        Text("Library")
            .modifier(EntityGridSearchModifier(isEnabled: true, text: $text, onSubmit: {}))
    }
}
