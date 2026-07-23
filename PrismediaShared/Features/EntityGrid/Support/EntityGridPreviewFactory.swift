#if DEBUG
    enum EntityGridPreviewFactory {
        static var randomControls: EntityGridControls {
            var controls = EntityGridControls(baselineQuery: EntityListQuery())
            controls.sort = .random
            return controls
        }

        static var compactListPreset: EntityGridPreset {
            EntityGridPreset(
                name: "Recently Added",
                preferences: EntityGridPreferences(
                    controls: EntityGridControls(baselineQuery: EntityListQuery()),
                    displayMode: .list,
                    density: .compact,
                    pageSize: 24
                )
            )
        }
    }
#endif
