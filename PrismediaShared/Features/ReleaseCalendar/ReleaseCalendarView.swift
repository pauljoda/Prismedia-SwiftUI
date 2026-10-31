import SwiftUI

#if os(iOS) || os(macOS)
    public struct ReleaseCalendarView: View {
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @State private var displayedMonth: Date
        @State private var monthNavigationDirection = 1
        @State private var eventsByMonth: [String: [ReleaseCalendarEvent]] = [:]
        @State private var pendingMonth: Date?
        @State private var isLoading = true
        @State private var errorMessage: String?
        @State private var mediaFilter: EntityKind?
        @State private var milestoneFilter: EntityDateType?
        /// The day picked in the month grid; the day pane lists its releases.
        @State private var selectedDay: Date?
        @State private var monthGridHeight: CGFloat = 0
        #if os(iOS)
            @GestureState private var isMonthSwipeActive = false
            @State private var eventActivationSuppressedUntil = Date.distantPast
        #endif

        private let loader: any ReleaseCalendarLoading
        private let resolveAssetURL: (String?) -> URL?
        private let navigationPath: Binding<[EntityLink]>

        public init(
            loader: any ReleaseCalendarLoading,
            navigationPath: Binding<[EntityLink]>,
            initialDate: Date = .now,
            resolveAssetURL: @escaping (String?) -> URL? = { $0.flatMap(URL.init(string:)) }
        ) {
            self.loader = loader
            self.navigationPath = navigationPath
            self.resolveAssetURL = resolveAssetURL
            _displayedMonth = State(initialValue: initialDate)
        }

        public var body: some View {
            ZStack {
                if isLoading && events.isEmpty {
                    PrismediaLoadingView("Loading release calendar…")
                } else if let errorMessage, events.isEmpty {
                    ContentUnavailableView {
                        Label("Unable to Load Calendar", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        PrismediaButton("Try Again", systemImage: "arrow.clockwise", variant: .prominent) {
                            Task { await load(forceRefresh: true) }
                        }
                    }
                } else if usesDayPane {
                    PrismediaArrangedPanes {
                        VStack(spacing: 0) {
                            monthHeader
                            ScrollView {
                                monthGrid
                                    .padding(.horizontal, PrismediaSpacing.large)
                                    .padding(.bottom, PrismediaSpacing.small)
                            }
                            .scrollBounceBehavior(.basedOnSize)
                            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
                                monthGridHeight = $0
                            }
                            .id(displayedMonthKey)
                            .transition(monthTransition)
                        }
                    } secondary: {
                        ReleaseCalendarDayPane(
                            date: focusedDay,
                            events: events(on: focusedDay),
                            resolveAssetURL: resolveAssetURL,
                            onOpen: open
                        )
                        .allowsHitTesting(calendarContentAllowsHitTesting)
                    }
                } else {
                    VStack(spacing: 0) {
                        monthHeader
                        agendaList
                            .id(displayedMonthKey)
                            .transition(monthTransition)
                    }
                }
            }
            #if os(iOS)
                .simultaneousGesture(monthSwipeGesture)
            #endif
            .navigationTitle("Release Calendar")
            .prismediaInlineNavigationTitle()
            .toolbar { toolbarContent }
            .prismediaScreenBackground()
            .task(id: displayedMonthKey) { await load(forceRefresh: false) }
            .task(id: pendingMonth) { await loadPendingMonth() }
            .refreshable { await load(forceRefresh: true) }
        }

        private var monthHeader: some View {
            ReleaseCalendarMonthHeader(
                month: displayedMonth,
                isDisabled: pendingMonth != nil,
                onPrevious: { moveMonth(-1) },
                onNext: { moveMonth(1) }
            )
        }

        private var agendaList: some View {
            List {
                if agendaDays.isEmpty {
                    ContentUnavailableView(
                        "No Releases",
                        systemImage: "calendar",
                        description: Text("No monitored milestones match these filters.")
                    )
                    .accessibilityIdentifier("release-calendar.empty")
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(agendaDays, id: \.self) { date in
                        Section(date.formatted(date: .complete, time: .omitted)) {
                            ForEach(events(on: date)) { event in
                                ReleaseCalendarEventRow(
                                    event: event,
                                    resolveAssetURL: resolveAssetURL,
                                    onOpen: { open(event) }
                                )
                                .allowsHitTesting(calendarContentAllowsHitTesting)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }

        private var monthGrid: some View {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                // Weekday initials repeat (two Ts and two Ss), so they're keyed by position.
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption.bold())
                        .foregroundStyle(PrismediaColor.textSecondary)
                        .frame(height: Self.weekdayRowHeight)
                }
                ForEach(ReleaseCalendarDatePolicy.gridDays(containing: displayedMonth), id: \.self) { date in
                    ReleaseCalendarMonthDayCell(
                        date: date,
                        displayedMonth: displayedMonth,
                        events: events(on: date),
                        isSelected: date == focusedDay,
                        height: monthGridRowHeight,
                        action: { select(date) }
                    )
                    .allowsHitTesting(calendarContentAllowsHitTesting)
                }
            }
        }

        @ToolbarContentBuilder
        private var toolbarContent: some ToolbarContent {
            ToolbarItemGroup(placement: .primaryAction) {
                ReleaseCalendarMediaFilterMenu(
                    selection: $mediaFilter,
                    options: availableKinds
                )
                ReleaseCalendarMilestoneFilterMenu(
                    selection: $milestoneFilter,
                    options: availableMilestones
                )
            }
        }

        private var filteredEvents: [ReleaseCalendarEvent] {
            events.filter { event in
                (mediaFilter == nil || event.kind == mediaFilter)
                    && (milestoneFilter == nil || event.dateType == milestoneFilter)
            }
        }

        private var events: [ReleaseCalendarEvent] {
            eventsByMonth[displayedMonthKey] ?? []
        }

        private var displayedMonthKey: String {
            ReleaseCalendarDatePolicy.monthCacheKey(for: displayedMonth)
        }

        private var agendaDays: [Date] {
            ReleaseCalendarPresentationPolicy.groupedByDay(filteredEvents).keys
                .filter { $0 != .distantPast }
                .sorted()
        }

        private var availableMilestones: [EntityDateType] {
            Array(Set(events.map(\.dateType))).sorted { $0.milestoneOrder < $1.milestoneOrder }
        }

        private var availableKinds: [EntityKind] {
            Array(Set(events.map(\.kind))).sorted {
                $0.displayLabel.localizedStandardCompare($1.displayLabel) == .orderedAscending
            }
        }

        private var weekdaySymbols: [String] {
            let symbols = Calendar.current.veryShortStandaloneWeekdaySymbols
            let offset = max(0, Calendar.current.firstWeekday - 1)
            return Array(symbols[offset...] + symbols[..<offset])
        }

        /// Regular width lists the selected day's releases beside a compact month
        /// grid; compact width lists the month's releases by day.
        private var usesDayPane: Bool {
            #if os(macOS)
                true
            #else
                horizontalSizeClass == .regular
            #endif
        }

        private static let weekdayRowHeight: CGFloat = 22

        /// The grid's six weeks share the pane's height, between a compact row and
        /// a comfortable one, so a whole month shows in half of a folded iPhone Duo;
        /// a pane shorter than that scrolls.
        private var monthGridRowHeight: CGFloat {
            let available = (monthGridHeight - Self.weekdayRowHeight - PrismediaSpacing.small) / 6
            return min(52, max(32, available.rounded(.down)))
        }

        private var focusedDay: Date {
            ReleaseCalendarDatePolicy.focusedDay(
                selected: selectedDay,
                in: displayedMonth,
                today: .now,
                releaseDays: agendaDays
            )
        }

        private func events(on date: Date) -> [ReleaseCalendarEvent] {
            ReleaseCalendarPresentationPolicy.groupedByDay(filteredEvents)[Calendar.current.startOfDay(for: date)] ?? []
        }

        private func moveMonth(_ value: Int) {
            guard pendingMonth == nil,
                let monthStart = Calendar.current.dateInterval(of: .month, for: displayedMonth)?.start,
                let date = Calendar.current.date(byAdding: .month, value: value, to: monthStart)
            else { return }
            monthNavigationDirection = value
            if eventsByMonth[ReleaseCalendarDatePolicy.monthCacheKey(for: date)] != nil {
                transition(to: date)
            } else {
                pendingMonth = date
            }
        }

        private func transition(to date: Date) {
            withAnimation(monthNavigationAnimation) {
                displayedMonth = date
            }
        }

        private func open(_ event: ReleaseCalendarEvent) {
            guard eventActivationAllowed else { return }
            navigationPath.wrappedValue.append(
                ReleaseCalendarPresentationPolicy.entityLink(for: event)
            )
        }

        private var eventActivationAllowed: Bool {
            #if os(iOS)
                Date.now >= eventActivationSuppressedUntil
            #else
                true
            #endif
        }

        private var calendarContentAllowsHitTesting: Bool {
            #if os(iOS)
                !isMonthSwipeActive
            #else
                true
            #endif
        }

        private func select(_ date: Date) {
            guard eventActivationAllowed else { return }
            selectedDay = date
        }

        private var monthNavigationAnimation: Animation {
            reduceMotion
                ? .easeInOut(duration: 0.16)
                : .smooth(duration: 0.28)
        }

        private var monthTransition: AnyTransition {
            guard !reduceMotion else { return .opacity }
            let insertionEdge: Edge = monthNavigationDirection > 0 ? .trailing : .leading
            let removalEdge: Edge = monthNavigationDirection > 0 ? .leading : .trailing
            return .asymmetric(
                insertion: .move(edge: insertionEdge).combined(with: .opacity),
                removal: .move(edge: removalEdge).combined(with: .opacity)
            )
        }

        #if os(iOS)
            private var monthSwipeGesture: some Gesture {
                DragGesture(minimumDistance: 30)
                    .updating($isMonthSwipeActive) { value, isActive, _ in
                        isActive = isHorizontalMonthSwipe(value)
                    }
                    .onChanged(handleMonthSwipeChange)
                    .onEnded(handleMonthSwipe)
            }

            private func handleMonthSwipeChange(_ value: DragGesture.Value) {
                guard isHorizontalMonthSwipe(value) else { return }
                eventActivationSuppressedUntil = Date.now.addingTimeInterval(0.2)
            }

            private func handleMonthSwipe(_ value: DragGesture.Value) {
                let horizontalDistance = value.translation.width
                let verticalDistance = value.translation.height
                if isHorizontalMonthSwipe(value) {
                    eventActivationSuppressedUntil = Date.now.addingTimeInterval(0.2)
                }
                if abs(horizontalDistance) >= 60,
                    abs(horizontalDistance) > abs(verticalDistance) * 1.2
                {
                    moveMonth(horizontalDistance < 0 ? 1 : -1)
                }
            }

            private func isHorizontalMonthSwipe(_ value: DragGesture.Value) -> Bool {
                let horizontalDistance = abs(value.translation.width)
                let verticalDistance = abs(value.translation.height)
                return horizontalDistance >= 12
                    && horizontalDistance > verticalDistance * 1.2
            }
        #endif

        private func load(forceRefresh: Bool) async {
            let targetMonth = displayedMonth
            let targetKey = ReleaseCalendarDatePolicy.monthCacheKey(for: targetMonth)
            let cachedKeys = Set(eventsByMonth.keys)
            let requests: [(key: String, interval: DateInterval)] =
                ReleaseCalendarDatePolicy.preloadMonths(around: targetMonth).compactMap { month in
                    let key = ReleaseCalendarDatePolicy.monthCacheKey(for: month)
                    guard (forceRefresh && key == targetKey) || !cachedKeys.contains(key),
                        let interval = ReleaseCalendarDatePolicy.gridInterval(containing: month)
                    else { return nil }
                    return (key: key, interval: interval)
                }

            guard !requests.isEmpty else {
                isLoading = false
                errorMessage = nil
                return
            }

            if eventsByMonth[targetKey] == nil {
                isLoading = true
            }
            defer {
                if displayedMonthKey == targetKey {
                    isLoading = false
                }
            }

            let loader = loader
            var targetErrorMessage: String?
            var loadedEventsByKey: [String: [ReleaseCalendarEvent]] = [:]
            await withTaskGroup(
                of: (key: String, events: [ReleaseCalendarEvent]?, errorMessage: String?).self
            ) { group in
                for request in requests {
                    group.addTask {
                        do {
                            let events = try await loader.releases(
                                from: request.interval.start,
                                through: request.interval.end
                            )
                            return (request.key, events, nil)
                        } catch is CancellationError {
                            return (request.key, nil, nil)
                        } catch {
                            return (request.key, nil, error.localizedDescription)
                        }
                    }
                }

                for await result in group {
                    guard !Task.isCancelled else { return }
                    if let events = result.events {
                        loadedEventsByKey[result.key] = events
                    } else if result.key == targetKey {
                        targetErrorMessage = result.errorMessage
                    }
                }
            }

            guard !Task.isCancelled else { return }
            for (key, events) in loadedEventsByKey {
                eventsByMonth[key] = events
            }
            if let targetErrorMessage {
                errorMessage = targetErrorMessage
            } else if eventsByMonth[targetKey] != nil {
                errorMessage = nil
            }
            pruneEventCache(around: targetMonth)
        }

        private func loadPendingMonth() async {
            guard let pendingMonth,
                let interval = ReleaseCalendarDatePolicy.gridInterval(containing: pendingMonth)
            else { return }
            let key = ReleaseCalendarDatePolicy.monthCacheKey(for: pendingMonth)
            do {
                let events = try await loader.releases(from: interval.start, through: interval.end)
                guard !Task.isCancelled, self.pendingMonth == pendingMonth else { return }
                eventsByMonth[key] = events
                errorMessage = nil
                transition(to: pendingMonth)
                self.pendingMonth = nil
                pruneEventCache(around: pendingMonth)
            } catch is CancellationError {
                return
            } catch {
                guard self.pendingMonth == pendingMonth else { return }
                errorMessage = error.localizedDescription
                self.pendingMonth = nil
            }
        }

        private func pruneEventCache(around month: Date) {
            let retainedKeys = Set(
                (-2...2).compactMap { offset in
                    Calendar.current.date(byAdding: .month, value: offset, to: month)
                }.map { ReleaseCalendarDatePolicy.monthCacheKey(for: $0) }
            )
            eventsByMonth = eventsByMonth.filter { retainedKeys.contains($0.key) }
        }
    }
#endif

#if DEBUG && (os(iOS) || os(macOS))
    #Preview("Release Calendar") {
        PreviewShell {
            NavigationStack {
                ReleaseCalendarView(
                    loader: PreviewReleaseCalendarLoader(),
                    navigationPath: .constant([]),
                    initialDate: ReleaseCalendarPreviewFixtures.day,
                    resolveAssetURL: { _ in nil }
                )
            }
        }
        .preferredColorScheme(.dark)
    }
#endif
