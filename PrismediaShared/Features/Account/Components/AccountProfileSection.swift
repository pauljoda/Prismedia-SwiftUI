import SwiftUI

struct AccountProfileSection: View {
    @State private var displayName: String
    @State private var isSaving = false
    @State private var message: String?
    let user: UserAccount
    let service: any AccountServicing
    let onSaved: () async -> Void

    init(user: UserAccount, service: any AccountServicing, onSaved: @escaping () async -> Void) {
        self.user = user
        self.service = service
        self.onSaved = onSaved
        _displayName = State(initialValue: user.displayName)
    }

    var body: some View {
        Section("Profile") {
            LabeledContent("Username", value: "@\(user.username)")
            LabeledContent("Role", value: user.isAdmin ? "Administrator" : "Member")
            TextField("Display name", text: $displayName)
                .textContentType(.name)
                .disabled(isSaving)
            Button("Save Profile", systemImage: "checkmark") { Task { await save() } }
                .disabled(
                    !isValid || isSaving
                        || displayName.trimmingCharacters(in: .whitespacesAndNewlines) == user.displayName)
            if let message {
                Text(message).font(.footnote).foregroundStyle(
                    message == "Profile saved." ? .secondary : PrismediaColor.destructive)
            }
        }
    }

    private var isValid: Bool {
        let count = displayName.trimmingCharacters(in: .whitespacesAndNewlines).count
        return (1...128).contains(count)
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await service.updateProfile(
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            await onSaved()
            message = "Profile saved."
        } catch {
            message = error.localizedDescription
        }
    }
}

#if DEBUG
    #Preview {
        Form { AccountProfileSection(user: PrismediaPreviewData.user, service: AccountPreviewService(), onSaved: {}) }
    }
#endif
