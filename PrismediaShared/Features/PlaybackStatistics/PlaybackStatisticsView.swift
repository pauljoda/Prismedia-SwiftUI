import SwiftUI

struct PlaybackStatisticsView: View {
    @Binding private var navigationPath: [EntityLink]
    @State private var snapshot = PlaybackStatisticsSnapshot()
    @State private var timeframe = StatisticsTimeframe.year
    @State private var eventFilter = StatisticsEventFilter.completed
    @State private var kindFilter: EntityKind?

    private let service: PlaybackStatisticsService
    private let detailDependencies: EntityDetailDependencies
    private let now: Date

    init(
        loader: any PlaybackStatisticsLoading,
        detailDependencies: EntityDetailDependencies,
        navigationPath: Binding<[EntityLink]> = .constant([]),
        now: Date = Date()
    ) {
        _navigationPath = navigationPath
        service = PlaybackStatisticsService(loader: loader)
        self.detailDependencies = detailDependencies
        self.now = now
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if snapshot.state == .idle || snapshot.state == .loading {
                    PrismediaLoadingView("Loading playback history…")
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
                            filters
                            summary
                            stateContent
                        }
                        .padding(PrismediaSpacing.large)
                    }
                }
            }
            .prismediaScreenBackground()
            .navigationTitle("Playback Stats")
            .refreshable { await reload() }
            .prismediaEntityDestinations(dependencies: detailDependencies)
        }
        .task(id: filterKey) { await reload() }
        .accessibilityIdentifier("shell.stats")
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            Picker("Timeframe", selection: $timeframe) {
                ForEach(StatisticsTimeframe.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            HStack {
                Picker("Events", selection: $eventFilter) {
                    ForEach(StatisticsEventFilter.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)

                Spacer()

                Picker("Media", selection: $kindFilter) {
                    Text("All Media").tag(EntityKind?.none)
                    ForEach(statisticKinds, id: \.rawValue) { kind in
                        Text(SearchHubCatalog.sectionTitle(for: kind)).tag(Optional(kind))
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    @ViewBuilder
    private var summary: some View {
        let response = snapshot.response
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 140), spacing: PrismediaSpacing.medium)],
            spacing: PrismediaSpacing.medium
        ) {
            metric("Total", value: response?.totalEvents, systemImage: "waveform.path.ecg")
            metric("Plays", value: response?.completedCount, systemImage: "play.fill")
            metric("Skips", value: response?.skippedCount, systemImage: "forward.end.fill")
            metric("Items", value: response?.distinctEntityCount, systemImage: "trophy.fill")
        }
    }

    @ViewBuilder
    private var stateContent: some View {
        switch snapshot.state {
        case .idle, .loading:
            PrismediaLoadingView("Loading playback history…")
        case .empty:
            ContentUnavailableView(
                "No Playback History Yet",
                systemImage: "clock.arrow.circlepath",
                description: Text("Completed and skipped media will appear here.")
            )
            .frame(maxWidth: .infinity, minHeight: 260)
        case .failed:
            ContentUnavailableView {
                Label("Couldn’t Load Stats", systemImage: "wifi.exclamationmark")
            } actions: {
                Button("Try Again") { Task { await reload() } }
            }
        case .content:
            if let response = snapshot.response {
                dailyActivity(response.dailyEvents)
                entityList(title: "Top Entities", entities: response.topEntities)
                recentEvents(response.recentEvents)
            }
        }
    }

    private func metric(_ title: String, value: Int?, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value.map(String.init) ?? "—")
                .font(.title.bold().monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PrismediaSpacing.large)
        .background(
            PrismediaColor.elevatedContentBackground, in: RoundedRectangle(cornerRadius: PrismediaRadius.control))
    }

    private func dailyActivity(_ buckets: [PlaybackStatisticsBucket]) -> some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            Text("Daily Activity").font(.title3.bold())
            ForEach(buckets.reversed().prefix(15)) { bucket in
                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    HStack {
                        Text(bucket.date).font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(bucket.totalCount)").font(.headline.monospacedDigit())
                    }
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(PrismediaColor.accent)
                                .frame(width: share(bucket.completedCount, in: bucket, width: geometry.size.width))
                            Rectangle().fill(PrismediaColor.warning.opacity(0.8))
                        }
                    }
                    .frame(height: 6)
                    .clipShape(Capsule())
                    Text("\(bucket.completedCount) plays · \(bucket.skippedCount) skips")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(PrismediaSpacing.medium)
                .background(
                    PrismediaColor.elevatedContentBackground,
                    in: RoundedRectangle(cornerRadius: PrismediaRadius.control))
            }
        }
    }

    private func entityList(
        title: String,
        entities: [PlaybackStatisticsEntity]
    ) -> some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
            Text(title).font(.title3.bold()).padding(.bottom, PrismediaSpacing.extraSmall)
            ForEach(Array(entities.enumerated()), id: \.element.id) { index, entity in
                if let item = snapshot.thumbnailsByID[entity.id] {
                    NavigationLink(value: EntityLink(thumbnail: item)) {
                        statisticRow(
                            item: item,
                            leading: "\(index + 1)",
                            trailing: "\(entity.completedCount) plays · \(entity.skippedCount) skips"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func recentEvents(_ events: [PlaybackStatisticsEvent]) -> some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
            Text("Recent Events").font(.title3.bold()).padding(.bottom, PrismediaSpacing.extraSmall)
            ForEach(events) { event in
                if let item = snapshot.thumbnailsByID[event.entityID] {
                    NavigationLink(value: EntityLink(thumbnail: item)) {
                        statisticRow(
                            item: item,
                            leading: event.kind == .completed ? "Played" : "Skipped",
                            trailing: event.occurredAt.formatted(.relative(presentation: .named))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func statisticRow(
        item: EntityThumbnail,
        leading: String,
        trailing: String
    ) -> some View {
        HStack(spacing: PrismediaSpacing.medium) {
            Text(leading)
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(PrismediaColor.accent)
                .frame(minWidth: 34)
            EntityThumbnailCompactArtworkView(item: item, width: 52)
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Text(item.title).lineLimit(1)
                Text(trailing).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.forward").font(.caption).foregroundStyle(.tertiary)
        }
        .padding(.vertical, PrismediaSpacing.small)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func share(
        _ value: Int,
        in bucket: PlaybackStatisticsBucket,
        width: CGFloat
    ) -> CGFloat {
        guard bucket.totalCount > 0 else { return 0 }
        return width * CGFloat(value) / CGFloat(bucket.totalCount)
    }

    private var filterKey: String {
        "\(timeframe.rawValue)|\(eventFilter.rawValue)|\(kindFilter?.rawValue ?? "all")"
    }

    private func reload() async {
        let to = now
        let from =
            timeframe.days.flatMap {
                Calendar(identifier: .gregorian).date(byAdding: .day, value: -$0, to: to)
            } ?? Date(timeIntervalSince1970: 0)
        let query = PlaybackStatisticsQuery(
            from: from,
            to: to,
            kind: kindFilter,
            eventKind: eventFilter.kind
        )
        snapshot.state = .loading
        let loaded = await service.load(query)
        guard !Task.isCancelled else { return }
        snapshot = loaded
    }

    private let statisticKinds: [EntityKind] = [
        .video, .movie, .videoSeries, .audioTrack, .audioLibrary, .book, .gallery, .image,
    ]
}

#if DEBUG

    #Preview("Playback Stats") {
        let detailLoader = StatisticsPreviewDetailLoader()
        PreviewShell(signedIn: true) {
            PlaybackStatisticsView(
                loader: StatisticsPreviewLoader(),
                detailDependencies: EntityDetailDependencies(
                    detailLoader: detailLoader,
                    mutator: nil,
                    collectionItemsLoader: nil,
                    readerService: nil,
                    videoPlaybackService: nil,
                    onEntityMutated: {}
                ),
                now: Date(timeIntervalSince1970: 1_752_201_600)
            )
        }
    }
#endif
