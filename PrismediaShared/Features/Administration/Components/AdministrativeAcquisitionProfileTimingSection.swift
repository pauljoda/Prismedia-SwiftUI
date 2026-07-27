import SwiftUI

#if os(iOS) || os(macOS)
    struct AdministrativeAcquisitionProfileTimingSection: View {
        @State private var profiles: [AdministrativeAcquisitionProfile] = []
        @State private var selectedProfile: AdministrativeAcquisitionProfile?
        @State private var isLoading = true
        @State private var errorMessage: String?

        let service: any AdministrationServicing

        var body: some View {
            Section {
                if isLoading && profiles.isEmpty {
                    ProgressView("Loading profiles…")
                } else {
                    ForEach(profiles) { profile in
                        Button {
                            selectedProfile = profile
                        } label: {
                            LabeledContent {
                                Text(AdministrativeAcquisitionProfileTimingPolicy.summary(for: profile))
                                    .foregroundStyle(PrismediaColor.textSecondary)
                            } label: {
                                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                                    Text(profile.displayName)
                                    Text(profile.kind.displayLabel)
                                        .font(.caption)
                                        .foregroundStyle(PrismediaColor.textSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(PrismediaColor.destructive)
                }
            } header: {
                Text("Release Timing")
            } footer: {
                Text("Choose when automatic searching begins for each acquisition profile.")
            }
            .task { await load() }
            .sheet(item: $selectedProfile, onDismiss: { Task { await load() } }) { profile in
                AdministrativeAcquisitionProfileTimingEditor(profile: profile, service: service)
            }
        }

        private func load() async {
            isLoading = true
            defer { isLoading = false }
            do {
                profiles = try await service.acquisitionProfiles()
                    .sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
                errorMessage = nil
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
#endif

#if DEBUG && (os(iOS) || os(macOS))
    #Preview("Acquisition Profile Timing Section") {
        Form {
            AdministrativeAcquisitionProfileTimingSection(service: AdministrativePreviewService())
        }
        .preferredColorScheme(.dark)
    }
#endif
