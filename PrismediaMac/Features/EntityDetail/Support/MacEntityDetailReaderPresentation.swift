#if os(macOS)
import SwiftUI

extension View {
    @ViewBuilder
    func prismediaReaderCover<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        sheet(item: item, content: content)
    }
}

#Preview("Mac Reader Presentation Host") {
    Text("Reader presentation host")
}
#endif
