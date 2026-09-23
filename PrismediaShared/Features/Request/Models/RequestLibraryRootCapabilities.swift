/// Scan settings required to decide whether a library can receive a request kind.
public protocol RequestLibraryRootCapabilities {
    var scanVideos: Bool { get }
    var scanImages: Bool { get }
    var scanAudio: Bool { get }
    var scanBooks: Bool { get }
}

extension RequestLibraryRoot: RequestLibraryRootCapabilities {}
extension AdministrativeLibraryRoot: RequestLibraryRootCapabilities {}
