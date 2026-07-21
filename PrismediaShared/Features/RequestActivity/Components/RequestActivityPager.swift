import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityPager: View {
        let page: Int
        let totalPages: Int
        let isLoading: Bool
        let onPrevious: () -> Void
        let onNext: () -> Void

        var body: some View {
            HStack {
                PrismediaButton(
                    "Previous",
                    systemImage: "chevron.left",
                    form: .compactIcon,
                    action: onPrevious
                )
                .disabled(page <= 1 || isLoading)
                Spacer()
                Text("Page \(page) of \(totalPages)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(PrismediaColor.textSecondary)
                Spacer()
                PrismediaButton(
                    "Next",
                    systemImage: "chevron.right",
                    form: .compactIcon,
                    action: onNext
                )
                .disabled(page >= totalPages || isLoading)
            }
            .prismediaCompactActionControlSize()
            .accessibilityElement(children: .contain)
        }
    }

    #if DEBUG
        #Preview("Request Activity Pager") {
            RequestActivityPager(
                page: 2,
                totalPages: 5,
                isLoading: false,
                onPrevious: {},
                onNext: {}
            )
            .padding()
        }
    #endif
#endif
