#if DEBUG
    import Foundation

    /// Supplies an isolated mock session to post-authentication UI tests without
    /// coupling feature smoke tests to keyboard or sign-in automation.
    enum PrismediaUITestBootstrap {
        static func session(
            arguments: [String] = CommandLine.arguments,
            environment: [String: String] = ProcessInfo.processInfo.environment
        ) -> AuthSession? {
            guard arguments.contains("-prismedia-ui-testing"),
                let serverValue = environment["PRISMEDIA_UI_TEST_SESSION_SERVER"],
                let serverURL = URL(string: serverValue),
                let token = environment["PRISMEDIA_UI_TEST_SESSION_TOKEN"],
                !token.isEmpty
            else { return nil }

            return AuthSession(
                serverURL: serverURL,
                accessToken: token,
                user: UserAccount(
                    id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
                    username: "test",
                    displayName: "Test User",
                    role: .admin,
                    allowSfw: true,
                    allowNsfw: true,
                    canCreateLibraries: true
                )
            )
        }

        @MainActor
        static func router(
            arguments: [String] = CommandLine.arguments,
            environment: [String: String] = ProcessInfo.processInfo.environment
        ) -> PrismediaAppRouter? {
            guard arguments.contains("-prismedia-ui-testing") else { return nil }

            if let modeID = environment["PRISMEDIA_UI_TEST_MODE_ID"],
                let mode = ModeCatalog.all.first(where: { $0.id == modeID })
            {
                let destinationID = environment["PRISMEDIA_UI_TEST_DESTINATION_ID"]
                return PrismediaAppRouter(
                    initialMode: mode,
                    initialDestinationID: destinationID
                )
            }

            guard
                let idValue = environment["PRISMEDIA_UI_TEST_ENTITY_ID"],
                let entityID = UUID(uuidString: idValue),
                let kindValue = environment["PRISMEDIA_UI_TEST_ENTITY_KIND"]
            else { return nil }

            let kind = EntityKind(rawValue: kindValue)
            let mode: AppMode
            let destinationID: String
            switch kind {
            case .collection:
                mode = ModeCatalog.browse
                destinationID = "collections"
            case .movie:
                mode = ModeCatalog.video
                destinationID = "movies"
            case .video:
                mode = ModeCatalog.video
                destinationID = "videos"
            case .videoSeries, .videoSeason:
                mode = ModeCatalog.video
                destinationID = "series"
            case .book:
                mode = ModeCatalog.books
                destinationID = "books"
            case .gallery, .image:
                mode = ModeCatalog.images
                destinationID = "images"
            default:
                return nil
            }

            let router = PrismediaAppRouter(
                initialMode: mode,
                initialDestinationID: destinationID
            )
            let intent: EntityNavigationIntent =
                environment["PRISMEDIA_UI_TEST_START_VIDEO"] == "1"
                ? .playback
                : .detail
            router.setPath(
                [EntityLink(entityID: entityID, kind: kind, intent: intent)],
                for: destinationID
            )
            return router
        }

        static func startsVideoAutomatically(
            arguments: [String] = CommandLine.arguments,
            environment: [String: String] = ProcessInfo.processInfo.environment
        ) -> Bool {
            arguments.contains("-prismedia-ui-testing")
                && environment["PRISMEDIA_UI_TEST_START_VIDEO"] == "1"
        }

        static func pausesVideoPlayback(
            arguments: [String] = CommandLine.arguments,
            environment: [String: String] = ProcessInfo.processInfo.environment
        ) -> Bool {
            arguments.contains("-prismedia-ui-testing")
                && environment["PRISMEDIA_UI_TEST_AUTOPLAY"] == "0"
        }

        static func startsVideoInFullscreen(
            arguments: [String] = CommandLine.arguments,
            environment: [String: String] = ProcessInfo.processInfo.environment
        ) -> Bool {
            arguments.contains("-prismedia-ui-testing")
                && environment["PRISMEDIA_UI_TEST_START_FULLSCREEN"] == "1"
        }

        static func videoSubtitleChoiceID(
            arguments: [String] = CommandLine.arguments,
            environment: [String: String] = ProcessInfo.processInfo.environment
        ) -> String? {
            guard arguments.contains("-prismedia-ui-testing"),
                let subtitleID = environment["PRISMEDIA_UI_TEST_SUBTITLE_ID"],
                !subtitleID.isEmpty
            else { return nil }

            return "sidecar-\(subtitleID)"
        }

        static func videoResumeSeconds(
            arguments: [String] = CommandLine.arguments,
            environment: [String: String] = ProcessInfo.processInfo.environment
        ) -> Double? {
            guard arguments.contains("-prismedia-ui-testing"),
                let value = environment["PRISMEDIA_UI_TEST_VIDEO_RESUME_SECONDS"],
                let seconds = Double(value),
                seconds >= 0
            else { return nil }

            return seconds
        }

        static func tvTabID(
            arguments: [String] = CommandLine.arguments,
            environment: [String: String] = ProcessInfo.processInfo.environment
        ) -> String? {
            guard arguments.contains("-prismedia-ui-testing"),
                let tabID = environment["PRISMEDIA_UI_TEST_TV_TAB_ID"],
                TVAppCatalog.tabs.contains(where: { $0.id == tabID })
            else { return nil }

            return tabID
        }

        static func startsEntityDetailAtBottom(
            arguments: [String] = CommandLine.arguments,
            environment: [String: String] = ProcessInfo.processInfo.environment
        ) -> Bool {
            arguments.contains("-prismedia-ui-testing")
                && environment["PRISMEDIA_UI_TEST_DETAIL_SCROLL_BOTTOM"] == "1"
        }

        static func disablesDashboardHeroAutoAdvance(
            arguments: [String] = CommandLine.arguments,
            environment: [String: String] = ProcessInfo.processInfo.environment
        ) -> Bool {
            arguments.contains("-prismedia-ui-testing")
                && environment["PRISMEDIA_UI_TEST_DISABLE_HERO_AUTO_ADVANCE"] == "1"
        }

        static func usesStep4AdministrationFixtures(
            arguments: [String] = CommandLine.arguments,
            environment: [String: String] = ProcessInfo.processInfo.environment
        ) -> Bool {
            arguments.contains("-prismedia-ui-testing")
                && environment["PRISMEDIA_UI_TEST_STEP4_FIXTURES"] == "1"
        }
    }
#endif
