import SwiftUI

/// Reading progress presentation with no service discovery or owned state.
/// The page supplies the value state and actions at the feature boundary.
struct EntityDetailReadingSection: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
    @Environment(\.artworkSecondaryText) private var artworkSecondaryText
    let state: EntityDetailReadingState
    let horizontalPadding: CGFloat
    let onResume: () -> Void
    let onStartOver: () -> Void
    let onToggleCompletion: (MediaProgressStatus) -> Void
    let onRetry: () -> Void
    let onDismissError: () -> Void

    @ViewBuilder
    var body: some View {
        switch state.phase {
        case .idle:
            EmptyView()
        case .loading:
            loadingContent
        case .failure(let message):
            failureContent(message)
        case .content(let manifest):
            progressContent(
                ReadingProgressPresentation(
                    progress: manifest.progress,
                    chapters: manifest.chapters.map(\.summary)
                )
            )
        case .singleFile(let detail):
            progressContent(
                ReadingProgressPresentation(
                    singleFileProgress: singleFileProgress(in: detail)
                )
            )
        }
    }

    private var loadingContent: some View {
        HStack(spacing: PrismediaSpacing.medium) {
            ProgressView()
                .tint(artworkPrimaryAccent)
            Text("Loading reading progress…")
                .font(.subheadline)
                .foregroundStyle(artworkSecondaryText)
        }
        .padding(PrismediaSpacing.extraLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .prismediaPanel()
        .padding(.horizontal, horizontalPadding)
        .accessibilityIdentifier("entity-detail.reading-progress.loading")
    }

    private func failureContent(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Couldn’t Load Reading Progress", systemImage: "book.closed")
        } description: {
            Text(message)
        } actions: {
            PrismediaButton("Try Again", variant: .prominent, action: onRetry)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .prismediaPanel()
        .padding(.horizontal, horizontalPadding)
        .accessibilityIdentifier("entity-detail.reading-progress.failure")
    }

    @ViewBuilder
    private func progressContent(_ progress: ReadingProgressPresentation?) -> some View {
        if progress != nil || state.errorMessage != nil {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                if let errorMessage = state.errorMessage {
                    errorBanner(errorMessage)
                }

                if let progress {
                    MediaProgressCard(
                        presentation: MediaProgressCardPresentation(
                            readingProgress: progress,
                            isBusy: state.isMutating
                        ),
                        onResume: onResume,
                        onStartOver: onStartOver,
                        onToggleCompletion: { onToggleCompletion(progress.status) }
                    )
                }
            }
            .padding(.horizontal, horizontalPadding)
            .accessibilityIdentifier("entity-detail.reading-progress")
        }
    }

    private func singleFileProgress(in detail: EntityDetail) -> EntityProgressCapability? {
        detail.capability()
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(PrismediaColor.warning)
                .accessibilityHidden(true)

            Text(message)
                .font(.callout)
                .foregroundStyle(artworkSecondaryText)

            Spacer(minLength: 8)

            Button("Dismiss", systemImage: "xmark", action: onDismissError)
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
        }
        .padding(PrismediaSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .prismediaPanel()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("entity-detail.reading-progress.error")
    }

    #if DEBUG
        fileprivate static let previewManifest: BookReaderManifest = {
            let bookID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
            let chapterID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
            let pageID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
            let chapter = EntityDetail(
                id: chapterID,
                kind: .bookChapter,
                title: "The Quiet Frequency",
                parentEntityID: bookID,
                sortOrder: 0,
                hasSourceMedia: false,
                capabilities: [],
                childrenByKind: [],
                relationships: []
            )
            return BookReaderManifest(
                bookID: bookID,
                title: "Signal in the Static",
                chapters: [
                    BookReaderChapter(
                        detail: chapter,
                        pages: [
                            EntityThumbnail(
                                id: pageID,
                                kind: .bookPage,
                                title: "Page 24",
                                parentEntityID: chapterID,
                                sortOrder: 23
                            )
                        ],
                        sequenceIndex: 0
                    )
                ],
                nextChapter: nil,
                progress: EntityProgressCapability(
                    currentEntityID: chapterID,
                    unit: .page,
                    index: 23,
                    total: 96,
                    mode: .paged,
                    completedAt: nil,
                    updatedAt: nil,
                    workIndex: 23,
                    workTotal: 96,
                    location: nil
                ),
                initialIndex: 23,
                readerMode: .paged
            )
        }()

        fileprivate static let previewEPUB = EntityDetail(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            kind: .book,
            title: "The Quiet Frequency",
            parentEntityID: nil,
            sortOrder: nil,
            bookType: "novel",
            bookFormat: .epub,
            hasSourceMedia: true,
            capabilities: [
                .progress(
                    EntityProgressCapability(
                        currentEntityID: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                        unit: .cfi,
                        index: 4_250,
                        total: 10_000,
                        mode: .scrolled,
                        completedAt: nil,
                        updatedAt: nil,
                        workIndex: nil,
                        workTotal: nil,
                        location: "epubcfi(/6/4!/4/2/2:14)"
                    )
                )
            ],
            childrenByKind: [],
            relationships: []
        )

        fileprivate static func previewState(
            _ outcome: EntityDetailReadingLoadOutcome,
            mutationError: String? = nil
        ) -> EntityDetailReadingState {
            var state = EntityDetailReadingState()
            let request = state.beginLoad(entityID: previewManifest.bookID)
            state.finishLoad(outcome, request: request)
            if let mutationError, let mutation = state.beginMutation() {
                state.finishMutation(.failure(mutationError), request: mutation)
            }
            return state
        }

        fileprivate static var previewLoadingState: EntityDetailReadingState {
            var state = EntityDetailReadingState()
            state.beginLoad(entityID: previewManifest.bookID)
            return state
        }
    #endif
}

