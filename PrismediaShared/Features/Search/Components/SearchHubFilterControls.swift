import SwiftUI

struct SearchHubFilterControls: View {
    @Environment(\.dismiss) private var dismiss

    @Binding private var filters: SearchHubFilterState

    init(filters: Binding<SearchHubFilterState>) {
        _filters = filters
    }

    var body: some View {
        Form {
            Section("Entity Kinds") {
                SearchHubKindSelector(filters: $filters, usesRegularLayout: true)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, PrismediaSpacing.small)
            }

            Section("Minimum Rating") {
                Picker("Minimum rating", selection: $filters.minimumRating) {
                    Text("Any rating").tag(nil as Int?)
                    ForEach(1...5, id: \.self) { rating in
                        Text("\(rating) stars or more").tag(rating as Int?)
                    }
                }
                .pickerStyle(.menu)
            }

            Section {
                Toggle("Starting date", isOn: startingDateEnabled)
                if filters.dateFrom != nil {
                    #if os(tvOS)
                        Picker("From", selection: startingDate) {
                            ForEach(datePresets, id: \.self) { date in
                                Text(date, format: .dateTime.month().day().year())
                                    .tag(date)
                            }
                        }
                    #else
                        DatePicker(
                            "From",
                            selection: startingDate,
                            displayedComponents: .date
                        )
                    #endif
                }

                Toggle("Ending date", isOn: endingDateEnabled)
                if filters.dateTo != nil {
                    #if os(tvOS)
                        Picker("Through", selection: endingDate) {
                            ForEach(datePresets, id: \.self) { date in
                                Text(date, format: .dateTime.month().day().year())
                                    .tag(date)
                            }
                        }
                    #else
                        DatePicker(
                            "Through",
                            selection: endingDate,
                            displayedComponents: .date
                        )
                    #endif
                }
            } header: {
                Text("Date Added")
            } footer: {
                Text("Date filters use the date an item was added to the Prismedia library.")
            }

            Section {
                Button("Reset All Filters", systemImage: "arrow.counterclockwise") {
                    filters.reset()
                }
                .disabled(filters.isDefault)
                .accessibilityHint("Includes every entity kind and clears rating and date filters")
            }
        }
        .navigationTitle("Search Filters")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }

    private var startingDateEnabled: Binding<Bool> {
        Binding(
            get: { filters.dateFrom != nil },
            set: { enabled in filters.setDateFrom(enabled ? filters.dateTo ?? Date() : nil) }
        )
    }

    private var endingDateEnabled: Binding<Bool> {
        Binding(
            get: { filters.dateTo != nil },
            set: { enabled in filters.setDateTo(enabled ? filters.dateFrom ?? Date() : nil) }
        )
    }

    private var startingDate: Binding<Date> {
        Binding(
            get: { filters.dateFrom ?? Date() },
            set: { filters.setDateFrom($0) }
        )
    }

    private var endingDate: Binding<Date> {
        Binding(
            get: { filters.dateTo ?? Date() },
            set: { filters.setDateTo($0) }
        )
    }

    #if os(tvOS)
        private var datePresets: [Date] {
            let calendar = Calendar.autoupdatingCurrent
            let today = calendar.startOfDay(for: Date())
            return [
                calendar.date(byAdding: .year, value: -1, to: today),
                calendar.date(byAdding: .month, value: -1, to: today),
                calendar.date(byAdding: .day, value: -7, to: today),
                today,
            ].compactMap { $0 }
        }
    #endif
}

#if DEBUG
    #Preview("Search Filters · Active") {
        @Previewable @State var filters = SearchHubFilterState(
            selectedKinds: [.movie, .videoSeries, .video],
            minimumRating: 4,
            dateFrom: Date(timeIntervalSince1970: 1_735_689_600)
        )
        NavigationStack {
            SearchHubFilterControls(filters: $filters)
        }
        .preferredColorScheme(.dark)
    }
#endif
