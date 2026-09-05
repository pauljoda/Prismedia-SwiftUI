import SwiftUI

struct AdministrativeUserAccountFields: View {
    @Binding var draft: AdministrativeUserDraft
    let requiresPassword: Bool

    var body: some View {
        Section {
            PrismediaFormField("Username") {
                TextField("Username", text: $draft.username, prompt: Text("Required"))
                    .prismediaPlainTextInput()
                    .textContentType(.username)
            }
            PrismediaFormField("Display name") {
                TextField("Display name", text: $draft.displayName, prompt: Text("Optional"))
            }
            if requiresPassword {
                PrismediaFormField("Password") {
                    SecureField("Password", text: $draft.password, prompt: Text("Required"))
                        .textContentType(.newPassword)
                }
            }
        } header: {
            Text("Account Details")
        } footer: {
            if requiresPassword { Text("Passwords need at least 8 characters.") }
        }
    }
}

#if DEBUG
    #Preview("User Account Fields · Accessibility") {
        @Previewable @State var draft = AdministrativeUserDraft(user: nil)
        Form { AdministrativeUserAccountFields(draft: $draft, requiresPassword: true) }
            .environment(\.dynamicTypeSize, .accessibility3)
            .preferredColorScheme(.dark)
    }
#endif
