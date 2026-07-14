import SwiftUI

struct UnsupportedBookReaderView: View {
    @Environment(\.dismiss) private var dismiss
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label("Reader Unavailable", systemImage: "book.closed")
        } description: {
            Text(message)
        } actions: {
            PrismediaButton("Close", variant: .prominent) { dismiss() }
        }
        .accessibilityIdentifier("book-reader.unsupported")
    }
}

#if DEBUG
    #Preview("Reader · Unsupported") {
        UnsupportedBookReaderView(message: "This protected book cannot be opened in the native reader.")
    }
#endif
