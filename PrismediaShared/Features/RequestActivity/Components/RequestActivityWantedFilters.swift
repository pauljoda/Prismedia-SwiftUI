import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityWantedFilters: View {
        @Binding var kind: EntityKind?

        var body: some View {
            Section("Filters") {
                Picker("Kind", selection: $kind) {
                    Text("All Kinds").tag(nil as EntityKind?)
                    ForEach(RequestActivityKindCatalog.wanted) { option in
                        Text(option.displayLabel).tag(option as EntityKind?)
                    }
                }
                .pickerStyle(.menu)
            }
            .accessibilityIdentifier("request-activity.filters")
        }
    }

    #if DEBUG
        #Preview("Request Activity Wanted Filters") {
            List {
                RequestActivityWantedFilters(kind: .constant(.book))
            }
        }
    #endif
#endif
