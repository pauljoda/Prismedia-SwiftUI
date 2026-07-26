#if os(macOS)
import AppKit
import SwiftUI

@MainActor
struct MacEPUBDocumentView: NSViewRepresentable {
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

    func makeCoordinator() -> Coordinator {
        Coordinator(
            rootURL: rootURL,
            initialScrollProgress: initialScrollProgress,
            onLocalNavigation: onLocalNavigation,
            onScrollProgress: onScrollProgress
        )
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .white
        scrollView.contentView.postsBoundsChangedNotifications = true

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = true
        textView.backgroundColor = .white
        textView.textContainerInset = NSSize(width: 48, height: 40)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.delegate = context.coordinator
        textView.appearance = NSAppearance(named: .aqua)
        scrollView.documentView = textView

        context.coordinator.attach(scrollView: scrollView, textView: textView)
        context.coordinator.render(chapter: chapter, previewHTML: previewHTMLValue)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.rootURL = rootURL
        context.coordinator.initialScrollProgress = initialScrollProgress
        context.coordinator.onLocalNavigation = onLocalNavigation
        context.coordinator.onScrollProgress = onScrollProgress
        context.coordinator.render(chapter: chapter, previewHTML: previewHTMLValue)
    }

    private var previewHTMLValue: String? {
        #if DEBUG
            previewHTML
        #else
            nil
        #endif
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var rootURL: URL
        var initialScrollProgress: Double
        var onLocalNavigation: @MainActor (URL) -> Void
        var onScrollProgress: @MainActor (Double) -> Void

        private weak var scrollView: NSScrollView?
        private weak var textView: NSTextView?
        private var scrollObserver: NSObjectProtocol?
        private var renderedChapterID: String?
        private var currentChapterDirectory: URL?

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

        isolated deinit {
            if let scrollObserver {
                NotificationCenter.default.removeObserver(scrollObserver)
            }
        }

        func attach(scrollView: NSScrollView, textView: NSTextView) {
            self.scrollView = scrollView
            self.textView = textView
            scrollObserver = NotificationCenter.default.addObserver(
                forName: NSView.boundsDidChangeNotification,
                object: scrollView.contentView,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.reportScrollProgress() }
            }
        }

        func render(chapter: EPUBChapter, previewHTML: String?) {
            guard renderedChapterID != chapter.id, let textView else { return }
            renderedChapterID = chapter.id
            let chapterDirectory = chapter.fileURL.deletingLastPathComponent()
            currentChapterDirectory = chapterDirectory

            do {
                let data: Data
                if let previewHTML {
                    data = Data(previewHTML.utf8)
                } else {
                    data = try Data(contentsOf: chapter.fileURL)
                }
                let content = try NSMutableAttributedString(
                    data: data,
                    options: [
                        .documentType: NSAttributedString.DocumentType.html,
                        .characterEncoding: String.Encoding.utf8.rawValue,
                        .baseURL: chapterDirectory,
                    ],
                    documentAttributes: nil
                )
                textView.textStorage?.setAttributedString(content)
            } catch {
                textView.string = "This chapter could not be displayed.\n\n\(error.localizedDescription)"
            }

            restoreScrollProgress()
        }

        func textView(
            _ textView: NSTextView,
            clickedOnLink link: Any,
            at characterIndex: Int
        ) -> Bool {
            let resolvedURL: URL?
            if let url = link as? URL {
                resolvedURL = url
            } else if let value = link as? String, let currentChapterDirectory {
                resolvedURL = URL(string: value, relativeTo: currentChapterDirectory)?.absoluteURL
            } else {
                resolvedURL = nil
            }

            guard let resolvedURL,
                  resolvedURL.isFileURL,
                  isInsideRoot(resolvedURL)
            else { return false }

            onLocalNavigation(resolvedURL)
            return true
        }

        private func restoreScrollProgress() {
            guard let scrollView, let textView else { return }
            let progress = min(max(initialScrollProgress, 0), 1)
            textView.layoutManager?.ensureLayout(for: textView.textContainer!)

            DispatchQueue.main.async { [weak self, weak scrollView, weak textView] in
                guard let self, let scrollView, let textView else { return }
                let maximumOffset = max(
                    0,
                    textView.bounds.height - scrollView.contentView.bounds.height
                )
                scrollView.contentView.scroll(
                    to: CGPoint(x: 0, y: maximumOffset * progress)
                )
                scrollView.reflectScrolledClipView(scrollView.contentView)
                self.reportScrollProgress()
            }
        }

        private func reportScrollProgress() {
            guard let scrollView, let textView else { return }
            let maximumOffset = max(
                0,
                textView.bounds.height - scrollView.contentView.bounds.height
            )
            let progress = maximumOffset > 0
                ? scrollView.contentView.bounds.origin.y / maximumOffset
                : 0
            onScrollProgress(min(max(progress, 0), 1))
        }

        private func isInsideRoot(_ url: URL) -> Bool {
            let rootPath = rootURL.standardizedFileURL.path(percentEncoded: false)
            let candidate = url.standardizedFileURL.path(percentEncoded: false)
            return candidate == rootPath || candidate.hasPrefix(rootPath + "/")
        }
    }
}

#if DEBUG
    #Preview("Mac EPUB Document") {
        MacEPUBDocumentView(
            previewHTML: """
                <!doctype html>
                <html>
                  <body style="font: -apple-system-body; padding: 2rem; line-height: 1.6;">
                    <h1>Preview Chapter</h1>
                    <p>A deterministic in-memory chapter for the native macOS reading surface.</p>
                  </body>
                </html>
                """
        )
        .frame(width: 820, height: 620)
    }
#endif
#endif
