import SwiftUI

#if os(tvOS)
    struct TVHomeView: View {
        @State private var snapshot = TVHomeSnapshot()
        @State private var failedShelfIDs = Set<String>()
        @State private var hasLoaded = false

        private let useCase: TVHomeUseCase
        private let onSelectTab: (String) -> Void

        init(client: PrismediaAPIClient, onSelectTab: @escaping (String) -> Void) {
            useCase = TVHomeUseCase(loader: PrismediaTVHomeLoader(client: client))
            self.onSelectTab = onSelectTab
        }

        init(loader: any TVHomeLoading, onSelectTab: @escaping (String) -> Void) {
            useCase = TVHomeUseCase(loader: loader)
            self.onSelectTab = onSelectTab
        }

        var body: some View {
            Group {
                if hasLoaded {
                    GeometryReader { viewport in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 48) {
                                TVHomeHero(
                                    items: snapshot.heroItems,
                                    viewportHeight: viewport.size.height
                                )

                                ForEach(TVAppCatalog.homeShelves) { shelf in
                                    TVHomeShelfSection(
                                        shelf: shelf,
                                        items: snapshot.items(for: shelf.id),
                                        failed: failedShelfIDs.contains(shelf.id),
                                        onReload: { Task { await load() } },
                                        onSelectTab: onSelectTab
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 80)
                        }
                        .ignoresSafeArea(edges: .top)
                    }
                } else {
                    PrismediaLoadingView("Loading TV home…")
                }
            }
            .prismediaScreenBackground()
            .task { await loadIfNeeded() }
            .refreshable { await load() }
            .accessibilityIdentifier("tv.home")
        }

        private func loadIfNeeded() async {
            guard !hasLoaded else { return }
            await load()
        }

        private func load() async {
            failedShelfIDs = []
            let result = await useCase.load()
            guard !Task.isCancelled else { return }
            snapshot = result.snapshot
            failedShelfIDs = result.failedShelfIDs
            hasLoaded = true
        }
    }

    #if DEBUG

        #Preview("TV Home") {
            @Previewable @State var tabFocusCoordinator = TVTabFocusCoordinator()
            PreviewShell {
                NavigationStack {
                    TVHomeView(loader: TVHomePreviewLoader(), onSelectTab: { _ in })
                }
            }
            .environment(tabFocusCoordinator)
        }
    #endif
#endif
