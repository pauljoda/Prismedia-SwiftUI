import SwiftUI

public struct EntityReaderView: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

    let selected: EntityDetail
    let command: BookReaderCommand
    let service: any BookReaderServicing
    let bookmarkStore: any EPUBBookmarkStoring
    let locatorStore: EPUBLocatorStore
    let initialEPUBLocation: String?
    let initialEPUBProgression: Double?
    let initialEPUBUpdatedAt: Date?
    let epubProgressRanges: [EPUBReadingProgressRange]
    let readingReportFormat: BookReadingReportFormat
    let companionPlayer: MusicPlayerController?
    let findCurrentAudiobookReadingTarget: @MainActor () async -> BookReaderLocationTarget?
    let onEPUBReady: () -> Void

    public init(
        selected: EntityDetail,
        command: BookReaderCommand,
        service: any BookReaderServicing,
        bookmarkStore: any EPUBBookmarkStoring = EPUBBookmarkStore.disabled,
        locatorStore: EPUBLocatorStore = .disabled,
        initialEPUBLocation: String? = nil,
        initialEPUBProgression: Double? = nil,
        initialEPUBUpdatedAt: Date? = nil,
        epubProgressRanges: [EPUBReadingProgressRange] = [],
        readingReportFormat: BookReadingReportFormat = .legacyCursor,
        companionPlayer: MusicPlayerController? = nil,
        findCurrentAudiobookReadingTarget: @escaping @MainActor () async -> BookReaderLocationTarget? = { nil },
        onEPUBReady: @escaping () -> Void = {}
    ) {
        self.selected = selected
        self.command = command
        self.service = service
        self.bookmarkStore = bookmarkStore
        self.locatorStore = locatorStore
        self.initialEPUBLocation = initialEPUBLocation
        self.initialEPUBProgression = initialEPUBProgression
        self.initialEPUBUpdatedAt = initialEPUBUpdatedAt
        self.epubProgressRanges = epubProgressRanges
        self.readingReportFormat = readingReportFormat
        self.companionPlayer = companionPlayer
        self.findCurrentAudiobookReadingTarget = findCurrentAudiobookReadingTarget
        self.onEPUBReady = onEPUBReady
    }

    public var body: some View {
        Group {
            #if os(tvOS)
                UnsupportedBookReaderView(message: "Books can be read in Prismedia on iPhone, iPad, or Mac.")
            #else
                if selected.capability(EntityPageSequenceCapability.self) != nil {
                    ComicReaderView(selected: selected, command: command, service: service)
                } else {
                    switch BookReaderFormatPolicy.route(
                        for: selected.kind,
                        format: selected.bookFormat
                    ) {
                    case .unavailable:
                        UnsupportedBookReaderView(message: "This book does not expose a readable source format.")
                    case .pdf:
                        PDFReaderView(
                            book: selected,
                            command: command,
                            service: service,
                            readingReportFormat: readingReportFormat
                        )
                    case .epub:
                        EPUBReaderView(
                            book: selected,
                            command: command,
                            service: service,
                            bookmarkStore: bookmarkStore,
                            locatorStore: locatorStore,
                            initialLocation: initialEPUBLocation,
                            initialProgression: initialEPUBProgression,
                            initialUpdatedAt: initialEPUBUpdatedAt,
                            progressRanges: epubProgressRanges,
                            readingReportFormat: readingReportFormat,
                            companionPlayer: companionPlayer,
                            findCurrentAudiobookReadingTarget: findCurrentAudiobookReadingTarget,
                            onReady: onEPUBReady
                        )
                    case .unsupported(let format):
                        UnsupportedBookReaderView(
                            message: "The native reader does not support the \(format.rawValue) book format."
                        )
                    }
                }
            #endif
        }
        .tint(artworkPrimaryAccent)
    }
}

#if DEBUG
    #Preview("Entity Reader · Comic") {
        EntityReaderView(
            selected: ComicReaderPreviewData.installment,
            command: .read,
            service: ComicReaderPreviewData.service
        )
    }
#endif
