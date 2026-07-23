import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityInlineErrorSection: View {
        let message: String?
        let sourceIsEmpty: Bool

        @ViewBuilder
        var body: some View {
            if let message, !sourceIsEmpty {
                Section {
                    Label(message, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(PrismediaColor.destructive)
                }
            }
        }
    }

    #if DEBUG
        #Preview("Request Activity Inline Error") {
            List {
                RequestActivityInlineErrorSection(
                    message: "The latest status could not be refreshed.",
                    sourceIsEmpty: false
                )
            }
        }
    #endif
#endif
