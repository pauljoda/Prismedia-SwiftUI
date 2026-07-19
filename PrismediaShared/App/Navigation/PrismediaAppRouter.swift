import Foundation
import Observation

/// App-wide navigation state retained independently of the shell's adaptive
/// presentation. iPhone tabs can become an iPad or Mac sidebar without losing
/// the selected mode, per-destination paths, search task state, or playback restore
/// destination.
@Observable
@MainActor
public final class PrismediaAppRouter {
    public static let searchPathID = "search"

    public private(set) var navigation: AppShellNavigation
    public private(set) var selectedTab: PrismediaTabSelection
    public var searchText: String
    public var searchFilters: SearchHubFilterState

    /// Synchronous platform handoff invoked before a shared entity link mutates
    /// the active stack. The video host uses it to request PiP while its player
    /// layer is still visible.
    @ObservationIgnored public var onWillOpenEntity: (() -> Void)?

    private var navigationPaths: [String: [EntityLink]]

    public init(
        initialMode: AppMode = ModeCatalog.overview,
        initialDestinationID: String? = nil,
        initialSearchSelected: Bool = false
    ) {
        let navigation = AppShellNavigation(
            mode: initialMode,
            destinationID: initialDestinationID
                ?? initialMode.destinations.first?.id
                ?? "dashboard"
        )
        self.navigation = navigation
        selectedTab =
            initialSearchSelected
            ? .search
            : .destination(navigation.destinationID)
        searchText = ""
        searchFilters = SearchHubFilterState()
        navigationPaths = [:]
    }

    public func activeMode(in availableModes: [AppMode]) -> AppMode {
        availableModes.first { $0.id == navigation.modeID }
            ?? availableModes.first
            ?? ModeCatalog.overview
    }

    public func activeTabDestinations(
        in availableModes: [AppMode]
    ) -> [AppDestination] {
        activeMode(in: availableModes)
            .tabDestinations(selectedDestinationID: navigation.destinationID)
    }

    public func select(
        tab: PrismediaTabSelection,
        availableModes: [AppMode]
    ) {
        selectedTab = tab
        guard case .destination(let destinationID) = tab else { return }
        navigation.select(
            destinationID: destinationID,
            in: activeMode(in: availableModes)
        )
    }

    public func select(mode: AppMode) {
        navigation.select(mode: mode)
        selectedTab = .destination(navigation.destinationID)
    }

    public func select(mode: AppMode, destination: AppDestination) {
        navigation.select(mode: mode, destination: destination)
        selectedTab = .destination(destination.id)
    }

    @discardableResult
    public func selectDashboardSection(
        _ section: DashboardSectionDefinition
    ) -> Bool {
        guard
            let mode = ModeCatalog.mode(containing: section.destinationID),
            let destination = mode.destination(id: section.destinationID)
        else { return false }

        select(mode: mode, destination: destination)
        return true
    }

    public func path(for destinationID: String) -> [EntityLink] {
        navigationPaths[destinationID] ?? []
    }

    public func setPath(_ path: [EntityLink], for destinationID: String) {
        navigationPaths[destinationID] = path
    }

    @discardableResult
    public func navigateBack(in destinationID: String) -> Bool {
        guard var path = navigationPaths[destinationID], !path.isEmpty else { return false }
        path.removeLast()
        navigationPaths[destinationID] = path
        return true
    }

    public func open(
        entity: EntityThumbnail,
        previewSubtitle: String? = nil,
        intent: EntityNavigationIntent = .detail,
        within mediaSequence: EntityMediaSequence? = nil
    ) {
        let link = EntityLink(
            thumbnail: entity,
            previewSubtitle: previewSubtitle,
            intent: intent,
            mediaSequence: mediaSequence
        )
        open(link: link)
    }

    public func open(link: EntityLink) {
        onWillOpenEntity?()
        let destinationID =
            switch selectedTab {
            case .search:
                Self.searchPathID
            case .destination(let destinationID):
                destinationID
            }
        var path = path(for: destinationID)
        path.append(link)
        setPath(path, for: destinationID)
    }

    public func restoreVideoPlayback(_ link: EntityLink) async {
        let destinationID =
            if link.kind == .movie {
                "movies"
            } else if link.kind == .videoSeason
                || link.kind == .videoSeries
            {
                "series"
            } else {
                "videos"
            }
        guard let destination = ModeCatalog.video.destination(id: destinationID) else { return }

        select(mode: ModeCatalog.video, destination: destination)
        await Task.yield()
        guard path(for: destinationID).last != link else { return }
        setPath([link], for: destinationID)
    }

    public func reconcile(with availableModes: [AppMode]) {
        navigation.reconcile(with: availableModes)
        guard case .destination = selectedTab else { return }
        selectedTab = .destination(navigation.destinationID)
    }

    public func reset() {
        navigation = AppShellNavigation(
            mode: ModeCatalog.overview,
            destinationID: ModeCatalog.overview.destinations.first?.id ?? "dashboard"
        )
        selectedTab = .destination(navigation.destinationID)
        searchText = ""
        searchFilters = SearchHubFilterState()
        navigationPaths.removeAll()
        onWillOpenEntity = nil
    }
}
