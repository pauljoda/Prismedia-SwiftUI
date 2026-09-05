import SwiftUI

struct AdministrativeUserPasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var confirmation = ""
    @State private var isSaving = false
    @State private var error: String?
    let user: UserAccount
    let service: any UserAdministrationServicing
    let onReset: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                if isSaving { Section { ProgressView("Resetting password…") } }
                Section {
                    PrismediaFormField("New password") {
                        SecureField("New password", text: $password, prompt: Text("Required"))
                            .textContentType(.newPassword)
                    }
                    PrismediaFormField("Confirm password") {
                        SecureField("Confirm password", text: $confirmation, prompt: Text("Re-enter password"))
                            .textContentType(.newPassword)
                    }
                    if !confirmation.isEmpty && confirmation != password {
                        Text("Passwords do not match.").foregroundStyle(PrismediaColor.destructive)
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                        Text("Passwords need at least 8 characters.")
                        Text(
                            "Resetting the password signs \(user.username) out everywhere, including this device if it is their account."
                        )
                    }
                }
                if let error { Section { Text(error).foregroundStyle(PrismediaColor.destructive) } }
            }
            .disabled(isSaving)
            .prismediaScreenBackground()
            .navigationTitle("Reset Password")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    PrismediaToolbarActionButton("Cancel", systemImage: "xmark") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    PrismediaToolbarActionButton("Reset", systemImage: "arrow.counterclockwise") {
                        Task { await reset() }
                    }
                    .disabled(password.count < 8 || confirmation != password || isSaving)
                }
            }
        }
        .interactiveDismissDisabled(isSaving)
    }

    private func reset() async {
        guard !isSaving, password.count >= 8, confirmation == password else { return }
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            try await service.resetPassword(id: user.id, newPassword: password)
            onReset()
            dismiss()
        } catch let caught { error = caught.localizedDescription }
    }
}

#if DEBUG
    #Preview("Password Reset") {
        AdministrativeUserPasswordSheet(
            user: PrismediaPreviewData.user,
            service: Step3AdministrationPreviewService(),
            onReset: {}
        )
    }
#endif
