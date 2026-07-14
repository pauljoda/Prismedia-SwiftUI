#if os(iOS) || os(macOS)
    import PDFKit
    import SwiftUI
    #if os(iOS)
        import UIKit
    #endif

    @MainActor
    struct PDFKitDocumentView {
        let document: PDFDocument
        let pageIndex: Int
        let layoutMode: PDFReaderLayoutMode
        let fitMode: PDFReaderFitMode
        let fitRequestID: Int
        let highlightedSelection: PDFSelection?
        let isSwipeDownEnabled: Bool
        let onPageChanged: @MainActor (Int) -> Void
        let onSwipeDown: @MainActor () -> Void
    }

    #if os(iOS)
        extension PDFKitDocumentView: UIViewRepresentable {
            func makeUIView(context: Context) -> PDFView {
                makeView(context: context)
            }

            func updateUIView(_ view: PDFView, context: Context) {
                update(view, coordinator: context.coordinator)
            }
        }
    #else
        extension PDFKitDocumentView: NSViewRepresentable {
            func makeNSView(context: Context) -> PDFView {
                makeView(context: context)
            }

            func updateNSView(_ view: PDFView, context: Context) {
                update(view, coordinator: context.coordinator)
            }
        }
    #endif

    extension PDFKitDocumentView {
        func makeCoordinator() -> Coordinator {
            Coordinator(
                isSwipeDownEnabled: isSwipeDownEnabled,
                onPageChanged: onPageChanged,
                onSwipeDown: onSwipeDown
            )
        }

        func makeView(context: Context) -> PDFView {
            let view = PDFView()
            view.displaysPageBreaks = true
            configureLayout(in: view)
            view.document = document
            context.coordinator.observe(view)
            context.coordinator.installDismissGesture(on: view)
            go(to: pageIndex, in: view)
            applyFitMode(in: view)
            return view
        }

        func update(_ view: PDFView, coordinator: Coordinator) {
            coordinator.onPageChanged = onPageChanged
            coordinator.onSwipeDown = onSwipeDown
            coordinator.isSwipeDownEnabled = isSwipeDownEnabled
            let documentChanged = view.document !== document
            if documentChanged { view.document = document }

            let layoutChanged = coordinator.layoutMode != layoutMode
            if layoutChanged || documentChanged {
                configureLayout(in: view)
                coordinator.layoutMode = layoutMode
            }

            let visiblePage = view.currentPage.map(document.index(for:))
            let pageChanged = visiblePage != pageIndex
            if pageChanged { go(to: pageIndex, in: view) }

            if coordinator.fitRequestID != fitRequestID || layoutChanged || pageChanged || documentChanged {
                applyFitMode(in: view)
                coordinator.fitRequestID = fitRequestID
            }

            if coordinator.highlightedSelection !== highlightedSelection {
                applySelection(in: view)
                coordinator.highlightedSelection = highlightedSelection
            }
        }

        private func go(to index: Int, in view: PDFView) {
            guard let page = document.page(at: max(0, min(index, document.pageCount - 1))) else { return }
            view.go(to: page)
        }

        private func configureLayout(in view: PDFView) {
            switch layoutMode {
            case .paged:
                view.displayMode = .singlePage
                view.displayDirection = .horizontal
                #if os(iOS)
                    view.usePageViewController(true, withViewOptions: nil)
                #endif
            case .continuous:
                #if os(iOS)
                    view.usePageViewController(false, withViewOptions: nil)
                #endif
                view.displayMode = .singlePageContinuous
                view.displayDirection = .vertical
            }
        }

        private func applyFitMode(in view: PDFView) {
            switch fitMode {
            case .page:
                view.autoScales = true
                view.scaleFactor = view.scaleFactorForSizeToFit
            case .width:
                view.autoScales = false
                guard let page = view.currentPage, view.bounds.width > 0 else { return }
                let pageWidth = page.bounds(for: .cropBox).width
                guard pageWidth > 0 else { return }
                let widthScale = view.bounds.width / pageWidth
                view.scaleFactor = min(max(widthScale, view.minScaleFactor), view.maxScaleFactor)
            }
        }

        private func applySelection(in view: PDFView) {
            guard let highlightedSelection else {
                view.highlightedSelections = nil
                view.setCurrentSelection(nil, animate: false)
                return
            }
            view.highlightedSelections = [highlightedSelection]
            view.setCurrentSelection(highlightedSelection, animate: false)
            view.go(to: highlightedSelection)
        }

        @MainActor
        final class Coordinator: NSObject {
            var isSwipeDownEnabled: Bool
            var onPageChanged: @MainActor (Int) -> Void
            var onSwipeDown: @MainActor () -> Void
            var layoutMode: PDFReaderLayoutMode?
            var fitRequestID: Int?
            var highlightedSelection: PDFSelection?
            private weak var view: PDFView?
            private var observer: NSObjectProtocol?

            init(
                isSwipeDownEnabled: Bool,
                onPageChanged: @escaping @MainActor (Int) -> Void,
                onSwipeDown: @escaping @MainActor () -> Void
            ) {
                self.isSwipeDownEnabled = isSwipeDownEnabled
                self.onPageChanged = onPageChanged
                self.onSwipeDown = onSwipeDown
                super.init()
            }

            isolated deinit {
                if let observer { NotificationCenter.default.removeObserver(observer) }
            }

            func observe(_ view: PDFView) {
                self.view = view
                observer = NotificationCenter.default.addObserver(
                    forName: Notification.Name.PDFViewPageChanged,
                    object: view,
                    queue: .main
                ) { [weak self] _ in
                    MainActor.assumeIsolated {
                        guard let self,
                            let view = self.view,
                            let document = view.document,
                            let page = view.currentPage
                        else { return }
                        self.onPageChanged(document.index(for: page))
                    }
                }
            }

            func installDismissGesture(on view: PDFView) {
                #if os(iOS)
                    let gesture = UIPanGestureRecognizer(
                        target: self,
                        action: #selector(handleDismissGesture(_:))
                    )
                    gesture.cancelsTouchesInView = false
                    gesture.maximumNumberOfTouches = 1
                    gesture.delegate = self
                    view.addGestureRecognizer(gesture)
                #endif
            }

            #if os(iOS)
                @objc private func handleDismissGesture(_ gesture: UIPanGestureRecognizer) {
                    guard gesture.state == .ended,
                        isSwipeDownEnabled,
                        let view,
                        view.scaleFactor <= view.scaleFactorForSizeToFit * 1.05
                    else { return }
                    let translation = gesture.translation(in: gesture.view)
                    guard
                        ReaderDismissGesture.shouldDismiss(
                            deltaX: translation.x,
                            deltaY: translation.y
                        )
                    else { return }
                    onSwipeDown()
                }
            #endif
        }
    }

    #if os(iOS)
        extension PDFKitDocumentView.Coordinator: UIGestureRecognizerDelegate {
            func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
                guard isSwipeDownEnabled,
                    let view,
                    let gesture = gestureRecognizer as? UIPanGestureRecognizer
                else { return false }

                let velocity = gesture.velocity(in: view)
                guard
                    ReaderDismissGesture.shouldDismiss(
                        deltaX: velocity.x,
                        deltaY: velocity.y
                    )
                else { return false }

                return view.scaleFactor <= view.scaleFactorForSizeToFit * 1.05
            }

            func gestureRecognizer(
                _ gestureRecognizer: UIGestureRecognizer,
                shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
            ) -> Bool {
                true
            }
        }
    #endif

    #if DEBUG
        #Preview("PDFKit Document View") {
            PDFKitDocumentView(
                document: PDFDocument(),
                pageIndex: 0,
                layoutMode: .continuous,
                fitMode: .page,
                fitRequestID: 0,
                highlightedSelection: nil,
                isSwipeDownEnabled: false,
                onPageChanged: { _ in },
                onSwipeDown: {}
            )
        }
    #endif
#endif
