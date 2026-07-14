import SwiftUI

public struct EntityImageViewerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var contentLoader: EntityMediaContentLoader
    @State private var exportStore: EntityImageExportStore
    @State private var chrome = EntityImageViewerChromeState()
    @State private var chromeTask: Task<Void, Never>?
    @State private var metadataLink: EntityLink?
    @GestureState private var dismissDragTranslation = CGSize.zero

    private let session: EntityImageViewerSession
    private let initialDetail: EntityDetail?
    private let dependencies: EntityDetailDependencies

    public init(
        session: EntityImageViewerSession,
        initialDetail: EntityDetail? = nil,
        dependencies: EntityDetailDependencies
    ) {
        self.init(
            session: session,
            initialDetail: initialDetail,
            dependencies: dependencies,
            exportStore: EntityImageExportStore()
        )
    }

    private init(
        session: EntityImageViewerSession,
        initialDetail: EntityDetail?,
        dependencies: EntityDetailDependencies,
        exportStore: EntityImageExportStore
    ) {
        self.session = session
        self.initialDetail = initialDetail
        self.dependencies = dependencies
        _contentLoader = State(
            initialValue: EntityMediaContentLoader(
                detailLoader: dependencies.detailLoader,
                sourceLoader: dependencies.imageSourceLoader,
                retainedItems: session.currentEntityID.map {
                    session.sequence.preloadItems(around: $0)
                } ?? [],
                initialDetails: initialDetail.map { [$0] } ?? []
            )
        )
        _exportStore = State(initialValue: exportStore)
    }

    #if DEBUG
        init(
            previewSession session: EntityImageViewerSession,
            initialDetail: EntityDetail? = nil,
            dependencies: EntityDetailDependencies
        ) {
            self.init(
                session: session,
                initialDetail: initialDetail,
                dependencies: dependencies,
                exportStore: EntityImageExportStore(previewDisabled: true)
            )
        }
    #endif

    public var body: some View {
        #if os(iOS)
            viewerContent
                .suppressesMusicMiniPlayer()
                .navigationBarBackButtonHidden(true)
                .toolbarBackground(.hidden, for: .navigationBar, .bottomBar)
                .toolbarVisibility(
                    chrome.isVisible ? .visible : .hidden,
                    for: .navigationBar, .bottomBar
                )
                .toolbarVisibility(.hidden, for: .tabBar)
                .statusBarHidden(!chrome.isVisible)
        #elseif os(macOS)
            viewerContent
                .suppressesMusicMiniPlayer()
                .toolbarVisibility(chrome.isVisible ? .visible : .hidden)
        #else
            viewerContent
        #endif
    }

    private var viewerContent: some View {
        GeometryReader { viewport in
            ZStack {
                Color.black.ignoresSafeArea()
                pager(viewportSize: viewport.size)
            }
        }
        .ignoresSafeArea()
        #if os(iOS) || os(macOS)
            .toolbar {
                EntityImageViewerToolbar(
                    title: session.currentItem?.title ?? "Image",
                    positionLabel: positionLabel,
                    onClose: dismiss.callAsFunction,
                    onOpenDetails: openDetails
                )
            }
        #endif
        .overlay { keyboardNavigation }
        .offset(y: dismissOffset)
        .scaleEffect(dismissScale)
        #if !os(tvOS)
            .simultaneousGesture(dismissGesture)
        #endif
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Image viewer")
        .accessibilityValue(positionLabel)
        .accessibilityAdjustableAction(moveAccessibility)
        .accessibilityIdentifier("image-viewer")
        .task(id: session.currentEntityID) {
            guard let currentEntityID = session.currentEntityID else { return }
            await session.loadNextPageIfNeeded()
            guard !Task.isCancelled else { return }
            await contentLoader.prepare(
                activeEntityID: currentEntityID,
                sequence: session.sequence
            )
        }
        .task { scheduleChromeHide() }
        .onChange(of: session.currentEntityID) {
            chrome.pageChanged()
            scheduleChromeHide()
        }
        .onDisappear {
            chromeTask?.cancel()
            Task { await exportStore.removeAll() }
        }
        .prismediaEntityDestination(item: $metadataLink, dependencies: dependencies)
    }

    private func pager(viewportSize: CGSize) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(session.sequence.items) { item in
                    EntityImageViewerPage(
                        item: item,
                        initialDetail: item.id == initialDetail?.id ? initialDetail : nil,
                        contentLoader: contentLoader,
                        exportStore: exportStore,
                        isActive: item.id == session.currentEntityID,
                        showsControls: chrome.isVisible
                    )
                    .frame(width: viewportSize.width, height: viewportSize.height)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: contentTapped)
                    .id(item.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: currentEntityIDBinding)
        .scrollDisabled(session.sequence.items.count < 2)
        .frame(width: viewportSize.width, height: viewportSize.height)
        #if os(macOS) || os(tvOS)
            .onMoveCommand(perform: moveCommand)
        #endif
    }

    @ViewBuilder
    private var keyboardNavigation: some View {
        #if !os(tvOS)
            HStack {
                Button("Previous Image") { move(.previous) }
                    .keyboardShortcut(.leftArrow, modifiers: [])
                Button("Next Image") { move(.next) }
                    .keyboardShortcut(.rightArrow, modifiers: [])
            }
            .frame(width: 1, height: 1)
            .opacity(0.001)
            .accessibilityHidden(true)
        #endif
    }

    private var currentEntityIDBinding: Binding<UUID?> {
        let session = session
        return Binding(
            get: { session.currentEntityID },
            set: { entityID in
                guard let entityID else { return }
                session.select(entityID)
            }
        )
    }

    private var positionLabel: String {
        guard let currentEntityID = session.currentEntityID else { return "" }
        guard let index = session.sequence.index(of: currentEntityID) else { return "" }
        return "\(index + 1) of \(session.sequence.items.count)"
    }

    private func moveAccessibility(_ direction: AccessibilityAdjustmentDirection) {
        switch direction {
        case .increment:
            move(.next)
        case .decrement:
            move(.previous)
        @unknown default:
            break
        }
    }

    private func move(_ direction: EntityImageViewerPagingDirection) {
        guard let currentEntityID = session.currentEntityID else { return }
        let paging = EntityImageViewerPaging(entityIDs: session.sequence.items.map(\.id))
        guard let destination = paging.destination(from: currentEntityID, direction: direction)
        else { return }
        withAnimation(.snappy) { session.select(destination) }
    }

    #if os(macOS) || os(tvOS)
        private func moveCommand(_ direction: MoveCommandDirection) {
            switch direction {
            case .left: move(.previous)
            case .right: move(.next)
            default: break
            }
        }
    #endif

    private func contentTapped() {
        withAnimation(.easeOut(duration: 0.2)) { chrome.contentTapped() }
        scheduleChromeHide()
    }

    private func scheduleChromeHide() {
        chromeTask?.cancel()
        guard chrome.shouldScheduleHide else { return }
        chromeTask = Task { @MainActor in
            try? await Task.sleep(for: EntityImageViewerChromeState.autoHideDelay)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) { chrome.hide() }
            chromeTask = nil
        }
    }

    private func openDetails() {
        guard let currentItem = session.currentItem else { return }
        chromeTask?.cancel()
        metadataLink = EntityLink(thumbnail: currentItem, intent: .metadata)
    }

    private var dismissOffset: CGFloat {
        EntityImageViewerDismissPolicy.interactiveOffset(for: dismissDragTranslation)
    }

    private var dismissScale: CGFloat {
        1 - min(dismissOffset / 2_400, 0.04)
    }

    #if !os(tvOS)
        private var dismissGesture: some Gesture {
            DragGesture(minimumDistance: 12)
                .updating($dismissDragTranslation) { value, state, _ in
                    state = CGSize(
                        width: 0,
                        height: EntityImageViewerDismissPolicy.interactiveOffset(
                            for: value.translation
                        )
                    )
                }
                .onEnded { value in
                    guard
                        EntityImageViewerDismissPolicy.shouldDismiss(
                            translation: value.translation,
                            predictedEndTranslation: value.predictedEndTranslation
                        )
                    else { return }
                    dismiss()
                }
        }
    #endif
}

