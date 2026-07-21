#if os(iOS) || os(macOS)
    import SwiftUI

    struct MusicLibraryView: View {
        @Environment(PrismediaAppEnvironment.self) private var environment
        @Environment(MusicPlayerController.self) private var controller
        @State private var snapshot: EntityGridSnapshot
        @State private var searchText = ""
        @State private var filtersPresented = false
        @State private var artistNamesByID: [UUID: String] = [:]
        @State private var visibleTracksByID: [UUID: MusicTrack] = [:]

        private let configuration: EntityGridConfiguration
        private let layout: MusicLibraryLayout
        private let service: EntityGridService
        private let controlCatalog: EntityGridControlCatalog
        private let preferencesStore: EntityGridPreferencesStore

        @MainActor
        init(
            configuration: EntityGridConfiguration,
            layout: MusicLibraryLayout,
            loader: any EntityGridLoading,
            preferencesStore: EntityGridPreferencesStore = .standard
        ) {
            self.configuration = configuration
            self.layout = layout
            service = EntityGridService(loader: loader)
            controlCatalog = EntityGridControlCatalog(query: configuration.query)
            self.preferencesStore = preferencesStore
            let restoredControls =
                preferencesStore
                .load(for: configuration.preferencesID)?
                .controls(baselineQuery: configuration.query)
            _snapshot = State(
                initialValue: EntityGridSnapshot(
                    configuration: configuration,
                    restoredControls: restoredControls
                )
            )
        }

        var body: some View {
            Group {
                switch snapshot.state {
                case .idle, .loading:
                    PrismediaLoadingView("Loading \(configuration.title.lowercased())…")

                case .content, .empty, .failed:
                    ScrollView {
                        LazyVStack(
                            alignment: .leading,
                            spacing: PrismediaSpacing.large,
                            pinnedViews: [.sectionHeaders]
                        ) {
                            if layout != .artists { playbackHeader }
                            stateContent
                        }
                        .padding(.horizontal, PrismediaSpacing.large)
                        .padding(.bottom, PrismediaSpacing.section)
                    }
                }
            }
            .prismediaScreenBackground()
            .navigationTitle(configuration.title)
            .prismediaInlineNavigationTitle()
            .toolbar { libraryToolbar }
            .sheet(isPresented: $filtersPresented) {
                EntityGridControlsView(
                    controls: snapshot.controls,
                    catalog: controlCatalog
                ) { controls in
                    Task { await applyControls(controls) }
                }
            }
            .searchable(text: $searchText, prompt: "Search \(configuration.title.lowercased())")
            .onSubmit(of: .search) { Task { await submitSearch() } }
            .task(id: searchText) {
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                await searchIfChanged()
            }
            .onChange(of: searchText) { _, newValue in
                guard
                    newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    snapshot.activeSearch != nil
                else { return }
                Task { await submitSearch() }
            }
            .task { await loadIfNeeded() }
            .task(id: parentArtistIDs) { await resolveParentArtists() }
            .task(id: visibleTrackIDs) { await resolveVisibleTracks() }
            .refreshable { await refresh() }
        }

        @ViewBuilder
        private var stateContent: some View {
            if snapshot.state == .content {
                librarySections
                paginationFooter
            } else if snapshot.state == .empty {
                ContentUnavailableView("No \(configuration.title)", systemImage: "music.note")
                    .frame(maxWidth: .infinity, minHeight: 280)
            } else if case .failed(let message) = snapshot.state {
                ContentUnavailableView {
                    Label("Couldn’t Load \(configuration.title)", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again") { Task { await loadFirstPage(preservingContent: false) } }
                }
                .frame(maxWidth: .infinity, minHeight: 280)
            }
        }

        private var presentedLibrarySections: [MusicLibrarySection] {
            MusicLibrarySection.sections(
                for: snapshot.items,
                sort: snapshot.controls.sort,
                sortDescending: snapshot.controls.sortDescending
            )
        }

        private var librarySections: some View {
            ForEach(presentedLibrarySections) { section in
                Section {
                    switch layout {
                    case .albums:
                        albumGrid(section.items)
                    case .artists:
                        artistRows(section.items)
                    case .tracks:
                        trackRows(section.items)
                    }
                } header: {
                    if !section.title.isEmpty {
                        MusicPinnedSectionHeader(title: section.title)
                    }
                }
            }
        }

        private func trackRows(_ trackThumbnails: [EntityThumbnail]) -> some View {
            LazyVStack(spacing: 0) {
                ForEach(trackThumbnails) { thumbnail in
                    let track = visibleTracksByID[thumbnail.id] ?? MusicTrack(thumbnail: thumbnail)
                    Button {
                        playVisibleTracks(startingAt: track.id)
                    } label: {
                        HStack(spacing: PrismediaSpacing.medium) {
                            RemotePosterImage(
                                path: track.artworkPath,
                                fallbackSeed: track.album ?? track.title,
                                systemImage: "music.note"
                            )
                            .frame(
                                width: PrismediaLayout.minimumHitTarget,
                                height: PrismediaLayout.minimumHitTarget
                            )
                            .clipShape(RoundedRectangle(cornerRadius: PrismediaRadius.badge, style: .continuous))

                            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                                Text(track.title)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(PrismediaColor.textPrimary)
                                    .lineLimit(1)
                                Text([track.artist, track.album].compactMap { $0 }.joined(separator: " — "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            if let duration = track.duration {
                                Text(MusicPresentation.clockTime(duration))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, PrismediaSpacing.small)
                        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("music.track.row.\(track.id.uuidString)")
                    .onAppear {
                        prewarmArtwork(after: thumbnail.id)
                    }
                    Divider().opacity(0.22).padding(.leading, 56)
                }
            }
        }

        private func albumGrid(_ albums: [EntityThumbnail]) -> some View {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: PrismediaSpacing.small),
                    GridItem(.flexible(), spacing: PrismediaSpacing.small),
                ],
                alignment: .leading,
                spacing: PrismediaSpacing.large
            ) {
                ForEach(albums) { album in
                    NavigationLink(
                        value: EntityLink(
                            thumbnail: album,
                            previewSubtitle: MusicPresentation.albumArtist(album, artistNamesByID: artistNamesByID)
                        )
                    ) {
                        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                            Color.clear
                                .aspectRatio(1, contentMode: .fit)
                                .overlay {
                                    RemotePosterImage(
                                        path: album.bestCoverPath,
                                        fallbackSeed: album.title,
                                        systemImage: "square.stack"
                                    )
                                }
                                .clipShape(RoundedRectangle(cornerRadius: PrismediaRadius.compact, style: .continuous))
                            Text(album.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(PrismediaColor.textPrimary)
                                .lineLimit(1)
                            Text(MusicPresentation.albumArtist(album, artistNamesByID: artistNamesByID))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        prewarmArtwork(after: album.id)
                    }
                }
            }
        }

        private func artistRows(_ artists: [EntityThumbnail]) -> some View {
            LazyVStack(spacing: 0) {
                ForEach(artists) { artist in
                    NavigationLink(value: EntityLink(thumbnail: artist)) {
                        HStack(spacing: PrismediaSpacing.medium) {
                            RemotePosterImage(
                                path: artist.bestCoverPath,
                                fallbackSeed: artist.title,
                                systemImage: "music.mic"
                            )
                            .frame(width: 38, height: 38)
                            .clipShape(Circle())
                            Text(artist.title)
                                .font(.body.weight(.medium))
                                .foregroundStyle(PrismediaColor.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, PrismediaSpacing.small)
                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("music.artist.row.\(artist.id.uuidString)")
                    .onAppear {
                        prewarmArtwork(after: artist.id)
                    }
                    Divider().opacity(0.22).padding(.leading, 50)
                }
            }
        }

        private var paginationFooter: some View {
            VStack(spacing: PrismediaSpacing.medium) {
                if snapshot.isLoadingNextPage {
                    ProgressView("Loading more…")
                } else if let message = snapshot.paginationErrorMessage {
                    Text(message)
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    PrismediaButton("Try Again") {
                        Task { await loadNextPage() }
                    }
                } else if snapshot.hasNextPage {
                    Color.clear
                        .frame(height: 1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(
                .vertical,
                snapshot.hasNextPage || snapshot.paginationErrorMessage != nil ? 12 : 0
            )
            .task(id: snapshot.nextCursor) {
                guard
                    snapshot.hasNextPage,
                    !snapshot.isLoadingNextPage,
                    snapshot.paginationErrorMessage == nil
                else { return }
                await loadNextPage()
            }
        }

        private var playbackHeader: some View {
            MusicLibraryPlaybackActions(
                context: EntityGridTopContentContext(
                    query: snapshot.controls.applying(to: configuration.query),
                    search: snapshot.activeSearch,
                    visibleItemCount: snapshot.items.count
                )
            )
            .padding(.top, PrismediaSpacing.extraSmall)
        }

        @ToolbarContentBuilder
        private var libraryToolbar: some ToolbarContent {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    ForEach(controlCatalog.sortOptions) { option in
                        Button(option.label) {
                            var controls = snapshot.controls
                            controls.sort = option
                            controls.sortDescending = option.defaultDescending
                            Task { await applyControls(controls) }
                        }
                    }

                    Divider()

                    Button {
                        Task { await resetControls() }
                    } label: {
                        Label("Reset Sort and Filters", systemImage: "arrow.counterclockwise")
                    }
                    .disabled(controlsAreDefault)
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                }
                Button {
                    filtersPresented = true
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }

        private func loadIfNeeded() async {
            guard snapshot.state == .idle else { return }
            await loadFirstPage(preservingContent: false)
        }

        private func refresh() async {
            await loadFirstPage(preservingContent: !snapshot.items.isEmpty)
        }

        private func submitSearch() async {
            snapshot.setSearch(searchText)
            await loadFirstPage(preservingContent: false)
        }

        private func searchIfChanged() async {
            guard snapshot.setSearch(searchText) else { return }
            await loadFirstPage(preservingContent: false)
        }

        private func applyControls(_ controls: EntityGridControls) async {
            snapshot.setControls(controls)
            preferencesStore.save(
                EntityGridPreferences(controls: controls),
                for: configuration.preferencesID
            )
            await loadFirstPage(preservingContent: false)
        }

        private func resetControls() async {
            snapshot.resetControls(for: configuration)
            preferencesStore.reset(for: configuration.preferencesID)
            await loadFirstPage(preservingContent: false)
        }

        private var controlsAreDefault: Bool {
            EntityGridPreferences(controls: snapshot.controls)
                == EntityGridPreferences(
                    controls: EntityGridControls(baselineQuery: configuration.query)
                )
        }

        private func loadFirstPage(preservingContent: Bool) async {
            let request = snapshot.beginFirstPage(
                configuration: configuration,
                preservingContent: preservingContent
            )

            do {
                let page = try await service.loadFirstPage(request)
                guard !Task.isCancelled else {
                    snapshot.cancel(request)
                    return
                }
                snapshot.receiveFirstPage(page, for: request)
            } catch is CancellationError {
                snapshot.cancel(request)
            } catch {
                guard !Task.isCancelled else {
                    snapshot.cancel(request)
                    return
                }
                snapshot.failFirstPage(title: configuration.title, for: request)
            }
        }

        private func loadNextPage() async {
            guard let request = snapshot.beginNextPage(configuration: configuration) else { return }

            do {
                let page = try await service.loadNextVisiblePage(request)
                guard !Task.isCancelled else {
                    snapshot.cancel(request)
                    return
                }
                snapshot.receiveNextPage(page, for: request)
            } catch is CancellationError {
                snapshot.cancel(request)
            } catch {
                guard !Task.isCancelled else {
                    snapshot.cancel(request)
                    return
                }
                snapshot.failNextPage(for: request)
            }
        }

        private var orderedLibraryItems: [EntityThumbnail] {
            presentedLibrarySections.flatMap(\.items)
        }

        private var parentArtistIDs: [UUID] {
            guard layout == .albums else { return [] }
            return Array(Set(snapshot.items.compactMap(\.parentEntityID)))
                .sorted { $0.uuidString < $1.uuidString }
        }

        private var visibleTrackIDs: [UUID] {
            guard layout == .tracks else { return [] }
            return snapshot.items.map(\.id)
        }

        private func resolveParentArtists() async {
            guard let client = environment.client else { return }
            let unresolved = parentArtistIDs.filter { artistNamesByID[$0] == nil }
            guard !unresolved.isEmpty else { return }
            guard let artists = try? await client.fetchEntityThumbnails(ids: unresolved) else { return }
            for artist in artists where artist.kind == .musicArtist {
                artistNamesByID[artist.id] = artist.title
            }
        }

        private func resolveVisibleTracks() async {
            guard layout == .tracks, let client = environment.client else { return }
            let unresolved = snapshot.items.filter { visibleTracksByID[$0.id] == nil }
            guard !unresolved.isEmpty else { return }
            guard let tracks = try? await MusicLibraryQueueLoader(client: client).hydrate(unresolved) else { return }
            guard !Task.isCancelled else { return }
            for track in tracks { visibleTracksByID[track.id] = track }
        }

        private func prewarmArtwork(after itemID: UUID) {
            guard let client = environment.client else { return }
            let urls =
                EntityGridArtworkPrewarming
                .paths(after: itemID, in: orderedLibraryItems)
                .compactMap { client.assetURL(for: $0) }
            guard !urls.isEmpty else { return }
            Task(priority: .utility) { await RemoteArtworkPipeline.shared.prewarm(urls) }
        }

        private func playVisibleTracks(startingAt trackID: UUID) {
            let tracks = orderedLibraryItems.map {
                visibleTracksByID[$0.id] ?? MusicTrack(thumbnail: $0)
            }
            controller.play(tracks: tracks, startingAt: trackID)
        }

    }

    #if DEBUG
        #Preview("Music Library · Albums · Dark") {
            @Previewable @State var controller = MusicPreviewData.controller(playing: false)
            let albums = [
                EntityThumbnail(
                    id: UUID(uuidString: "0D516F73-4C7F-4424-A357-2D079D0758D0")!, kind: .audioLibrary, title: "1",
                    meta: [.init(icon: "artist", label: "The Beatles")]),
                EntityThumbnail(
                    id: UUID(uuidString: "81CD08EB-A52B-47B1-9202-48DC3BD13E96")!, kind: .audioLibrary,
                    title: "A New World",
                    meta: [.init(icon: "artist", label: "AmaLee")]),
            ]
            PreviewShell(signedIn: true) {
                NavigationStack {
                    MusicLibraryView(
                        configuration: .init(title: "Albums", query: .init(kind: .audioLibrary)),
                        layout: .albums,
                        loader: MusicLibraryPreviewLoader(items: albums),
                        preferencesStore: .disabled
                    )
                    .environment(controller)
                }
            }
            .preferredColorScheme(.dark)
        }

        #Preview("Music Library · Artists") {
            @Previewable @State var controller = MusicPreviewData.controller(playing: false)
            let artists = [
                EntityThumbnail(
                    id: UUID(uuidString: "2F52586D-3762-483E-9148-2017600D25B6")!, kind: .musicArtist, title: "AmaLee"),
                EntityThumbnail(
                    id: UUID(uuidString: "2C6115E8-D3EC-41B6-BF22-FE6D3CC3D8E0")!, kind: .musicArtist,
                    title: "The Beatles"),
                EntityThumbnail(
                    id: UUID(uuidString: "27E361CB-0C7F-4EB8-8F89-EB8406D82324")!, kind: .musicArtist,
                    title: "Explosions in the Sky and the Very Long Artist Name"),
            ]
            PreviewShell(signedIn: true) {
                NavigationStack {
                    MusicLibraryView(
                        configuration: .init(title: "Artists", query: .init(kind: .musicArtist)),
                        layout: .artists,
                        loader: MusicLibraryPreviewLoader(items: artists),
                        preferencesStore: .disabled
                    )
                    .environment(controller)
                }
            }
        }

        #Preview("Music Library · Tracks") {
            @Previewable @State var controller = MusicPreviewData.controller(playing: false)
            let tracks = [
                EntityThumbnail(
                    id: UUID(uuidString: "4F5F547A-0402-4C2D-A552-363D9252184E")!, kind: .audioTrack,
                    title: "Calling Waves",
                    meta: [.init(icon: "duration", label: "06:21")]),
                EntityThumbnail(
                    id: UUID(uuidString: "BC1E5F3F-0E49-4149-8084-ECF80E40C681")!, kind: .audioTrack, title: "Shots",
                    meta: [.init(icon: "duration", label: "03:52")]),
            ]
            PreviewShell(signedIn: true) {
                NavigationStack {
                    MusicLibraryView(
                        configuration: .init(title: "Tracks", query: .init(kind: .audioTrack)),
                        layout: .tracks,
                        loader: MusicLibraryPreviewLoader(items: tracks),
                        preferencesStore: .disabled
                    )
                    .environment(controller)
                }
            }
        }
    #endif
#endif
