import SwiftUI

struct FullWidthButtonLabel<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
    }
}

#if DEBUG
    #Preview("Full-width button label") {
        List {
            Button {
            } label: {
                FullWidthButtonLabel {
                    Label("Open chapter", systemImage: "book.pages")
                }
            }
        }
    }
#endif
