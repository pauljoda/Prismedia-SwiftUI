import SwiftUI

struct AccountSessionsSection: View {
    @State private var sessions: [AccountSession] = []
    @State private var isLoading = true
    @State private var pendingRevocation: AccountSession?
    @State private var message: String?
    let service: any AccountServicing
    let onRevokedCurrentSession: () async -> Void

    var body: some View {
        Section("Signed-in Devices") {
            if isLoading && sessions.isEmpty {
                ProgressView("Loading devices…")
            } else if sessions.isEmpty {
                ContentUnavailableView("No Active Sessions", systemImage: "rectangle.stack.badge.person.crop")
            } else {
                ForEach(sessions) { session in
                    AccountSessionRow(session: session, isWorking: pendingRevocation != nil) {
                        pendingRevocation = session
                    }
                }
            }
            Button("Refresh Devices", systemImage: "arrow.clockwise") { Task { await load() } }
                .disabled(isLoading)
            if let message { Text(message).font(.footnote).foregroundStyle(PrismediaColor.destructive) }
        }
        .task { await load() }
        .confirmationDialog(
            pendingRevocation?.isCurrent == true ? "Sign out this device?" : "Revoke this session?",
            isPresented: Binding(get: { pendingRevocation != nil }, set: { if !$0 { pendingRevocation = nil } }),
            titleVisibility: .visible
        ) {
            Button(pendingRevocation?.isCurrent == true ? "Sign Out" : "Revoke", role: .destructive) {
                Task { await revoke() }
            }
        } message: {
            Text("The selected device will need the account password to sign in again.")
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            sessions = try await service.sessions()
            message = nil
        } catch { message = error.localizedDescription }
    }

    private func revoke() async {
        guard let target = pendingRevocation else { return }
        do {
            try await service.revoke(sessionID: target.id)
            pendingRevocation = nil
            if target.isCurrent {
                await onRevokedCurrentSession()
                return
            }
            sessions.removeAll { $0.id == target.id }
        } catch {
            pendingRevocation = nil
            message = error.localizedDescription
            await load()
        }
    }
}

#if DEBUG
    #Preview { Form { AccountSessionsSection(service: AccountPreviewService(), onRevokedCurrentSession: {}) } }
#endif
