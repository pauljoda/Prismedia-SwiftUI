import SwiftUI

struct EntityGridSearchModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var text: String
    let onSubmit: () -> Void

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .searchable(text: $text, prompt: "Search your library")
                .onSubmit(of: .search, onSubmit)
        } else {
            content
        }
    }
}
#Preview("Entity Grid Search") {
    @Previewable @State var text = ""
    NavigationStack {
        Text("Library")
            .modifier(EntityGridSearchModifier(isEnabled: true, text: $text, onSubmit: {}))
    }
}
