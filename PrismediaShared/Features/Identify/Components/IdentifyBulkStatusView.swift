import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyBulkStatusView: View {
        let session: IdentifySession

        var body: some View {
            if let progress = session.bulkProgress {
                ProgressView(value: progress.fraction) {
                    Text("Processed \(progress.completed) of \(progress.total)")
                }
                .padding(PrismediaSpacing.large)
                .prismediaPanel()
            } else if let message = session.bulkResultMessage {
                HStack(spacing: PrismediaSpacing.medium) {
                    Text(message)
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Dismiss", systemImage: "xmark", action: session.dismissBulkResult)
                        .labelStyle(.iconOnly)
                }
                .padding(PrismediaSpacing.large)
                .prismediaPanel()
                .accessibilityElement(children: .contain)
            }
        }
    }
#endif
