import SwiftUI

struct AdministrativePluginCapabilitiesView: View {
    let supports: [AdministrativePluginSupport]

    var body: some View {
        #if os(tvOS)
            content
        #else
            DisclosureGroup("Capabilities") { content }
        #endif
    }

    private var content: some View {
        ForEach(supports, id: \.entityKind) { support in
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Text(support.contentTypeLabel).font(.headline)
                Text(support.actionSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#if DEBUG
    #Preview("Capabilities") {
        Form {
            AdministrativePluginCapabilitiesView(supports: [
                .init(entityKind: "movie", actions: ["search", "lookup-id"])
            ])
        }
    }
#endif
