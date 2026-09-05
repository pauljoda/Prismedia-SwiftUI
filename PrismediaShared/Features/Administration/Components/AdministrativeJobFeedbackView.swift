import SwiftUI

struct AdministrativeJobFeedbackView: View {
    @Bindable var session: AdministrativeJobSession

    var body: some View {
        if let error = session.refreshError {
            Section {
                VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                    Label(
                        session.hasLoaded ? "Activity Couldn't Refresh" : "Couldn't Load Jobs",
                        systemImage: "wifi.exclamationmark"
                    )
                    .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(PrismediaColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if session.hasLoaded {
                        Text("Showing the last received activity.")
                            .font(.subheadline)
                            .foregroundStyle(PrismediaColor.textSecondary)
                    }
                    PrismediaButton("Retry", systemImage: "arrow.clockwise") {
                        Task { await session.refresh() }
                    }
                    .disabled(session.isRefreshing || session.isMutating)
                }
            }
        }
        if session.isMutating {
            Section { ProgressView("Updating jobs…") }
        } else if let notice = session.notice {
            Section {
                HStack(spacing: PrismediaSpacing.medium) {
                    Label(notice, systemImage: "checkmark.circle")
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    PrismediaButton("Dismiss", systemImage: "xmark", form: .compactIcon) { session.notice = nil }
                }
            }
        }
    }
}
