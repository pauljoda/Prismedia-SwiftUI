import Foundation
import XCTest

@testable import PrismediaCore

final class RequestActivityPresentationPolicyTests: XCTestCase {
    func testUnknownAcquisitionStatusPollsAndLocksActions() {
        let status = AcquisitionStatus(rawValue: "future-state")

        XCTAssertTrue(RequestActivityStatusPolicy.shouldPoll(status))
        XCTAssertTrue(RequestActivityStatusPolicy.isTransitionLocked(status))
        XCTAssertNil(RequestActivityStatusPolicy.primaryAction(for: status, hasEntity: true))
    }

    func testDownloadPrimaryActionMatchesWebLifecycle() {
        XCTAssertEqual(
            RequestActivityStatusPolicy.primaryAction(
                for: AcquisitionStatus(rawValue: "awaiting-selection"),
                hasEntity: true
            ),
            .chooseRelease
        )
        XCTAssertEqual(
            RequestActivityStatusPolicy.primaryAction(
                for: AcquisitionStatus(rawValue: "failed"),
                hasEntity: false
            ),
            .searchAgain
        )
        XCTAssertEqual(
            RequestActivityStatusPolicy.primaryAction(
                for: AcquisitionStatus(rawValue: "downloading"),
                hasEntity: true
            ),
            .view
        )
    }

