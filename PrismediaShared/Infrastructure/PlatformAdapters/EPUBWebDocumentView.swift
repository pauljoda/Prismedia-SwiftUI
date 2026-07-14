#if os(iOS) || os(macOS)
    import SwiftUI
    import WebKit
    #if os(iOS)
        import UIKit
    #else
        import AppKit
    #endif

    @MainActor
    struct EPUBWebDocumentView {
        let chapter: EPUBChapter
        let rootURL: URL
        let initialScrollProgress: Double
        let onLocalNavigation: @MainActor (URL) -> Void
        let onScrollProgress: @MainActor (Double) -> Void
        #if DEBUG
            private let previewHTML: String?
        #endif

        init(
            chapter: EPUBChapter,
            rootURL: URL,
            initialScrollProgress: Double,
            onLocalNavigation: @escaping @MainActor (URL) -> Void,
            onScrollProgress: @escaping @MainActor (Double) -> Void
        ) {
            self.chapter = chapter
            self.rootURL = rootURL
            self.initialScrollProgress = initialScrollProgress
            self.onLocalNavigation = onLocalNavigation
            self.onScrollProgress = onScrollProgress
            #if DEBUG
                previewHTML = nil
            #endif
        }

        #if DEBUG
            init(previewHTML: String) {
                let rootURL = URL(fileURLWithPath: "/preview-epub", isDirectory: true)
                chapter = EPUBChapter(
                    id: "preview-chapter",
                    location: "chapter.xhtml",
                    fileURL: rootURL.appending(path: "chapter.xhtml")
                )
                self.rootURL = rootURL
                initialScrollProgress = 0
                onLocalNavigation = { _ in }
                onScrollProgress = { _ in }
                self.previewHTML = previewHTML
            }
        #endif
    }

    #if os(iOS)
        extension EPUBWebDocumentView: UIViewRepresentable {
            func makeUIView(context: Context) -> WKWebView {
                makeView(context: context)
            }

            func updateUIView(_ view: WKWebView, context: Context) {
                update(view, coordinator: context.coordinator)
            }
        }
    #else
        extension EPUBWebDocumentView: NSViewRepresentable {
            func makeNSView(context: Context) -> WKWebView {
                makeView(context: context)
            }

            func updateNSView(_ view: WKWebView, context: Context) {
                update(view, coordinator: context.coordinator)
            }
        }
    #endif

    extension EPUBWebDocumentView {
        func makeCoordinator() -> Coordinator {
            Coordinator(
                rootURL: rootURL,
                initialScrollProgress: initialScrollProgress,
                onLocalNavigation: onLocalNavigation,
                onScrollProgress: onScrollProgress
            )
        }

        func makeView(context: Context) -> WKWebView {
            let configuration = WKWebViewConfiguration()
            configuration.websiteDataStore = .nonPersistent()
            configuration.defaultWebpagePreferences.allowsContentJavaScript = false
            let view = WKWebView(frame: .zero, configuration: configuration)
            view.navigationDelegate = context.coordinator
            context.coordinator.attach(to: view)
            #if DEBUG
                if let previewHTML {
                    view.loadHTMLString(previewHTML, baseURL: nil)
                    return view
                }
            #endif
            load(chapter.fileURL, in: view)
            return view
        }

        func update(_ view: WKWebView, coordinator: Coordinator) {
            coordinator.rootURL = rootURL
            coordinator.onLocalNavigation = onLocalNavigation
            coordinator.onScrollProgress = onScrollProgress
            #if DEBUG
                if previewHTML != nil { return }
            #endif
            guard view.url?.standardizedFileURL != chapter.fileURL.standardizedFileURL else { return }
            coordinator.initialScrollProgress = initialScrollProgress
            load(chapter.fileURL, in: view)
        }

        private func load(_ url: URL, in view: WKWebView) {
            view.loadFileURL(url, allowingReadAccessTo: rootURL)
        }

        @MainActor
        final class Coordinator: NSObject, WKNavigationDelegate {
            var rootURL: URL
            var initialScrollProgress: Double
            var onLocalNavigation: @MainActor (URL) -> Void
            var onScrollProgress: @MainActor (Double) -> Void

            #if os(macOS)
                private var scrollObserver: NSObjectProtocol?
                private weak var observedScrollView: NSScrollView?
            #endif

            init(
                rootURL: URL,
                initialScrollProgress: Double,
                onLocalNavigation: @escaping @MainActor (URL) -> Void,
                onScrollProgress: @escaping @MainActor (Double) -> Void
            ) {
                self.rootURL = rootURL
                self.initialScrollProgress = initialScrollProgress
                self.onLocalNavigation = onLocalNavigation
                self.onScrollProgress = onScrollProgress
            }

            func attach(to webView: WKWebView) {
                #if os(iOS)
                    webView.scrollView.delegate = self
                #else
                    guard let scrollView = macScrollView(in: webView) else { return }
                    if observedScrollView === scrollView { return }
                    if let scrollObserver { NotificationCenter.default.removeObserver(scrollObserver) }
                    observedScrollView = scrollView
                    let clipView = scrollView.contentView
                    clipView.postsBoundsChangedNotifications = true
                    scrollObserver = NotificationCenter.default.addObserver(
                        forName: NSView.boundsDidChangeNotification,
                        object: clipView,
                        queue: .main
                    ) { [weak self, weak webView] _ in
                        MainActor.assumeIsolated {
                            guard let self, let webView else { return }
                            self.reportMacScroll(in: webView)
                        }
                    }
                #endif
            }

            func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
                attach(to: webView)
                restoreScrollProgress(in: webView)
            }

            func webView(
                _ webView: WKWebView,
                decidePolicyFor navigationAction: WKNavigationAction,
                decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
            ) {
                guard let url = navigationAction.request.url else {
                    decisionHandler(.cancel)
                    return
                }
                if url.scheme == "about" {
                    decisionHandler(.allow)
                    return
                }
                guard url.isFileURL, isInsideRoot(url) else {
                    decisionHandler(.cancel)
                    return
                }
                if navigationAction.navigationType == .linkActivated,
                    documentURL(url) != webView.url.map(documentURL)
                {
                    onLocalNavigation(documentURL(url))
                    decisionHandler(.cancel)
                    return
                }
                decisionHandler(.allow)
            }

            private func isInsideRoot(_ url: URL) -> Bool {
                let rootPath = rootURL.standardizedFileURL.path(percentEncoded: false)
                let candidate = url.standardizedFileURL.path(percentEncoded: false)
                return candidate == rootPath || candidate.hasPrefix(rootPath + "/")
            }

            private func documentURL(_ url: URL) -> URL {
                guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                    return url.standardizedFileURL
                }
                components.fragment = nil
                components.query = nil
                return components.url?.standardizedFileURL ?? url.standardizedFileURL
            }

            private func restoreScrollProgress(in webView: WKWebView) {
                let progress = min(max(initialScrollProgress, 0), 1)
                #if os(iOS)
                    let scrollView = webView.scrollView
                    let maximumOffset = max(0, scrollView.contentSize.height - scrollView.bounds.height)
                    scrollView.setContentOffset(
                        CGPoint(x: scrollView.contentOffset.x, y: maximumOffset * progress),
                        animated: false
                    )
                #else
                    guard let scrollView = macScrollView(in: webView) else { return }
                    let documentHeight = scrollView.documentView?.bounds.height ?? 0
                    let maximumOffset = max(0, documentHeight - scrollView.contentView.bounds.height)
                    scrollView.contentView.scroll(
                        to: CGPoint(x: scrollView.contentView.bounds.origin.x, y: maximumOffset * progress)
                    )
                    scrollView.reflectScrolledClipView(scrollView.contentView)
                #endif
            }

            private func report(progress: Double) {
                onScrollProgress(min(max(progress, 0), 1))
            }

            #if os(macOS)
                private func reportMacScroll(in webView: WKWebView) {
                    guard let scrollView = macScrollView(in: webView) else { return }
                    let documentHeight = scrollView.documentView?.bounds.height ?? 0
                    let maximumOffset = max(0, documentHeight - scrollView.contentView.bounds.height)
                    report(
                        progress: maximumOffset > 0
                            ? scrollView.contentView.bounds.origin.y / maximumOffset
                            : 0
                    )
                }

                private func macScrollView(in view: NSView) -> NSScrollView? {
                    if let scrollView = view as? NSScrollView { return scrollView }
                    for subview in view.subviews {
                        if let scrollView = macScrollView(in: subview) { return scrollView }
                    }
                    return nil
                }
            #endif
        }
    }

    #if os(iOS)
        extension EPUBWebDocumentView.Coordinator: UIScrollViewDelegate {
            func scrollViewDidScroll(_ scrollView: UIScrollView) {
                let maximumOffset = max(0, scrollView.contentSize.height - scrollView.bounds.height)
                report(progress: maximumOffset > 0 ? scrollView.contentOffset.y / maximumOffset : 0)
            }
        }
    #endif

    #if DEBUG
        #Preview("EPUB Web Document") {
            EPUBWebDocumentView(
                previewHTML: """
                    <!doctype html>
                    <html>
                      <body style="font: -apple-system-body; padding: 2rem; line-height: 1.5;">
                        <h1>Preview Chapter</h1>
                        <p>A deterministic in-memory chapter for tuning the EPUB reading surface.</p>
                      </body>
                    </html>
                    """
            )
        }
    #endif
#endif
