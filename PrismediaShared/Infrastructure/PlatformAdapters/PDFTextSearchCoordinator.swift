#if os(iOS) || os(macOS)
    import Foundation
    @preconcurrency import PDFKit

    @MainActor
    final class PDFTextSearchCoordinator: NSObject, @preconcurrency PDFDocumentDelegate {
        private weak var document: PDFDocument?
        private weak var previousDelegate: (any PDFDocumentDelegate)?
        private var continuation: CheckedContinuation<PDFSelectionResults, Never>?
        private var matches: [PDFSelection] = []

        func search(in document: PDFDocument, query: String) async -> PDFSelectionResults {
            await withTaskCancellationHandler {
                await withCheckedContinuation { continuation in
                    self.document = document
                    previousDelegate = document.delegate
                    self.continuation = continuation
                    matches = []
                    document.delegate = self
                    document.beginFindString(
                        query,
                        withOptions: [.caseInsensitive, .diacriticInsensitive]
                    )
                }
            } onCancel: {
                Task { @MainActor [weak self] in
                    self?.cancel()
                }
            }
        }

        func didMatchString(_ instance: PDFSelection) {
            matches.append(instance)
        }

        func documentDidEndDocumentFind(_ notification: Notification) {
            finish()
        }

        private func cancel() {
            document?.cancelFindString()
            finish()
        }

        private func finish() {
            guard let continuation else { return }
            document?.delegate = previousDelegate
            self.continuation = nil
            let matches = matches
            self.matches = []
            continuation.resume(returning: PDFSelectionResults(values: matches))
        }
    }
#endif
