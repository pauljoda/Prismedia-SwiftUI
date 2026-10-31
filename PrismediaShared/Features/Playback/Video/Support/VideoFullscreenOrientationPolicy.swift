/// Whether fullscreen video turns the window to landscape. Only a compact-width
/// iPhone window follows the app's orientation mask: an iPad window, and the
/// regular-width inner display of iPhone Duo, rotate with the device instead.
enum VideoFullscreenOrientationPolicy {
    static func forcesLandscape(isPad: Bool, isCompactWidth: Bool) -> Bool {
        !isPad && isCompactWidth
    }
}
