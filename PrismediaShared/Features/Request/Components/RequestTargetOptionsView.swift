import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestTargetOptionsView: View {
        let kind: RequestKindDefinition
        let roots: [AdministrativeLibraryRoot]
        let profiles: [AdministrativeAcquisitionProfile]
        let isLoading: Bool
        let errorMessage: String?
        @Binding var selectedProfileID: UUID?
        @Binding var selectedRootID: UUID?

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                Label("Request Options", systemImage: "slider.horizontal.3")
                    .font(.headline)

                if isLoading {
                    HStack(spacing: PrismediaSpacing.medium) {
                        ProgressView()
                        Text("Loading profiles and libraries…")
                            .foregroundStyle(PrismediaColor.textSecondary)
                    }
                } else {
                    profileControl
                    rootControl
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.destructive)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(PrismediaSpacing.large)
            .prismediaPanel()
            .accessibilityIdentifier("request.target-options")
        }

        @ViewBuilder
        private var profileControl: some View {
            if compatibleProfiles.isEmpty {
                Text("No \(profileNoun) profile yet. Permissive defaults will apply.")
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.textSecondary)
            } else {
                Picker("Quality profile", selection: profileBinding) {
                    ForEach(compatibleProfiles) { profile in
                        Text(profile.displayName).tag(Optional(profile.id))
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedProfileID) { _, profileID in
                    let profile = compatibleProfiles.first { $0.id == profileID }
                    selectedRootID = RequestTargetPolicy.defaultRootID(
                        for: profile,
                        compatibleRoots: compatibleRoots
                    )
                }
            }
        }

        @ViewBuilder
        private var rootControl: some View {
            if compatibleRoots.isEmpty {
                Text("No enabled library supports \(kind.pluralLabel.lowercased()). Add one in Settings first.")
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.destructive)
            } else {
                Picker("Import into", selection: rootBinding) {
                    ForEach(compatibleRoots) { root in
                        Text(root.label.isEmpty ? root.path : root.label).tag(Optional(root.id))
                    }
                }
                .pickerStyle(.menu)
            }
        }

        private var compatibleProfiles: [AdministrativeAcquisitionProfile] {
            RequestTargetPolicy.profiles(for: kind, from: profiles)
        }

        private var compatibleRoots: [AdministrativeLibraryRoot] { roots }

        private var profileBinding: Binding<UUID?> {
            Binding(
                get: { selectedProfileID ?? compatibleProfiles.first?.id },
                set: { selectedProfileID = $0 }
            )
        }

        private var rootBinding: Binding<UUID?> {
            Binding(
                get: { selectedRootID ?? compatibleRoots.first?.id },
                set: { selectedRootID = $0 }
            )
        }

        private var profileNoun: String {
            switch kind.profileKind {
            case .movie: "movie"
            case .videoSeries: "TV"
            case .audioLibrary: "music"
            default: "book"
            }
        }
    }

    #if DEBUG
        #Preview("Request Target Options") {
            @Previewable @State var selectedProfileID: UUID? = RequestPreviewFixtures.profileID
            @Previewable @State var selectedRootID: UUID? = RequestPreviewFixtures.rootID

            RequestTargetOptionsView(
                kind: .movie,
                roots: RequestPreviewFixtures.roots,
                profiles: RequestPreviewFixtures.profiles,
                isLoading: false,
                errorMessage: nil,
                selectedProfileID: $selectedProfileID,
                selectedRootID: $selectedRootID
            )
            .padding()
        }
    #endif
#endif
