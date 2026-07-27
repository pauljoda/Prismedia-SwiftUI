import SwiftUI

#if os(iOS) || os(macOS)
    public struct ReleaseCalendarView: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @State private var displayedMonth: Date
        @State private var events: [ReleaseCalendarEvent] = []
        @State private var isLoading = true
        @State private var errorMessage: String?
        @State private var mediaFilter: EntityKind?
        @State private var milestoneFilter: EntityDateType?
        @State private var selectedDay: ReleaseCalendarDaySelection?

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
            Group {
                if isLoading && events.isEmpty {
                    PrismediaLoadingView("Loading release calendar…")
                } else if let errorMessage, events.isEmpty {
                    ContentUnavailableView {
                        Label("Unable to Load Calendar", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        PrismediaButton("Try Again", systemImage: "arrow.clockwise", variant: .prominent) {
                            Task { await load() }
                        }
                    }
                } else {
                    calendarContent
                }
            }
            .navigationTitle("Release Calendar")
            .toolbar { toolbarContent }
            .prismediaScreenBackground()
            .task(id: ReleaseCalendarDatePolicy.wireValue(displayedMonth)) { await load() }
            .refreshable { await load() }
            .sheet(item: $selectedDay) { selection in
                ReleaseCalendarDaySheet(
                    selection: selection,
                    resolveAssetURL: resolveAssetURL,
                    onOpen: { event in
                        navigationPath.wrappedValue.append(
                            ReleaseCalendarPresentationPolicy.entityLink(for: event)
                        )
                    }
                )
            }
        }

        @ViewBuilder
        private var calendarContent: some View {
            if usesMonthGrid {
                ScrollView {
                    monthHeader
                    monthGrid
                        .padding(.horizontal, PrismediaSpacing.large)
                        .padding(.bottom, PrismediaSpacing.extraLarge)
                }
            } else {
                List {
                    monthHeader
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
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
                                    ReleaseCalendarEventRow(event: event, resolveAssetURL: resolveAssetURL)
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
        }

        private var monthHeader: some View {
            HStack {
                Button("Previous month", systemImage: "chevron.left") { moveMonth(-1) }
                    .labelStyle(.iconOnly)
                    .accessibilityIdentifier("release-calendar.previous-month")
                Spacer()
                Text(displayedMonth, format: .dateTime.month(.wide).year())
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("release-calendar.month")
                Spacer()
                Button("Next month", systemImage: "chevron.right") { moveMonth(1) }
                    .labelStyle(.iconOnly)
                    .accessibilityIdentifier("release-calendar.next-month")
            }
            .padding(PrismediaSpacing.large)
        }

        private var monthGrid: some View {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: PrismediaSpacing.small), count: 7), spacing: PrismediaSpacing.small) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol).font(.caption.bold()).foregroundStyle(PrismediaColor.textSecondary)
                }
                ForEach(ReleaseCalendarDatePolicy.gridDays(containing: displayedMonth), id: \.self) { date in
                    let dayEvents = events(on: date)
                    ReleaseCalendarDayCell(
                        date: date,
                        displayedMonth: displayedMonth,
                        events: dayEvents,
                        onShowAll: { selectedDay = ReleaseCalendarDaySelection(date: date, events: dayEvents) }
                    )
                }
            }
        }

        @ToolbarContentBuilder
        private var toolbarContent: some ToolbarContent {
            ToolbarItemGroup {
                Picker("Media kind", selection: $mediaFilter) {
                    Text("All media").tag(EntityKind?.none)
                    ForEach(availableKinds, id: \.self) { kind in
                        Text(kind.displayLabel).tag(EntityKind?.some(kind))
                    }
                }
                Picker("Milestone", selection: $milestoneFilter) {
                    Text("All milestones").tag(EntityDateType?.none)
                    ForEach(availableMilestones, id: \.self) { type in
                        Text(type.displayName).tag(EntityDateType?.some(type))
                    }
                }
            }
        }

        private var filteredEvents: [ReleaseCalendarEvent] {
            events.filter { event in
                (mediaFilter == nil || event.kind == mediaFilter)
                    && (milestoneFilter == nil || event.dateType == milestoneFilter)
            }
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

        private var usesMonthGrid: Bool {
            #if os(macOS)
                true
            #else
                horizontalSizeClass == .regular
            #endif
        }

        private func events(on date: Date) -> [ReleaseCalendarEvent] {
            ReleaseCalendarPresentationPolicy.groupedByDay(filteredEvents)[Calendar.current.startOfDay(for: date)] ?? []
        }

        private func moveMonth(_ value: Int) {
            if let date = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) {
                displayedMonth = date
            }
        }

        private func load() async {
            guard let interval = ReleaseCalendarDatePolicy.gridInterval(containing: displayedMonth) else { return }
            isLoading = true
            defer { isLoading = false }
            do {
                events = try await loader.releases(from: interval.start, through: interval.end)
                errorMessage = nil
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
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
