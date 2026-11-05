#if os(iOS) || os(macOS)
    import SwiftUI

    struct ReaderPageNavigationToolbar: ToolbarContent {
        let status: ReaderProgressStatus
        let accessibilityPrefix: String
        let canGoPrevious: Bool
        let canGoNext: Bool
        /// Whether pages turn from right to left: the arrows then point the way the pages
        /// go, so the left arrow turns to the next page.
        var readsRightToLeft = false
        let onOpenContents: () -> Void
        let onPrevious: () -> Void
        let onNext: () -> Void

        @ToolbarContentBuilder
        var body: some ToolbarContent {
            #if os(iOS)
                ToolbarItemGroup(placement: .bottomBar) {
                    if readsRightToLeft {
                        nextButton
                        previousButton
                    } else {
                        previousButton
                        nextButton
                    }
                }

                ToolbarItem(placement: .status) {
                    progressStatus
                }
            #else
                ToolbarItemGroup(placement: .primaryAction) {
                    if readsRightToLeft {
                        nextButton
                        progressStatus
                        previousButton
                    } else {
                        previousButton
                        progressStatus
                        nextButton
                    }
                }
            #endif
        }

        private var previousButton: some View {
            Button(
                "Previous page",
                systemImage: readsRightToLeft ? "chevron.right" : "chevron.left",
                action: onPrevious
            )
            .prismediaToolbarActionLabelStyle()
            .disabled(!canGoPrevious)
            .accessibilityIdentifier("\(accessibilityPrefix).previous")
        }

        private var nextButton: some View {
            Button(
                "Next page",
                systemImage: readsRightToLeft ? "chevron.left" : "chevron.right",
                action: onNext
            )
            .prismediaToolbarActionLabelStyle()
            .disabled(!canGoNext)
            .accessibilityIdentifier("\(accessibilityPrefix).next")
        }

        private var progressStatus: some View {
            Button(action: onOpenContents) {
                ReaderProgressStatusView(
                    status: status,
                    accessibilityIdentifier: "\(accessibilityPrefix).progress"
                )
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(status.accessibilityLabel)
            .accessibilityHint("Opens the table of contents")
            .accessibilityIdentifier("\(accessibilityPrefix).progress")
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
                            onOpenContents: {},
                            onPrevious: {},
                            onNext: {}
                        )
                    }
            }
            .preferredColorScheme(.dark)
        }
    #endif
#endif
