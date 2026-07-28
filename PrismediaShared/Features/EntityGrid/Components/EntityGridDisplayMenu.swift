import SwiftUI

struct EntityGridDisplayMenu: View {
    let availableDisplayModes: [EntityGridDisplayMode]
    let displayMode: EntityGridDisplayMode
    let density: EntityGridDensity
    let pageSize: Int
    let appDefaultShowsThumbnailText: Bool
    let showsThumbnailTextOverride: Bool?
    let presets: [EntityGridPreset]
    let preferencesAreDefault: Bool
    let onSelectDisplayMode: (EntityGridDisplayMode) -> Void
    let onSelectDensity: (EntityGridDensity) -> Void
    let onSelectPageSize: (Int) -> Void
    let onSetShowsThumbnailText: (Bool?) -> Void
    let onApplyPreset: (EntityGridPreset) -> Void
    let onRequestSavePreset: () -> Void
    let onDeletePreset: (EntityGridPreset) -> Void
    let onResetPreferences: () -> Void

    var body: some View {
        Menu {
            if availableDisplayModes.count > 1 {
                Section("Layout") {
                    ForEach(availableDisplayModes) { option in
                        Button {
                            onSelectDisplayMode(option)
                        } label: {
                            Label(
                                option.label,
                                systemImage: displayMode == option
                                    ? "checkmark"
                                    : option.systemImage
                            )
                        }
                    }
                }
            }

            Section("Thumbnail Text") {
                Toggle("Show Text Below Thumbnails", isOn: showsThumbnailTextBinding)

                if showsThumbnailTextOverride != nil {
                    Button("Use App Default", systemImage: "arrow.uturn.backward") {
                        onSetShowsThumbnailText(nil)
                    }
                }
            }

            if displayMode != .list {
                Section("Item Size") {
                    ForEach(EntityGridDensity.allCases) { option in
                        Button {
                            onSelectDensity(option)
                        } label: {
                            if density == option {
                                Label(option.label, systemImage: "checkmark")
                            } else {
                                Text(option.label)
                            }
                        }
                    }
                }
            }

            Section("Page Size") {
                ForEach(EntityGridPageSizeCatalog.options, id: \.self) { option in
                    Button {
                        onSelectPageSize(option)
                    } label: {
                        if pageSize == option {
                            Label("\(option) items", systemImage: "checkmark")
                        } else {
                            Text("\(option) items")
                        }
                    }
                }
            }

            #if !os(tvOS)
                Section("Presets") {
                    ForEach(presets) { preset in
                        Button(preset.name) {
                            onApplyPreset(preset)
                        }
                    }

                    Button(action: onRequestSavePreset) {
                        Label("Save Current as Preset", systemImage: "plus")
                    }

                    if !presets.isEmpty {
                        Menu("Delete Preset", systemImage: "trash") {
                            ForEach(presets) { preset in
                                Button(preset.name, role: .destructive) {
                                    onDeletePreset(preset)
                                }
                            }
                        }
                    }
                }
            #endif

            Divider()

            Button(action: onResetPreferences) {
                Label("Reset Grid Settings", systemImage: "arrow.counterclockwise")
            }
            .disabled(preferencesAreDefault)
        } label: {
            Image(systemName: displayMode.systemImage)
        }
        .accessibilityLabel("Display options")
        .accessibilityValue(
            "\(displayMode.label), \(density.label) size, thumbnail text \(showsThumbnailText ? "shown" : "hidden")"
        )
        .accessibilityIdentifier("entity.grid.display")
    }

    private var showsThumbnailText: Bool {
        showsThumbnailTextOverride ?? appDefaultShowsThumbnailText
    }

    private var showsThumbnailTextBinding: Binding<Bool> {
        Binding(
            get: { showsThumbnailText },
            set: { onSetShowsThumbnailText($0) }
        )
    }
}

#if DEBUG
    #Preview("Entity Grid Display · Default") {
        EntityGridDisplayMenu(
            availableDisplayModes: EntityGridDisplayMode.allCases,
            displayMode: .grid,
            density: .standard,
            pageSize: 48,
            appDefaultShowsThumbnailText: true,
            showsThumbnailTextOverride: nil,
            presets: [],
            preferencesAreDefault: true,
            onSelectDisplayMode: { _ in },
            onSelectDensity: { _ in },
            onSelectPageSize: { _ in },
            onSetShowsThumbnailText: { _ in },
            onApplyPreset: { _ in },
            onRequestSavePreset: {},
            onDeletePreset: { _ in },
            onResetPreferences: {}
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }

    #Preview("Entity Grid Display · Presets") {
        EntityGridDisplayMenu(
            availableDisplayModes: [.grid, .list],
            displayMode: .list,
            density: .compact,
            pageSize: 24,
            appDefaultShowsThumbnailText: true,
            showsThumbnailTextOverride: false,
            presets: [EntityGridPreviewFactory.compactListPreset],
            preferencesAreDefault: false,
            onSelectDisplayMode: { _ in },
            onSelectDensity: { _ in },
            onSelectPageSize: { _ in },
            onSetShowsThumbnailText: { _ in },
            onApplyPreset: { _ in },
            onRequestSavePreset: {},
            onDeletePreset: { _ in },
            onResetPreferences: {}
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }
#endif
