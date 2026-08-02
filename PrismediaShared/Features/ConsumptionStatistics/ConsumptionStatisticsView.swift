import SwiftUI

struct ConsumptionStatisticsView: View {
    @Binding private var navigationPath: [EntityLink]
    @State private var snapshot = ConsumptionStatisticsSnapshot()
    @State private var timeframe = StatisticsTimeframe.year
    @State private var eventFilter = StatisticsEventFilter.all
    @State private var kindFilter: EntityKind?
    @State private var loadedFilterKey: String?

    private let service: ConsumptionStatisticsService
    private let detailDependencies: EntityDetailDependencies
    private let now: Date

    init(
        loader: any ConsumptionStatisticsLoading,
        detailDependencies: EntityDetailDependencies,
        navigationPath: Binding<[EntityLink]> = .constant([]),
        now: Date = Date()
    ) {
        _navigationPath = navigationPath
        service = ConsumptionStatisticsService(loader: loader)
        self.detailDependencies = detailDependencies
        self.now = now
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if snapshot.state == .idle || snapshot.state == .loading {
                    PrismediaLoadingView("Loading consumption history…")
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
            .navigationTitle("Consumption Stats")
            .refreshable {
                await PrismediaRefreshAction.perform {
                    _ = await reload(preservingContent: true)
                }
            }
            .prismediaEntityDestinations(dependencies: detailDependencies)
        }
        .task(id: filterKey) {
            guard loadedFilterKey != filterKey else { return }
            let preservesContent = loadedFilterKey == nil
            if await reload(preservingContent: preservesContent) {
                loadedFilterKey = filterKey
            }
        }
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
            metric("Opened", value: response?.accessedCount, systemImage: "play.rectangle.on.rectangle")
            metric("Completed", value: response?.completedCount, systemImage: "checkmark.circle.fill")
            durationMetric("Active", seconds: response?.activeSeconds, systemImage: "timer")
            if let viewingSeconds = response?.viewingSeconds, viewingSeconds > 0 {
                durationMetric("Viewing", seconds: viewingSeconds, systemImage: "tv.fill")
            }
            if let readingSeconds = response?.readingSeconds, readingSeconds > 0 {
                durationMetric("Reading", seconds: readingSeconds, systemImage: "book.fill")
            }
            if let listeningSeconds = response?.listeningSeconds, listeningSeconds > 0 {
                durationMetric("Listening", seconds: listeningSeconds, systemImage: "headphones")
            }
            metric("Skips", value: response?.skippedCount, systemImage: "forward.end.fill")
            metric("Items", value: response?.distinctEntityCount, systemImage: "trophy.fill")
        }
    }

    @ViewBuilder
    private var stateContent: some View {
        switch snapshot.state {
        case .idle, .loading:
            PrismediaLoadingView("Loading consumption history…")
        case .empty:
            ContentUnavailableView(
                "No Activity Yet",
                systemImage: "clock.arrow.circlepath",
                description: Text("Opening, viewing, listening, reading, completing, and skipping media will appear here.")
            )
            .frame(maxWidth: .infinity, minHeight: 260)
        case .failed:
            ContentUnavailableView {
                Label("Couldn’t Load Stats", systemImage: "wifi.exclamationmark")
            } actions: {
                Button("Try Again") {
                    Task {
                        _ = await reload(preservingContent: true)
                    }
                }
            }
        case .content:
            if let response = snapshot.response {
                dailyActivity(response.dailyEvents)
                kindBreakdown(response.kindBreakdown)
                consumptionRhythm(response.rhythm)
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

    private func durationMetric(
        _ title: String,
        seconds: Double?,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(seconds.map(MusicPresentation.clockTime) ?? "—")
                .font(.title.bold().monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PrismediaSpacing.large)
        .background(
            PrismediaColor.elevatedContentBackground,
            in: RoundedRectangle(cornerRadius: PrismediaRadius.control)
        )
    }

    private func dailyActivity(_ buckets: [ConsumptionStatisticsBucket]) -> some View {
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
                                .frame(width: share(bucket.accessedCount, in: bucket, width: geometry.size.width))
                            Rectangle()
                                .fill(PrismediaColor.success)
                                .frame(width: share(bucket.completedCount, in: bucket, width: geometry.size.width))
                            Rectangle()
                                .fill(PrismediaColor.warning.opacity(0.8))
                                .frame(width: share(bucket.skippedCount, in: bucket, width: geometry.size.width))
                        }
                    }
                    .frame(height: 6)
                    .clipShape(Capsule())
                    Text(
                        "\(bucket.accessedCount) opened · \(bucket.completedCount) completed · \(bucket.skippedCount) skips · \(MusicPresentation.clockTime(bucket.activeSeconds)) active"
                    )
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
        entities: [ConsumptionStatisticsEntity]
    ) -> some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
            Text(title).font(.title3.bold()).padding(.bottom, PrismediaSpacing.extraSmall)
            ForEach(Array(entities.enumerated()), id: \.element.id) { index, entity in
                if let item = snapshot.thumbnailsByID[entity.id] {
                    NavigationLink(value: EntityLink(thumbnail: item)) {
                        statisticRow(
                            item: item,
                            leading: "\(index + 1)",
                            trailing: "\(entity.accessedCount) opened · \(MusicPresentation.clockTime(entity.activeSeconds)) active"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func recentEvents(_ events: [ConsumptionStatisticsEvent]) -> some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
            Text("Recent Events").font(.title3.bold()).padding(.bottom, PrismediaSpacing.extraSmall)
            ForEach(events) { event in
                if let item = snapshot.thumbnailsByID[event.entityID] {
                    NavigationLink(value: EntityLink(thumbnail: item)) {
                        statisticRow(
                            item: item,
                            leading: eventLabel(event.kind),
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
            EntityThumbnailCardView(item: item, layout: .compact, preferredWidth: 52)
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

    private func kindBreakdown(_ slices: [ConsumptionStatisticsKindSlice]) -> some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
            Text("Media Breakdown").font(.title3.bold()).padding(.bottom, PrismediaSpacing.extraSmall)
            ForEach(slices) { slice in
                HStack(spacing: PrismediaSpacing.medium) {
                    Image(systemName: SearchHubKindCatalog.systemImage(for: slice.kind))
                        .foregroundStyle(PrismediaColor.accent)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        Text(SearchHubCatalog.sectionTitle(for: slice.kind))
                            .font(.headline)
                        Text("\(slice.accessedCount) opened · \(slice.completedCount) completed · \(MusicPresentation.clockTime(slice.activeSeconds)) active")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, PrismediaSpacing.small)
            }
        }
    }

    private func consumptionRhythm(_ cells: [ConsumptionStatisticsRhythmCell]) -> some View {
        let busiest = cells.sorted { lhs, rhs in
            if lhs.totalEvents == rhs.totalEvents { return lhs.hour < rhs.hour }
            return lhs.totalEvents > rhs.totalEvents
        }.prefix(8)
        return VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
            Text("Consumption Rhythm").font(.title3.bold()).padding(.bottom, PrismediaSpacing.extraSmall)
            ForEach(Array(busiest)) { cell in
                HStack {
                    Text("\(weekdayName(cell.dayOfWeek)) · \(hourLabel(cell.hour))")
                    Spacer()
                    Text("\(cell.totalEvents) events")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, PrismediaSpacing.extraSmall)
            }
        }
    }

    private func eventLabel(_ kind: ConsumptionEventKind) -> String {
        switch kind {
        case .accessed: "Opened"
        case .completed: "Completed"
        case .skipped: "Skipped"
        default: "Activity"
        }
    }

    private func weekdayName(_ day: Int) -> String {
        let symbols = Calendar(identifier: .gregorian).shortWeekdaySymbols
        guard day >= 1, day <= symbols.count else { return "Day \(day)" }
        return symbols[day - 1]
    }

    private func hourLabel(_ hour: Int) -> String {
        let boundedHour = min(23, max(0, hour))
        let date = Calendar(identifier: .gregorian).date(
            bySettingHour: boundedHour,
            minute: 0,
            second: 0,
            of: now
        ) ?? now
        return date.formatted(date: .omitted, time: .shortened)
    }

    private func share(
        _ value: Int,
        in bucket: ConsumptionStatisticsBucket,
        width: CGFloat
    ) -> CGFloat {
        guard bucket.totalCount > 0 else { return 0 }
        return width * CGFloat(value) / CGFloat(bucket.totalCount)
    }

    private var filterKey: String {
        "\(timeframe.rawValue)|\(eventFilter.rawValue)|\(kindFilter?.rawValue ?? "all")"
    }

    @discardableResult
    private func reload(
        preservingContent: Bool
    ) async -> Bool {
        let to = now
        let from =
            timeframe.days.flatMap {
                Calendar(identifier: .gregorian).date(byAdding: .day, value: -$0, to: to)
            } ?? Date(timeIntervalSince1970: 0)
        let query = ConsumptionStatisticsQuery(
            from: from,
            to: to,
            kind: kindFilter,
            eventKind: eventFilter.kind
        )
        if !preservingContent || snapshot.state == .idle {
            snapshot.state = .loading
        }
        let loaded = await service.load(query)
        guard !Task.isCancelled else { return false }
        snapshot = loaded
        return true
    }

    private let statisticKinds: [EntityKind] = [
        .video, .movie, .videoSeries, .audioTrack, .audioLibrary, .book, .gallery, .image,
    ]
}

#if DEBUG

    #Preview("Consumption Stats") {
        let detailLoader = StatisticsPreviewDetailLoader()
        PreviewShell(signedIn: true) {
            ConsumptionStatisticsView(
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
