import SwiftUI

#if os(iOS) || os(macOS)
    struct AdministrativeAcquisitionProfileTimingEditor: View {
        @Environment(\.dismiss) private var dismiss
        @State private var milestone: EntityDateType?
        @State private var delayDays: Int
        @State private var isSaving = false
        @State private var errorMessage: String?

        let profile: AdministrativeAcquisitionProfile
        let service: any AdministrationServicing

        init(profile: AdministrativeAcquisitionProfile, service: any AdministrationServicing) {
            self.profile = profile
            self.service = service
            _milestone = State(initialValue: profile.searchAfterDateType)
            _delayDays = State(initialValue: profile.searchDelayDays)
        }

        var body: some View {
            NavigationStack {
                Form {
                    Section {
                        Picker("Release milestone", selection: $milestone) {
                            Text("Immediately").tag(EntityDateType?.none)
                            ForEach(AdministrativeAcquisitionProfileTimingPolicy.supportedTypes(for: profile.kind), id: \.self) { type in
                                Text(type.displayName).tag(EntityDateType?.some(type))
                            }
                        }

                        if milestone != nil {
                            Stepper("Delay: \(delayDays) day\(delayDays == 1 ? "" : "s")", value: $delayDays, in: 0...3650)
                        }

                        if let description = AdministrativeAcquisitionProfileTimingPolicy.compatibilityDescription(for: milestone) {
                            Text(description)
                                .font(.footnote)
                                .foregroundStyle(PrismediaColor.textSecondary)
                        }
                    } header: {
                        Text("Search Timing")
                    } footer: {
                        Text("Immediate searching remains the default. A release milestone delays automatic searching; Manual search remains available from the acquisition.")
                    }

                    if let errorMessage {
                        Section {
                            Label(errorMessage, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(PrismediaColor.destructive)
                        }
                    }
                }
                .prismediaSettingsForm()
                .prismediaScreenBackground()
                .navigationTitle(profile.displayName)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        PrismediaToolbarActionButton(
                            "Cancel",
                            systemImage: "xmark",
                            role: .cancel,
                            action: dismiss.callAsFunction
                        )
                        .disabled(isSaving)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        PrismediaToolbarActionButton("Save", systemImage: "checkmark") {
                            Task { await save() }
                        }
                        .disabled(isSaving)
                    }
                }
                .overlay { if isSaving { ProgressView() } }
            }
        }

        private func save() async {
            isSaving = true
            defer { isSaving = false }
            do {
                _ = try await service.updateAcquisitionProfileTiming(
                    profile,
                    searchAfterDateType: milestone,
                    searchDelayDays: milestone == nil ? 0 : delayDays
                )
                dismiss()
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
#endif

#if DEBUG && (os(iOS) || os(macOS))
    #Preview("Acquisition Profile Release Timing") {
        AdministrativeAcquisitionProfileTimingEditor(
            profile: AdministrativeAcquisitionProfile(
                id: UUID(),
                kind: .movie,
                displayName: "Movie Default",
                isDefault: true,
                targetLibraryRootID: UUID(),
                searchAfterDateType: .streamingRelease,
                searchDelayDays: 2
            ),
            service: AdministrativePreviewService()
        )
    }
#endif
