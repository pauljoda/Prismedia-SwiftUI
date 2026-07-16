import AVFoundation
import XCTest

@testable import PrismediaCore

final class VideoPlaybackRecoveryPolicyTests: XCTestCase {
    func testNetworkFailuresDoNotAttemptMediaCompatibilityFallbacks() {
        XCTAssertFalse(
            VideoPlaybackRecoveryPolicy.shouldAttemptFallback(
                after: URLError(.cannotFindHost)
            )
        )
        XCTAssertFalse(
            VideoPlaybackRecoveryPolicy.shouldAttemptFallback(
                after: NSError(
                    domain: AVFoundationErrorDomain,
                    code: AVError.unknown.rawValue,
                    userInfo: [NSUnderlyingErrorKey: URLError(.timedOut)]
                )
            )
        )
    }

    func testDecodeAndRenderFailuresCanAttemptCompatibilityFallbacks() {
        XCTAssertTrue(VideoPlaybackRecoveryPolicy.shouldAttemptFallback(after: nil))
        XCTAssertTrue(
            VideoPlaybackRecoveryPolicy.shouldAttemptFallback(
                after: NSError(domain: AVFoundationErrorDomain, code: AVError.decoderNotFound.rawValue)
            )
        )
        XCTAssertTrue(
            VideoPlaybackRecoveryPolicy.shouldAttemptFallback(
                after: VideoPlaybackError.videoOutputUnavailable
            )
        )
    }
}
