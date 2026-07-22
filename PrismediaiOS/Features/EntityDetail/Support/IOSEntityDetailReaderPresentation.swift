#if os(iOS)
import SwiftUI

extension View {
    @ViewBuilder
    func prismediaReaderCover<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        fullScreenCover(item: item, content: content)
    }
}

#Preview("iOS Reader Presentation Host") {
    Text("Reader presentation host")
}
#endif
