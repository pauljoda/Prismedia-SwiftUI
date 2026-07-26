#if os(macOS)
    import SwiftUI

    extension View {
        @ViewBuilder
        func prismediaReaderCover<Item: Identifiable, Content: View>(
            item: Binding<Item?>,
            @ViewBuilder content: @escaping (Item) -> Content
        ) -> some View where Item: Hashable {
            navigationDestination(item: item) { item in
                content(item)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .suppressesMusicMiniPlayer()
            }
        }
    }

    #Preview("Mac Reader Presentation Host") {
        Text("Reader presentation host")
    }
#endif
