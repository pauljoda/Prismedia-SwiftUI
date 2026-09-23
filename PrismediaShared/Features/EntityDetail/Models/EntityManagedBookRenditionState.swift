/// User-visible lifecycle of one externally managed Book format.
enum EntityManagedBookRenditionState: Equatable {
    case starting
    case waitingForFiles
    case tracking
    case completed
    case needsReview
    case releasing
    case released
    case cancelled
    case updating
}
