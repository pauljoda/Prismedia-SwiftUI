import Foundation

/// Decides which exact EPUB location a reader session may persist.
///
/// Readium and the paragraph script report the page a programmatic restore settles on exactly as
/// they report a page the reader turned to. The tracker keeps a restored exact location until the
/// reader moves, accepts a new location only after that movement, and freezes when the reader
/// closes so a late measurement can never replace the closing checkpoint. Platform adapters
/// forward events; the paragraph script remains the source of paragraph geometry.
struct EPUBExactLocationTracker: Sendable {
    // MARK: - Variables

    /// The location the reader last chose, carrying its paragraph anchor when one was measured.
    private(set) var acceptedLocation: String?
    /// The reading-order resource that contains ``acceptedLocation``.
    private(set) var acceptedResourceKey: String?
    /// The navigator location ``acceptedLocation`` was built from, before any paragraph anchor.
    private var acceptedBaseLocation: String?
    private var phase = EPUBExactLocationPhase.following
    private var captureGeneration = 0

    /// Whether the reader closed; a closed tracker ignores every later event.
    var isClosed: Bool {
        phase == .closed
    }

    // MARK: - Actions - Restoring

    /// Starts restoring an exact saved location in `resourceKey`.
    ///
    /// The saved location becomes the accepted location. Positions reported while the paragraph is
    /// being placed, and at the offset where it settles, are programmatic and never replace it.
    /// - Returns: `false` when the location has no paragraph anchor or the tracker is closed.
    @discardableResult
    mutating func beginRestore(of location: String, in resourceKey: String) -> Bool {
        guard !isClosed, let anchor = EPUBParagraphLocator.anchor(from: location) else { return false }
        accept(location, base: nil, in: resourceKey)
        phase = .restoring(resourceKey: resourceKey, anchor: anchor)
        invalidateCaptures()
        return true
    }

    /// The paragraph still waiting to be placed in `resourceKey`, if a restore is in progress there.
    func restoreAnchor(in resourceKey: String) -> EPUBParagraphAnchor? {
        guard case .restoring(let restoringResourceKey, let anchor) = phase,
            restoringResourceKey == resourceKey
        else { return nil }
        return anchor
    }

    /// Records where the restored paragraph landed. Measurements at this offset are the settle.
    mutating func finishRestore(in resourceKey: String, landing: EPUBParagraphViewport) {
        guard restoreAnchor(in: resourceKey) != nil else { return }
        phase = .holding(resourceKey: resourceKey, landing: landing)
    }

    /// Keeps the saved location after the script could not place its paragraph. The next
    /// measurement records the settled offset instead of replacing the saved location.
    mutating func abandonRestore(in resourceKey: String) {
        guard restoreAnchor(in: resourceKey) != nil else { return }
        phase = .holding(resourceKey: resourceKey, landing: nil)
    }

    // MARK: - Actions - Movement

    /// Records touch, pointer, or key input from the reader.
    ///
    /// Input ends a settled hold so the next reported position is accepted. It does not interrupt
    /// a paragraph that is still being placed, because that restore lands on the saved location.
    mutating func recordUserInput() {
        guard case .holding = phase else { return }
        phase = .following
        invalidateCaptures()
    }

    /// Records navigation the reader chose, such as a page button, contents entry, search result,
    /// or link. It supersedes any restore in progress.
    mutating func recordNavigation() {
        guard !isClosed else { return }
        phase = .following
        invalidateCaptures()
    }

    /// Records a position the navigator reported.
    ///
    /// Following the reader, the position is accepted immediately and later enriched by its
    /// paragraph measurement. While a restore is protected, a position in the same resource is
    /// programmatic; a position in another resource means the reader moved.
    /// - Returns: The paragraph measurement to run, or `nil` when the position is ignored.
    mutating func recordLocation(
        _ location: String,
        in resourceKey: String
    ) -> EPUBParagraphCaptureRequest? {
        switch phase {
        case .closed:
            return nil
        case .restoring(let restoringResourceKey, _) where restoringResourceKey == resourceKey:
            return nil
        case .holding(let holdingResourceKey, _) where holdingResourceKey == resourceKey:
            return captureRequest(for: location, in: resourceKey)
        case .following, .restoring, .holding:
            phase = .following
            if location != acceptedBaseLocation || resourceKey != acceptedResourceKey {
                accept(location, base: location, in: resourceKey)
            }
            return captureRequest(for: location, in: resourceKey)
        }
    }

    /// Applies the paragraph the script measured for `request`.
    ///
    /// A failed measurement (`nil`) changes nothing. While a restore is protected, a measurement at
    /// the settled offset is ignored and one at another offset means the reader moved.
    /// - Returns: `true` when the accepted location changed.
    @discardableResult
    mutating func recordCapture(
        _ viewport: EPUBParagraphViewport?,
        for request: EPUBParagraphCaptureRequest
    ) -> Bool {
        guard request.generation == captureGeneration, let viewport else { return false }
        switch phase {
        case .closed, .restoring:
            return false
        case .holding(let resourceKey, let landing):
            guard resourceKey == request.resourceKey else { return false }
            guard let landing else {
                phase = .holding(resourceKey: resourceKey, landing: viewport)
                return false
            }
            guard !viewport.isAtScrollOffset(of: landing) else { return false }
            phase = .following
            return acceptCapture(viewport, for: request)
        case .following:
            return acceptCapture(viewport, for: request)
        }
    }

    // MARK: - Actions - Lifecycle

    /// Freezes the tracker when the reader closes.
    /// - Returns: The location the closing checkpoint saves.
    @discardableResult
    mutating func close() -> String? {
        phase = .closed
        invalidateCaptures()
        return acceptedLocation
    }

    /// Forgets every location for a newly loaded publication. Measurements requested earlier stay stale.
    mutating func reset() {
        acceptedLocation = nil
        acceptedResourceKey = nil
        acceptedBaseLocation = nil
        phase = .following
        invalidateCaptures()
    }

    // MARK: - Mutators

    private mutating func captureRequest(
        for location: String,
        in resourceKey: String
    ) -> EPUBParagraphCaptureRequest {
        captureGeneration &+= 1
        return EPUBParagraphCaptureRequest(
            generation: captureGeneration,
            location: location,
            resourceKey: resourceKey
        )
    }

    private mutating func invalidateCaptures() {
        captureGeneration &+= 1
    }

    private mutating func acceptCapture(
        _ viewport: EPUBParagraphViewport,
        for request: EPUBParagraphCaptureRequest
    ) -> Bool {
        let exactLocation = viewport.anchor.flatMap { EPUBParagraphLocator.enriching(request.location, with: $0) }
        return accept(exactLocation ?? request.location, base: request.location, in: request.resourceKey)
    }

    @discardableResult
    private mutating func accept(_ location: String, base: String?, in resourceKey: String) -> Bool {
        let didChange = location != acceptedLocation || resourceKey != acceptedResourceKey
        acceptedLocation = location
        acceptedResourceKey = resourceKey
        acceptedBaseLocation = base
        return didChange
    }
}
