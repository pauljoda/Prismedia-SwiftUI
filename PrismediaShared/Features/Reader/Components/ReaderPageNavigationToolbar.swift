#if os(iOS) || os(macOS)
    import SwiftUI

    struct ReaderPageNavigationToolbar: ToolbarContent {
        let status: ReaderProgressStatus
        let accessibilityPrefix: String
        let canGoPrevious: Bool
        let canGoNext: Bool
        let onPrevious: () -> Void
        let onNext: () -> Void

        @ToolbarContentBuilder
        var body: some ToolbarContent {
            #if os(iOS)
                ToolbarItemGroup(placement: .bottomBar) {
                    previousButton
                    nextButton
                }

                ToolbarItem(placement: .status) {
                    progressStatus
                }
            #else
                ToolbarItemGroup(placement: .primaryAction) {
                    previousButton
                    progressStatus
                    nextButton
                }
            #endif
        }

        private var previousButton: some View {
            Button("Previous page", systemImage: "chevron.left", action: onPrevious)
                .disabled(!canGoPrevious)
                .accessibilityIdentifier("\(accessibilityPrefix).previous")
        }

        private var nextButton: some View {
            Button("Next page", systemImage: "chevron.right", action: onNext)
                .disabled(!canGoNext)
                .accessibilityIdentifier("\(accessibilityPrefix).next")
        }

        private var progressStatus: some View {
            ReaderProgressStatusView(
                status: status,
                accessibilityIdentifier: "\(accessibilityPrefix).progress"
            )
        }
    }

    #if DEBUG
        #Preview("Reader Page Navigation Toolbar") {
            NavigationStack {
                Color.black
                    .ignoresSafeArea()
                    .toolbar {
                        ReaderPageNavigationToolbar(
                            status: ReaderProgressStatus(
                                title: "The First Signal",
                                counterText: "10 / 51",
                                accessibilityLabel: "The First Signal, page 10 of 51"
                            ),
                            accessibilityPrefix: "preview-reader",
                            canGoPrevious: true,
                            canGoNext: true,
                            onPrevious: {},
                            onNext: {}
                        )
                    }
            }
            .preferredColorScheme(.dark)
        }
    #endif
#endif
