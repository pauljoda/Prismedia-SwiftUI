import SwiftUI

struct AcquisitionBlocklistSettingsSection: View {
    @State private var entryCount: Int?
    @State private var clearRange = AcquisitionBlocklistClearRange.lastDay
    @State private var confirmsClear = false
    @State private var isClearing = false
    @State private var message: String?
    private let service: any AcquisitionBlocklistServicing

    init(service: any AcquisitionBlocklistServicing) {
        self.service = service
    }

    var body: some View {
        Section {
            LabeledContent("Blocked releases") {
                if let entryCount {
                    Text(entryCount, format: .number)
                } else {
                    ProgressView()
                }
            }

            Picker("Clear entries from", selection: $clearRange) {
                ForEach(AcquisitionBlocklistClearRange.allCases) { range in
                    Text(range.title).tag(range)
                }
            }

            Button(role: .destructive) {
                confirmsClear = true
            } label: {
                HStack {
                    Label("Clear Blocklist", systemImage: "trash")
                    Spacer()
                    if isClearing { ProgressView() }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .disabled(isClearing || entryCount == 0)

            if let message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Label("Release Blocklist", systemImage: "nosign")
        } footer: {
            Text("Clearing entries allows matching releases to be considered for download again.")
        }
        .task { await loadCount() }
        .confirmationDialog(
            "Clear blocklist entries from (clearRange.title.lowercased())?",
            isPresented: $confirmsClear,
            titleVisibility: .visible
        ) {
            Button("Clear Blocklist", role: .destructive) {
                Task { await clear() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Matching releases can be selected for download again.")
        }
    }

    private func loadCount() async {
        do {
            entryCount = try await service.acquisitionBlocklist(entityID: nil).count
        } catch {
            message = error.localizedDescription
        }
    }

    private func clear() async {
        isClearing = true
        defer { isClearing = false }
        do {
            let removed = try await service.clearAcquisitionBlocklist(
                entityID: nil,
                createdAfter: clearRange.createdAfter()
            )
            message = removed == 1 ? "Cleared 1 blocked release." : "Cleared (removed) blocked releases."
            await loadCount()
        } catch {
            message = error.localizedDescription
        }
    }
}

#if DEBUG
    #Preview("Acquisition Blocklist Settings · Empty") {
        Form {
            AcquisitionBlocklistSettingsSection(service: AdministrativePreviewService())
        }
    }
#endif
