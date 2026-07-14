import SwiftUI

struct AdministrativeIdentifyView: View {
    @State private var items: [AdministrativeIdentifyQueueItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    private let service: any AdministrationServicing
    private let detailDependencies: EntityDetailDependencies
    private let navigationPath: Binding<[EntityLink]>

    init(
        service: any AdministrationServicing,
        detailDependencies: EntityDetailDependencies,
        navigationPath: Binding<[EntityLink]>
    ) {
        self.service = service
        self.detailDependencies = detailDependencies
        self.navigationPath = navigationPath
    }

    var body: some View {
        NavigationStack(path: navigationPath) {
            List {
                ForEach(items) { item in
                    #if os(tvOS)
                        identifyLink(item)
                            .contextMenu {
                                Button("Remove", systemImage: "trash", role: .destructive) {
                                    Task { await remove(item) }
                                }
                            }
                    #else
                        identifyLink(item)
                            .swipeActions {
                                Button("Remove", systemImage: "trash", role: .destructive) {
                                    Task { await remove(item) }
                                }
                            }
                    #endif
                }
            }
            .prismediaScreenBackground()
            .overlay {
                if isLoading && items.isEmpty {
                    PrismediaLoadingView("Loading queue…")
                } else if isLoading {
                    ProgressView("Loading queue…")
                } else if items.isEmpty {
                    ContentUnavailableView(
                        "Identify Queue Is Empty", systemImage: "checkmark.circle",
                        description: Text("Entities needing metadata review will appear here."))
                }
            }
            .navigationTitle("Identify")
            .refreshable { await load() }
            .prismediaEntityDestinations(dependencies: detailDependencies)
            .alert(
                "Identify Unavailable",
                isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
        .task { await load() }
        .accessibilityIdentifier("administration.identify")
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do { items = try await service.identifyQueue() } catch { errorMessage = error.localizedDescription }
    }

    private func identifyLink(_ item: AdministrativeIdentifyQueueItem) -> some View {
        NavigationLink(value: EntityLink(entityID: item.entityID, kind: item.entityKind)) {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                HStack {
                    Text(item.title)
                    Spacer()
                    Text(item.state.capitalized).font(.caption).foregroundStyle(.secondary)
                }
                Text(item.entityKind.rawValue).font(.caption).foregroundStyle(.secondary)
                if let error = item.error { Text(error).font(.caption).foregroundStyle(PrismediaColor.destructive) }
            }
        }
    }

    private func remove(_ item: AdministrativeIdentifyQueueItem) async {
        do {
            try await service.removeIdentifyItem(entityID: item.entityID)
            items.removeAll { $0.id == item.id }
        } catch { errorMessage = error.localizedDescription }
    }
}

#if DEBUG
    #Preview {
        AdministrativeIdentifyView(
            service: AdministrativePreviewService(),
            detailDependencies: EntityDetailDependencies(
                detailLoader: PreviewEntityDetailLoader(detail: EntityDetailPreviewFixture.detail),
                mutator: nil,
                collectionItemsLoader: nil,
                readerService: nil,
                videoPlaybackService: VideoPlaybackPreviewService(),
                onEntityMutated: {}
            ),
            navigationPath: .constant([])
        )
    }
#endif
