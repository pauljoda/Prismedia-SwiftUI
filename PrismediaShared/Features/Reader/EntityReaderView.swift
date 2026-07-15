import SwiftUI

public struct EntityReaderView: View {
    let selected: EntityDetail
    let command: BookReaderCommand
    let service: any BookReaderServicing
    let bookmarkStore: any EPUBBookmarkStoring
    let locatorStore: EPUBLocatorStore
    let initialEPUBLocation: String?
    let initialEPUBProgression: Double?
    let companionPlayer: MusicPlayerController?
    let onEPUBReady: () -> Void

    public init(
        selected: EntityDetail,
        command: BookReaderCommand,
        service: any BookReaderServicing,
        bookmarkStore: any EPUBBookmarkStoring = EPUBBookmarkStore.disabled,
        locatorStore: EPUBLocatorStore = .disabled,
        initialEPUBLocation: String? = nil,
        initialEPUBProgression: Double? = nil,
        companionPlayer: MusicPlayerController? = nil,
        onEPUBReady: @escaping () -> Void = {}
    ) {
        self.selected = selected
        self.command = command
        self.service = service
        self.bookmarkStore = bookmarkStore
        self.locatorStore = locatorStore
        self.initialEPUBLocation = initialEPUBLocation
        self.initialEPUBProgression = initialEPUBProgression
        self.companionPlayer = companionPlayer
        self.onEPUBReady = onEPUBReady
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
                    locatorStore: locatorStore,
                    initialLocation: initialEPUBLocation,
                    initialProgression: initialEPUBProgression,
                    companionPlayer: companionPlayer,
                    onReady: onEPUBReady
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
