import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityDownloadFilters: View {
        @Binding var status: RequestActivityStatusFilter
        @Binding var kind: EntityKind?
        @Binding var sort: RequestActivitySort

        let availableKinds: [EntityKind]

        var body: some View {
            Section("Filters") {
                Picker("Status", selection: $status) {
                    ForEach(RequestActivityStatusFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.menu)

                Picker("Kind", selection: $kind) {
                    Text("All Kinds").tag(nil as EntityKind?)
                    ForEach(availableKinds) { option in
                        Text(option.displayLabel).tag(option as EntityKind?)
                    }
                }
                .pickerStyle(.menu)

                Picker("Sort", selection: $sort) {
                    ForEach(RequestActivitySort.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.menu)
            }
            .accessibilityIdentifier("request-activity.filters")
        }
    }

    #if DEBUG
        #Preview("Request Activity Download Filters") {
            List {
                RequestActivityDownloadFilters(
                    status: .constant(.all),
                    kind: .constant(nil),
                    sort: .constant(.updatedNewest),
                    availableKinds: [.book, .movie, .audioTrack]
                )
            }
        }
    #endif
#endif
