import Foundation
import Testing

@testable import PrismediaCore

struct MusicWaveformTests {
    @Test
    func decodingReadsGeneratedEnvelopeData() throws {
        let waveform = try JSONDecoder().decode(
            MusicWaveform.self,
            from: Data(#"{"data":[-0.2,0.4,-0.7,0.8]}"#.utf8)
        )

        #expect(waveform.samples == [-0.2, 0.4, -0.7, 0.8])
        #expect(waveform.pairCount == 2)
    }

    @Test
    func oversizedEnvelopePreservesBucketExtremes() {
        let pairCount = MusicWaveform.maximumDisplayPairCount * 2
        let input = (0..<pairCount).flatMap { index -> [Double] in
            index == pairCount - 1 ? [-1, 0.95] : [-0.1, 0.2]
        }

        let waveform = MusicWaveform(samples: input)

        #expect(waveform.pairCount == MusicWaveform.maximumDisplayPairCount)
        #expect(waveform.samples.suffix(2) == [-1, 0.95])
    }

    #if os(macOS)
        @Test
        func playbackPositionInterpolatesBetweenEngineUpdates() {
            let anchorDate = Date(timeIntervalSinceReferenceDate: 100)
            var anchor = MacMusicPlaybackPositionAnchor()
            anchor.synchronize(to: 12, at: anchorDate)

            let position = anchor.position(
                at: anchorDate.addingTimeInterval(0.25),
                isPlaying: true,
                playbackRate: 1,
                duration: 60
            )

            #expect(position == 12.25)
        }

        @Test
        func playbackPositionStopsAndClampsAtDuration() {
            let anchorDate = Date(timeIntervalSinceReferenceDate: 100)
            var anchor = MacMusicPlaybackPositionAnchor()
            anchor.synchronize(to: 59.5, at: anchorDate)

            #expect(
                anchor.position(
                    at: anchorDate.addingTimeInterval(4),
                    isPlaying: true,
                    playbackRate: 2,
                    duration: 60
                ) == 60
            )
            #expect(
                anchor.position(
                    at: anchorDate.addingTimeInterval(4),
                    isPlaying: false,
                    playbackRate: 2,
                    duration: 60
                ) == 59.5
            )
        }
    #endif
}
