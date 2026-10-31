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
        /// Two-page spreads, a left and a right page, while the reader is in landscape.
        /// In the paged layout, swipes then step by spread through `onSpreadStep`.
        var showsSpread = false
        /// The gap between a spread's pages: wide enough to clear iPhone Duo's fold
        /// while it is folded like a book, otherwise PDFKit's own page margins.
        var spreadGap: CGFloat = 0
        var onSpreadStep: (@MainActor (Int) -> Void)?
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
            context.coordinator.recordDefaultPageMargins(of: view)
            context.coordinator.showsSpread = showsSpread
            context.coordinator.spreadGap = spreadGap
            configureLayout(in: view, coordinator: context.coordinator)
            view.document = document
            context.coordinator.observe(view)
            context.coordinator.installDismissGesture(on: view)
            context.coordinator.installSpreadSwipes(on: view)
            go(to: pageIndex, in: view)
            applyFitMode(in: view)
            return view
        }

        func update(_ view: PDFView, coordinator: Coordinator) {
            coordinator.onPageChanged = onPageChanged
            coordinator.onSwipeDown = onSwipeDown
            coordinator.isSwipeDownEnabled = isSwipeDownEnabled
            coordinator.onSpreadStep = onSpreadStep
            let documentChanged = view.document !== document
            if documentChanged { view.document = document }

            let layoutChanged =
                coordinator.layoutMode != layoutMode
                || coordinator.showsSpread != showsSpread
                || coordinator.spreadGap != spreadGap
            if layoutChanged || documentChanged {
                coordinator.layoutMode = layoutMode
                coordinator.showsSpread = showsSpread
                coordinator.spreadGap = spreadGap
                configureLayout(in: view, coordinator: coordinator)
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

        private func configureLayout(in view: PDFView, coordinator: Coordinator) {
            view.displaysAsBook = false
            #if os(iOS)
                coordinator.updateSpreadMargins()
            #endif
            if showsSpread {
                #if os(iOS)
                    view.usePageViewController(false, withViewOptions: nil)
                #endif
                switch layoutMode {
                case .paged:
                    view.displayMode = .twoUp
                    view.displayDirection = .horizontal
                case .continuous:
                    view.displayMode = .twoUpContinuous
                    view.displayDirection = .vertical
                }
                return
            }
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
                // A new display mode (a spread after rotating) leaves the size-to-fit
                // scale stale until the document view lays out again, and setting the
                // scale turns auto scaling off, so lay out first and scale last.
                view.layoutDocumentView()
                view.scaleFactor = view.scaleFactorForSizeToFit
                view.autoScales = true
            case .width:
                view.autoScales = false
                guard let page = view.currentPage, view.bounds.width > 0 else { return }
                let pageWidth = page.bounds(for: .cropBox).width
                guard pageWidth > 0 else { return }
                let pagesAcross: CGFloat = showsSpread ? 2 : 1
                let widthScale = (view.bounds.width - (showsSpread ? spreadGap : 0)) / (pageWidth * pagesAcross)
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
            var showsSpread = false
            var spreadGap: CGFloat = 0
            var onSpreadStep: (@MainActor (Int) -> Void)?
            var fitRequestID: Int?
            #if os(iOS)
                private var defaultPageMargins = UIEdgeInsets.zero
            #endif
            var highlightedSelection: PDFSelection?
            private weak var view: PDFView?
            private var observer: NSObjectProtocol?
            private var scaleObserver: NSObjectProtocol?

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
                if let scaleObserver { NotificationCenter.default.removeObserver(scaleObserver) }
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
                scaleObserver = NotificationCenter.default.addObserver(
                    forName: Notification.Name.PDFViewScaleChanged,
                    object: view,
                    queue: .main
                ) { [weak self] _ in
                    MainActor.assumeIsolated { self?.updateSpreadMargins() }
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

            func recordDefaultPageMargins(of view: PDFView) {
                #if os(iOS)
                    defaultPageMargins = view.pageBreakMargins
                #endif
            }

            /// Parts a spread's two pages by ``spreadGap`` on screen. Page margins are
            /// in page points, so they follow the scale: rotating, refitting or zooming
            /// changes the scale, and the margins with it.
            func updateSpreadMargins() {
                #if os(iOS)
                    guard let view else { return }
                    let gap = showsSpread && view.scaleFactor > 0 ? spreadGap / view.scaleFactor : 0
                    var margins = defaultPageMargins
                    margins.left = max(margins.left, gap / 2)
                    margins.right = max(margins.right, gap / 2)
                    guard abs(margins.left - view.pageBreakMargins.left) > 0.5
                        || abs(margins.right - view.pageBreakMargins.right) > 0.5
                    else { return }
                    view.pageBreakMargins = margins
                    view.layoutDocumentView()
                #endif
            }

            /// Two-page spreads skip the page view controller, so horizontal swipes
            /// page by spread themselves in the paged layout; they do nothing otherwise.
            func installSpreadSwipes(on view: PDFView) {
                #if os(iOS)
                    for direction in [UISwipeGestureRecognizer.Direction.left, .right] {
                        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSpreadSwipe(_:)))
                        swipe.direction = direction
                        swipe.cancelsTouchesInView = false
                        view.addGestureRecognizer(swipe)
                    }
                #endif
            }

            #if os(iOS)
                @objc private func handleSpreadSwipe(_ gesture: UISwipeGestureRecognizer) {
                    guard showsSpread, layoutMode == .paged else { return }
                    onSpreadStep?(gesture.direction == .left ? 1 : -1)
                }

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
