import SwiftUI

struct SearchHubContentWidthModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        #else
            content
                .containerRelativeFrame(.horizontal, alignment: .center) { length, _ in
                    min(length, SearchHubLayout.maximumContentWidth)
                }
        #endif
    }
}

extension View {
    func searchHubContentWidth() -> some View {
        modifier(SearchHubContentWidthModifier())
    }
}

#if DEBUG
    #Preview("Search Hub Content Width") {
        ScrollView {
            Text("Search results use the available platform width.")
                .padding()
                .modifier(SearchHubContentWidthModifier())
        }
        .frame(width: 900, height: 480)
        .preferredColorScheme(.dark)
    }
#endif
