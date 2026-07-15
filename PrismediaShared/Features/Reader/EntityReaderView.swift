import SwiftUI

public struct EntityReaderView: View {
    let selected: EntityDetail
    let command: BookReaderCommand
    let service: any BookReaderServicing
    let bookmarkStore: any EPUBBookmarkStoring
    let initialEPUBLocation: String?
    let companionPlayer: MusicPlayerController?

    public init(
        selected: EntityDetail,
        command: BookReaderCommand,
        service: any BookReaderServicing,
        bookmarkStore: any EPUBBookmarkStoring = EPUBBookmarkStore.disabled,
        initialEPUBLocation: String? = nil,
        companionPlayer: MusicPlayerController? = nil
    ) {
        self.selected = selected
        self.command = command
        self.service = service
        self.bookmarkStore = bookmarkStore
        self.initialEPUBLocation = initialEPUBLocation
        self.companionPlayer = companionPlayer
    }

    @ViewBuilder
    public var body: some View {
        #if os(tvOS)
            UnsupportedBookReaderView(message: "Books can be read in Prismedia on iPhone, iPad, or Mac.")
        #else
            switch BookReaderFormatPolicy.route(
                for: selected.kind,
                format: selected.bookFormat
            ) {
            case .unavailable:
                UnsupportedBookReaderView(message: "This book does not expose a readable source format.")
            case .comic:
                ComicReaderView(selected: selected, command: command, service: service)
            case .pdf:
                PDFReaderView(book: selected, command: command, service: service)
            case .epub:
                EPUBReaderView(
                    book: selected,
                    command: command,
                    service: service,
                    bookmarkStore: bookmarkStore,
                    initialLocation: initialEPUBLocation,
                    companionPlayer: companionPlayer
                )
            case .unsupported(let format):
                UnsupportedBookReaderView(
                    message: "The native reader does not support the \(format.rawValue) book format."
                )
            }
        #endif
    }
}

#if DEBUG
    #Preview("Entity Reader · Comic") {
        EntityReaderView(
            selected: ComicReaderPreviewData.book,
            command: .read,
            service: ComicReaderPreviewData.service
        )
    }
#endif
