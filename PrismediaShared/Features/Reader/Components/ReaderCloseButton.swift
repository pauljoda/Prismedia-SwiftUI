import SwiftUI

struct ReaderCloseButton: View {
    let accessibilityPrefix: String
    let action: () -> Void

    var body: some View {
        Button("Close reader", systemImage: "xmark", action: action)
            .accessibilityIdentifier("\(accessibilityPrefix).close")
    }
}

#if DEBUG
    #Preview("Reader Close Button") {
        ReaderCloseButton(accessibilityPrefix: "preview-reader", action: {})
            .padding()
            .preferredColorScheme(.dark)
    }
#endif
