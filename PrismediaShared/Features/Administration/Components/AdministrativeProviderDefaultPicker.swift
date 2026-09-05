import SwiftUI

struct AdministrativeProviderDefaultPicker: View {
    let kind: EntityKind
    let providers: [AdministrativePlugin]
    @Binding var selection: String?

    var body: some View {
        Picker(kind.displayLabel, selection: $selection) {
            Text("Automatic").tag(String?.none)
            if let selection, !providers.contains(where: { $0.id == selection }) {
                Text("Unavailable provider").tag(Optional(selection)).disabled(true)
            }
            ForEach(providers) { provider in
                Text(provider.name).tag(Optional(provider.id))
            }
        }
        #if os(iOS)
            .pickerStyle(.navigationLink)
        #endif
        .accessibilityIdentifier("administration.settings.provider.\(kind.rawValue)")
    }
}

#if DEBUG
    #Preview("Provider Picker") {
        @Previewable @State var selection: String? = "removed-provider"
        NavigationStack {
            Form { AdministrativeProviderDefaultPicker(kind: .movie, providers: [], selection: $selection) }
        }
    }
#endif
