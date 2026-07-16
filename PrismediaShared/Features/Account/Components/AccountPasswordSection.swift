import SwiftUI

struct AccountPasswordSection: View {
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmation = ""
    @State private var isSaving = false
    @State private var message: String?
    let service: any AccountServicing
    let onChanged: () async -> Void

    var body: some View {
        Section {
            SecureField("Current password", text: $currentPassword)
                .textContentType(.password)
            SecureField("New password", text: $newPassword)
                .textContentType(.newPassword)
            SecureField("Confirm new password", text: $confirmation)
                .textContentType(.newPassword)
            if !newPassword.isEmpty && newPassword.count < 8 {
                Text("Use at least 8 characters.").font(.footnote).foregroundStyle(PrismediaColor.destructive)
            } else if !confirmation.isEmpty && confirmation != newPassword {
                Text("Passwords do not match.").font(.footnote).foregroundStyle(PrismediaColor.destructive)
            }
            Button("Change Password", systemImage: "key") { Task { await change() } }
                .disabled(!isReady || isSaving)
            if let message { Text(message).font(.footnote).foregroundStyle(.secondary) }
        } header: {
            Text("Password")
        } footer: {
            Text("Changing your password keeps this device signed in and signs out every other session.")
        }
    }

    private var isReady: Bool {
        !currentPassword.isEmpty && newPassword.count >= 8 && confirmation == newPassword
    }

    private func change() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await service.changePassword(currentPassword: currentPassword, newPassword: newPassword)
            currentPassword = ""
            newPassword = ""
            confirmation = ""
            message = "Password changed. Other devices were signed out."
            await onChanged()
        } catch {
            message = error.localizedDescription
        }
    }
}

#if DEBUG
    #Preview { Form { AccountPasswordSection(service: AccountPreviewService(), onChanged: {}) } }
#endif
