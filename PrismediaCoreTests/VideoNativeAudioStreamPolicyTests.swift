import XCTest

@testable import PrismediaCore

final class VideoNativeAudioStreamPolicyTests: XCTestCase {
    func testPrefersEAC3SurroundInTheSelectedLanguage() {
        let streams = [
            audioStream(index: 1, codec: "truehd", channels: 8, isDefault: true, language: "eng"),
            audioStream(index: 2, codec: "ac3", channels: 6, language: "eng"),
            audioStream(index: 3, codec: "eac3", channels: 8, language: "eng"),
        ]

        XCTAssertEqual(
            VideoNativeAudioStreamPolicy.preferredStreamIndex(
                container: "mkv",
                streams: streams
            ),
            3
        )
    }

    func testNeverChoosesStereoAsASurroundFallback() {
        let streams = [
            audioStream(index: 1, codec: "truehd", channels: 8, isDefault: true, language: "eng"),
            audioStream(index: 2, codec: "eac3", channels: 2, language: "eng"),
        ]

        XCTAssertNil(
            VideoNativeAudioStreamPolicy.preferredStreamIndex(
                container: "mkv",
                streams: streams
            )
        )
    }

    func testNeverChangesLanguageToReachANativeSurroundCodec() {
        let streams = [
            audioStream(index: 1, codec: "truehd", channels: 8, isDefault: true, language: "eng"),
            audioStream(index: 2, codec: "eac3", channels: 8, language: "jpn"),
        ]

        XCTAssertNil(
            VideoNativeAudioStreamPolicy.preferredStreamIndex(
                container: "mkv",
                streams: streams
            )
        )
    }

    func testNeverRedirectsAnAlreadyNativeContainer() {
        XCTAssertNil(
            VideoNativeAudioStreamPolicy.preferredStreamIndex(
                container: "mp4",
                streams: [
                    audioStream(index: 1, codec: "eac3", channels: 8, isDefault: true)
                ]
            )
        )
    }

    private func audioStream(
        index: Int,
        codec: String,
        channels: Int,
        isDefault: Bool = false,
        language: String? = nil
    ) -> VideoPlaybackStream {
        VideoPlaybackStream(
            index: index,
            type: PrismediaContractCodes.StreamKind.audio,
            codec: codec,
            width: nil,
            height: nil,
            averageFrameRate: nil,
            channels: channels,
            isDefault: isDefault,
            videoRangeType: nil,
            colorTransfer: nil,
            dolbyVisionProfile: nil,
            bitDepth: nil,
            language: language,
            displayTitle: nil
        )
    }
}
