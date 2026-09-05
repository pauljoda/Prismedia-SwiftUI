import SwiftUI

/// Keeps supporting administration details secondary using the platform's native navigation.
struct AdministrativeDetailsDisclosure<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: () -> Content

    init(_ title: LocalizedStringKey, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        #if os(tvOS)
            NavigationLink {
                Form { content() }
                    .prismediaSettingsForm()
                    .prismediaScreenBackground()
                    .navigationTitle(title)
            } label: {
                Text(title)
            }
        #else
            DisclosureGroup(title, content: content)
        #endif
    }
}

#if DEBUG
    #Preview("Supporting Details") {
        NavigationStack {
            Form {
                AdministrativeDetailsDisclosure("Runtime details") {
                    LabeledContent("Runtime", value: ".NET")
                }
            }
        }
    }
#endif
