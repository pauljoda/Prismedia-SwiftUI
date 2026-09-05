import SwiftUI

/// Keeps a field's label visible while its value is edited, using native form sizing.
struct PrismediaFormField<Content: View>: View {
    let title: LocalizedStringKey
    let content: Content

    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            content
                .labelsHidden()
                .accessibilityLabel(title)
        }
    }
}

#if DEBUG
    #Preview("Form Fields · Filled") {
        Form {
            PrismediaFormField("Username") {
                TextField("Username", text: .constant("reader"))
            }
            PrismediaFormField("Display name") {
                TextField("Display name", text: .constant("Library Reader"))
            }
        }
        .preferredColorScheme(.dark)
    }
#endif