#if DEBUG
    #Preview("Reading · Content Error · Dark") {
        PreviewShell {
            EntityDetailReadingSection(
                state: EntityDetailReadingSection.previewState(
                    .content(EntityDetailReadingSection.previewManifest),
                    mutationError: "The server is unavailable."
                ),
                horizontalPadding: PrismediaSpacing.extraLarge,
                onResume: {},
                onStartOver: {},
                onToggleCompletion: { _ in },
                onRetry: {},
                onDismissError: {}
            )
            .padding(.vertical)
        }
        .preferredColorScheme(.dark)
    }

    #Preview("Reading · EPUB Progress") {
        PreviewShell {
            EntityDetailReadingSection(
                state: EntityDetailReadingSection.previewState(
                    .singleFile(EntityDetailReadingSection.previewEPUB)
                ),
                horizontalPadding: PrismediaSpacing.extraLarge,
                onResume: {},
                onStartOver: {},
                onToggleCompletion: { _ in },
                onRetry: {},
                onDismissError: {}
            )
            .padding(.vertical)
        }
    }

    #Preview("Reading · Loading") {
        PreviewShell {
            EntityDetailReadingSection(
                state: EntityDetailReadingSection.previewLoadingState,
                horizontalPadding: PrismediaSpacing.extraLarge,
                onResume: {},
                onStartOver: {},
                onToggleCompletion: { _ in },
                onRetry: {},
                onDismissError: {}
            )
            .padding(.vertical)
        }
    }

    #Preview("Reading · Failure · Accessibility") {
        PreviewShell {
            EntityDetailReadingSection(
                state: EntityDetailReadingSection.previewState(
                    .failure("The server is unavailable.")
                ),
                horizontalPadding: PrismediaSpacing.extraLarge,
                onResume: {},
                onStartOver: {},
                onToggleCompletion: { _ in },
                onRetry: {},
                onDismissError: {}
            )
            .padding(.vertical)
        }
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