    func testEntityAcquisitionLifecycleUsesPreparingSearchBeforeIndexerWorkBegins() {
        let status = AcquisitionStatus(rawValue: "pending")

        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.label(for: status),
            "Preparing Search"
        )
        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.content(for: status),
            .preparingSearch
        )
        XCTAssertNil(
            RequestActivityAcquisitionLifecyclePolicy.primaryAction(
                for: status,
                hasResumableImport: false
            )
        )
        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.secondaryActions(
                for: status,
                hasResumableImport: false
            ),
            [.cancel]
        )
    }

    func testEntityAcquisitionLifecycleHidesCancelWhileImporting() {
        let status = AcquisitionStatus(rawValue: "importing")

        XCTAssertNil(
            RequestActivityAcquisitionLifecyclePolicy.primaryAction(
                for: status,
                hasResumableImport: true
            )
        )
        XCTAssertTrue(
            RequestActivityAcquisitionLifecyclePolicy.secondaryActions(
                for: status,
                hasResumableImport: true
            ).isEmpty
        )
    }

    func testEntityAcquisitionLifecycleSplitsFailedRecoveryByDurableImportState() {
        let status = AcquisitionStatus(rawValue: "failed")

        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.primaryAction(
                for: status,
                hasResumableImport: true
            ),
            .retryImport(allowFormatChange: false)
        )
        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.secondaryActions(
                for: status,
                hasResumableImport: true
            ),
            [.startOver]
        )
        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.primaryAction(
                for: status,
                hasResumableImport: false
            ),
            .research
        )
        XCTAssertTrue(
            RequestActivityAcquisitionLifecyclePolicy.secondaryActions(
                for: status,
                hasResumableImport: false
            ).isEmpty
        )
    }

    func testEntityAcquisitionLifecycleRevivesCancelledAttemptWithSearchAgain() {
        let status = AcquisitionStatus(rawValue: "cancelled")

        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.primaryAction(
                for: status,
                hasResumableImport: false
            ),
            .research
        )
        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.content(for: status),
            .lifecycleOnly
        )
    }

    func testEntityAcquisitionLifecycleLeavesAwaitingSelectionToDownstreamControls() {
        let status = AcquisitionStatus(rawValue: "awaiting-selection")

        XCTAssertNil(
            RequestActivityAcquisitionLifecyclePolicy.primaryAction(
                for: status,
                hasResumableImport: false
            )
        )
        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.secondaryActions(
                for: status,
                hasResumableImport: false
            ),
            [.research, .cancel]
        )
        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.content(for: status),
            .releases
        )
    }

    func testEntityAcquisitionRefreshWarningAppearsAfterThreeConsecutiveFailures() {
        var state = RequestActivityAcquisitionRefreshState()

        state.recordFailure()
        state.recordFailure()
        XCTAssertNil(state.message)

        state.recordFailure()
        XCTAssertEqual(
            state.message,
            "Live updates are failing. Prismedia will keep retrying in the background."
        )

        state.recordSuccess()
        XCTAssertNil(state.message)
        XCTAssertEqual(state.consecutiveFailures, 0)
    }

    func testTransferPolicyNormalizesKnownClientStagesAndSettledStates() {
        XCTAssertEqual(RequestActivityTransferPolicy.stageLabel(for: "stalledDL"), "Stalled — looking for peers")
        XCTAssertEqual(RequestActivityTransferPolicy.stageLabel(for: "checking"), "Verifying")
        XCTAssertEqual(RequestActivityTransferPolicy.stageLabel(for: "Extracting"), "Extracting")
        XCTAssertEqual(RequestActivityTransferPolicy.stageLabel(for: "Completed"), "Download complete")
        XCTAssertEqual(RequestActivityTransferPolicy.stageLabel(for: "FutureClientState"), "FutureClientState")

        XCTAssertTrue(RequestActivityTransferPolicy.isActive("downloading"))
        XCTAssertTrue(RequestActivityTransferPolicy.isActive("Extracting"))
        XCTAssertFalse(RequestActivityTransferPolicy.isActive("stalledDL"))
        XCTAssertFalse(RequestActivityTransferPolicy.isActive("pausedDL"))
        XCTAssertFalse(RequestActivityTransferPolicy.isActive("Failed"))
        XCTAssertFalse(RequestActivityTransferPolicy.isActive("Completed"))
        XCTAssertTrue(RequestActivityTransferPolicy.expectsDownloadTelemetry("metaDL"))
        XCTAssertFalse(RequestActivityTransferPolicy.expectsDownloadTelemetry("Extracting"))

        XCTAssertEqual(RequestActivityTransferPolicy.tone(for: "stalledDL"), .attention)
        XCTAssertEqual(RequestActivityTransferPolicy.tone(for: "error"), .failed)
        XCTAssertEqual(RequestActivityTransferPolicy.tone(for: "Completed"), .done)
        XCTAssertEqual(RequestActivityTransferPolicy.tone(for: "queuedDL"), .queued)
    }

    func testTransferPolicySuppressesProtocolZeroesUnlessSwarmTelemetryIsMeaningful() throws {
        let usenet = try transfer(state: "Extracting")
        let torrentWithPieces = try transfer(state: "downloading", pieces: [2, 1, 0])
        let torrentWithoutMetadata = try transfer(state: "metaDL")
        let connectedSwarm = try transfer(state: "downloading", seeds: 3, peers: 1)

        XCTAssertFalse(RequestActivityTransferPolicy.showsSwarmTelemetry(usenet))
        XCTAssertTrue(RequestActivityTransferPolicy.showsSwarmTelemetry(torrentWithPieces))
        XCTAssertTrue(RequestActivityTransferPolicy.showsSwarmTelemetry(torrentWithoutMetadata))
        XCTAssertTrue(RequestActivityTransferPolicy.showsSwarmTelemetry(connectedSwarm))
    }

    func testEntityAcquisitionLifecycleKeepsCompletedAndUnknownStatesReadOnly() {
        let imported = AcquisitionStatus(rawValue: "imported")
        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.content(for: imported),
            .files
        )
        XCTAssertNil(
            RequestActivityAcquisitionLifecyclePolicy.primaryAction(
                for: imported,
                hasResumableImport: false
            )
        )
        XCTAssertTrue(
            RequestActivityAcquisitionLifecyclePolicy.secondaryActions(
                for: imported,
                hasResumableImport: false
            ).isEmpty
        )

        let unknown = AcquisitionStatus(rawValue: "future-state")
        XCTAssertEqual(
            RequestActivityAcquisitionLifecyclePolicy.content(for: unknown),
            .locked
        )
        XCTAssertNil(
            RequestActivityAcquisitionLifecyclePolicy.primaryAction(
                for: unknown,
                hasResumableImport: true
            )
        )
        XCTAssertTrue(
            RequestActivityAcquisitionLifecyclePolicy.secondaryActions(
                for: unknown,
                hasResumableImport: true
            ).isEmpty
        )
    }

    func testWantedTransitionsFailClosed() {
        XCTAssertTrue(
            RequestActivityWantedPolicy.isTransitionLocked(
                monitorStatus: .deletingFiles,
                acquisitionStatus: nil
            ))
        XCTAssertTrue(
            RequestActivityWantedPolicy.isTransitionLocked(
                monitorStatus: .active,
                acquisitionStatus: AcquisitionStatus(rawValue: "future-state")
            ))
        XCTAssertFalse(
            RequestActivityWantedPolicy.isTransitionLocked(
                monitorStatus: .active,
                acquisitionStatus: AcquisitionStatus(rawValue: "searching")
            ))
    }

    func testReleaseDispositionSeparatesOverridesFromHardRejections() throws {
        let eligible = try candidate(id: 1, accepted: true)
        let overridable = try candidate(id: 2, rejections: ["below-cutoff"])
        let unavailable = try candidate(id: 3, rejections: ["wrong-protocol"])
        let blocked = try candidate(id: 4, accepted: true, rejections: ["blocklisted"])

        XCTAssertEqual(RequestActivityReleasePolicy.disposition(of: eligible), .eligible)
        XCTAssertEqual(RequestActivityReleasePolicy.disposition(of: overridable), .overridable)
        XCTAssertEqual(RequestActivityReleasePolicy.disposition(of: unavailable), .unavailable)
        XCTAssertEqual(RequestActivityReleasePolicy.disposition(of: blocked), .blocklisted)
        XCTAssertTrue(RequestActivityReleasePolicy.canManuallyQueue(eligible))
        XCTAssertTrue(RequestActivityReleasePolicy.canManuallyQueue(overridable))
        XCTAssertFalse(RequestActivityReleasePolicy.canManuallyQueue(unavailable))
        XCTAssertFalse(RequestActivityReleasePolicy.canManuallyQueue(blocked))
    }

    func testEveryHardReleaseRejectionPreventsManualDownload() throws {
        for (index, rejection) in [
            "unsupported-format",
            "wrong-protocol",
            "no-download-link",
            "dangerous-content",
        ].enumerated() {
            let release = try candidate(id: index + 10, rejections: [rejection])
            XCTAssertEqual(RequestActivityReleasePolicy.disposition(of: release), .unavailable)
            XCTAssertFalse(RequestActivityReleasePolicy.canManuallyQueue(release))
        }
    }

    func testRelevantReleaseFilterPrefersEligibleAndHidesBlocked() throws {
        let eligible = try candidate(id: 20, accepted: true)
        let overridable = try candidate(id: 21, rejections: ["below-cutoff"])
        let unavailable = try candidate(id: 22, rejections: ["no-download-link"])
        let blocked = try candidate(id: 23, accepted: true, rejections: ["blocklisted"])
        let candidates = [eligible, overridable, unavailable, blocked]

        XCTAssertEqual(
            RequestActivityReleasePolicy.filteredCandidates(
                candidates,
                showsOnlyRelevant: true
            ),
            [eligible]
        )
        XCTAssertEqual(
            RequestActivityReleasePolicy.filteredCandidates(
                candidates,
                showsOnlyRelevant: false
            ),
            candidates
        )
    }

    func testRelevantReleaseFilterFallsBackAfterLastEligibleIsBlocked() throws {
        let blockedLastEligible = try candidate(
            id: 30,
            accepted: true,
            rejections: ["blocklisted"]
        )
        let overridable = try candidate(id: 31, rejections: ["below-cutoff"])
        let unavailable = try candidate(id: 32, rejections: ["unsupported-format"])

        XCTAssertEqual(
            RequestActivityReleasePolicy.filteredCandidates(
                [blockedLastEligible, overridable, unavailable],
                showsOnlyRelevant: true
            ),
            [overridable, unavailable]
        )
    }

    func testReleaseSortingSupportsEveryPickerColumn() throws {
        let beta = try candidate(
            id: 40,
            title: "Beta",
            indexer: "Zulu",
            sizeBytes: 200,
            seeders: 1
        )
        let alpha = try candidate(
            id: 41,
            title: "Alpha",
            indexer: "Able",
            sizeBytes: 100,
            seeders: 3
        )
        let candidates = [beta, alpha]

        XCTAssertEqual(RequestActivityReleasePolicy.sortedCandidates(candidates, by: .bestMatch), candidates)
        XCTAssertEqual(
            RequestActivityReleasePolicy.sortedCandidates(candidates, by: .seedersDescending), [alpha, beta])
        XCTAssertEqual(RequestActivityReleasePolicy.sortedCandidates(candidates, by: .seedersAscending), [beta, alpha])
        XCTAssertEqual(RequestActivityReleasePolicy.sortedCandidates(candidates, by: .sizeDescending), [beta, alpha])
        XCTAssertEqual(RequestActivityReleasePolicy.sortedCandidates(candidates, by: .sizeAscending), [alpha, beta])
        XCTAssertEqual(RequestActivityReleasePolicy.sortedCandidates(candidates, by: .titleAscending), [alpha, beta])
        XCTAssertEqual(RequestActivityReleasePolicy.sortedCandidates(candidates, by: .titleDescending), [beta, alpha])
        XCTAssertEqual(RequestActivityReleasePolicy.sortedCandidates(candidates, by: .indexerAscending), [alpha, beta])
        XCTAssertEqual(
            RequestActivityReleasePolicy.sortedCandidates(candidates, by: .indexerDescending), [beta, alpha])
    }

    func testReleaseTitleCategoryAndProtocolLabelsAreCleaned() throws {
        let categorized = try candidate(
            id: 50,
            title: "  Dune   Retail EPUB  »  Books / Ebook ",
            protocolName: "soulseek"
        )
        let future = try candidate(id: 51, protocolName: "future-transfer")

        XCTAssertEqual(RequestActivityReleasePolicy.displayTitle(for: categorized), "Dune Retail EPUB")
        XCTAssertEqual(RequestActivityReleasePolicy.category(for: categorized), "Books / Ebook")
        XCTAssertEqual(RequestActivityReleasePolicy.categorySystemImage(for: "Books / Ebook"), "book.closed")
        XCTAssertEqual(RequestActivityReleasePolicy.protocolLabel(for: categorized), "Soulseek")
        XCTAssertEqual(RequestActivityReleasePolicy.protocolLabel(for: future), "Future Transfer")
    }

    func testReleasePageRequiresHTTPOrHTTPS() throws {
        let web = try candidate(id: 60, infoURL: "https://example.com/release")
        let local = try candidate(id: 61, infoURL: "file:///tmp/release")

        XCTAssertEqual(
            RequestActivityReleasePolicy.validInfoURL(for: web)?.absoluteString,
            "https://example.com/release"
        )
        XCTAssertNil(RequestActivityReleasePolicy.validInfoURL(for: local))
    }

    func testReleasePickerVisibilityMatchesRecoverableLifecycleStates() {
        XCTAssertTrue(showsReleasePicker(status: "awaiting-selection", hasCandidates: false))
        XCTAssertTrue(showsReleasePicker(status: "manual-import-required", hasCandidates: false))
        XCTAssertTrue(showsReleasePicker(status: "failed", hasCandidates: true))
        XCTAssertFalse(
            showsReleasePicker(
                status: "failed",
                hasResumableImport: true,
                hasCandidates: true
            )
        )
        XCTAssertTrue(showsReleasePicker(status: "cancelled", hasCandidates: true))
        XCTAssertFalse(showsReleasePicker(status: "cancelled", hasCandidates: false))
        XCTAssertFalse(showsReleasePicker(status: "searching", hasCandidates: true))
        XCTAssertFalse(showsReleasePicker(status: "future-state", hasCandidates: true))
    }

    private func showsReleasePicker(
        status: String,
        hasResumableImport: Bool = false,
        hasCandidates: Bool
    ) -> Bool {
        RequestActivityAcquisitionLifecyclePolicy.showsReleasePicker(
            for: AcquisitionStatus(rawValue: status),
            hasResumableImport: hasResumableImport,
            hasCandidates: hasCandidates
        )
    }

    private func candidate(
        id: Int,
        title: String = "Release",
        indexer: String = "Indexer",
        sizeBytes: Int64 = 1_000,
        seeders: Int? = 1,
        protocolName: String = "torrent",
        accepted: Bool = false,
        score: Double = 50,
        rejections: [String] = [],
        infoURL: String? = nil
    ) throws -> RequestActivityReleaseCandidate {
        var json: [String: Any] = [
            "id": String(format: "00000000-0000-0000-0000-%012d", id),
            "indexerName": indexer,
            "title": title,
            "sizeBytes": sizeBytes,
            "protocol": protocolName,
            "accepted": accepted,
            "score": score,
            "rejections": rejections,
        ]
        if let seeders { json["seeders"] = seeders }
        if let infoURL { json["infoUrl"] = infoURL }
        let data = try JSONSerialization.data(withJSONObject: json)
        return try PrismediaJSON.decoder().decode(RequestActivityReleaseCandidate.self, from: data)
    }

    private func transfer(
        state: String,
        seeds: Int = 0,
        peers: Int = 0,
        pieces: [Int] = []
    ) throws -> RequestActivityTransfer {
        let json: [String: Any] = [
            "progress": 0.5,
            "state": state,
            "totalSizeBytes": 1_000,
            "downloadSpeedBytesPerSecond": 0,
            "etaSeconds": 0,
            "seeds": seeds,
            "peers": peers,
            "savePath": NSNull(),
            "pieceStates": pieces,
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        return try PrismediaJSON.decoder().decode(RequestActivityTransfer.self, from: data)
    }

}
