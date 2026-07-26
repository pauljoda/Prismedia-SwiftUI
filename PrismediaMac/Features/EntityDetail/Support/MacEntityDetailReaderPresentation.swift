#if os(macOS)
import SwiftUI

extension View {
    @ViewBuilder
    func prismediaReaderCover<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        sheet(item: item) { item in
            content(item)
                .frame(
                    minWidth: 720,
                    idealWidth: 960,
                    minHeight: 560,
                    idealHeight: 720
                )
        }
    }
}

#Preview("Mac Reader Presentation Host") {
    Text("Reader presentation host")
}
#endif
