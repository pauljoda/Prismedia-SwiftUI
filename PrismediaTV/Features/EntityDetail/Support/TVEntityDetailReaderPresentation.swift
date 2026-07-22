#if os(tvOS)
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

#Preview("TV Reader Presentation Host") {
    Text("Reader presentation host")
}
#endif
