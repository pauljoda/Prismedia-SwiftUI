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
                Section {
                    SecureField("New password", text: $password).textContentType(.newPassword)
                    SecureField("Confirm password", text: $confirmation).textContentType(.newPassword)
                    if !confirmation.isEmpty && confirmation != password {
                        Text("Passwords do not match.").foregroundStyle(PrismediaColor.destructive)
                    }
                } footer: {
                    Text(
                        "Resetting the password signs \(user.username) out everywhere, including this device if it is their account."
                    )
                }
                if let error { Section { Text(error).foregroundStyle(PrismediaColor.destructive) } }
            }
            .navigationTitle("Reset Password")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Reset") { Task { await reset() } }
                        .disabled(password.count < 8 || confirmation != password || isSaving)
                }
            }
        }
    }

    private func reset() async {
        isSaving = true
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
