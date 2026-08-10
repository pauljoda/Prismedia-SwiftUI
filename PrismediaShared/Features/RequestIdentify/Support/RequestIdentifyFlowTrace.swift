import Foundation
import OSLog

#if os(iOS) || os(macOS)
    enum RequestIdentifyFlowTrace {
        private static let logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "Prismedia",
            category: "RequestIdentifyFlow"
        )

        static func record(
            mode: RequestIdentifyFlowMode,
            phase: RequestIdentifyFlowPhase,
            reviewDepth: Int
        ) {
            let modeName = String(describing: mode)
            let phaseName = String(describing: phase)
            logger.info(
                "mode=\(modeName, privacy: .public) phase=\(phaseName, privacy: .public) reviewDepth=\(reviewDepth, privacy: .public)"
            )
        }
    }
#endif
