import Foundation

@MainActor
public protocol AudioPlaybackEngine: AnyObject {
    func load(url: URL)
    func play()
    func pause()
    func seek(to seconds: Double)
    func setPlaybackRate(_ rate: Float)
}