#if DEBUG
    #Preview("Image Viewer · Sequence") {
        @Previewable @State var session = EntityImageViewerSession(
            selected: EntityImageViewerPreviewData.items[0],
            sequence: EntityMediaSequence(items: EntityImageViewerPreviewData.items)
        )
        let loader = EntityMediaPreviewLoader(
            details: EntityImageViewerPreviewData.details
        )
        PreviewShell(signedIn: true) {
            EntityImageViewerView(
                previewSession: session,
                initialDetail: EntityImageViewerPreviewData.details[EntityImageViewerPreviewData.firstID],
                dependencies: EntityDetailDependencies(
                    detailLoader: loader,
                    mutator: nil,
                    collectionItemsLoader: nil,
                    readerService: nil,
                    videoPlaybackService: nil,
                    onEntityMutated: {},
                    imageSourceLoader: loader
                )
            )
        }
    }

    #Preview("Image Viewer · Loading") {
        @Previewable @State var session = EntityImageViewerSession(
            selected: EntityImageViewerPreviewData.items[0]
        )
        let loader = EntityMediaPreviewLoader(
            details: EntityImageViewerPreviewData.details,
            delayMilliseconds: 10_000
        )
        PreviewShell(signedIn: true) {
            EntityImageViewerView(
                previewSession: session,
                dependencies: EntityDetailDependencies(
                    detailLoader: loader,
                    mutator: nil,
                    collectionItemsLoader: nil,
                    readerService: nil,
                    videoPlaybackService: nil,
                    onEntityMutated: {},
                    imageSourceLoader: loader
                )
            )
        }
    }

    #Preview("Image Viewer · Error") {
        @Previewable @State var session = EntityImageViewerSession(
            selected: EntityImageViewerPreviewData.items[0]
        )
        let loader = EntityMediaPreviewLoader(
            details: [:],
            failure: URLError(.notConnectedToInternet)
        )
        PreviewShell(signedIn: true) {
            EntityImageViewerView(
                previewSession: session,
                dependencies: EntityDetailDependencies(
                    detailLoader: loader,
                    mutator: nil,
                    collectionItemsLoader: nil,
                    readerService: nil,
                    videoPlaybackService: nil,
                    onEntityMutated: {},
                    imageSourceLoader: loader
                )
            )
        }
    }

    #Preview("Image Viewer · Accessibility Type") {
        @Previewable @State var session = EntityImageViewerSession(
            selected: EntityImageViewerPreviewData.items[0],
            sequence: EntityMediaSequence(items: EntityImageViewerPreviewData.items)
        )
        let loader = EntityMediaPreviewLoader(
            details: EntityImageViewerPreviewData.details
        )
        PreviewShell(signedIn: true) {
            EntityImageViewerView(
                previewSession: session,
                dependencies: EntityDetailDependencies(
                    detailLoader: loader,
                    mutator: nil,
                    collectionItemsLoader: nil,
                    readerService: nil,
                    videoPlaybackService: nil,
                    onEntityMutated: {},
                    imageSourceLoader: loader
                )
            )
            .environment(\.dynamicTypeSize, .accessibility3)
        }
    }
#endif
