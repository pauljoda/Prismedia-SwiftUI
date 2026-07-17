#if os(tvOS)
    import AVFoundation
    import AVKit
    import CoreMedia
    import CoreVideo
    import UIKit

    @MainActor
    final class TVVideoDisplayCriteriaCoordinator {
        private var didApplyCriteria = false

        var integration: VideoDisplayCriteriaIntegration {
            VideoDisplayCriteriaIntegration(
                prepare: { [self] metadata in await prepare(metadata) },
                reset: { [self] in reset() }
            )
        }

        private func prepare(_ metadata: VideoPlaybackDisplayMetadata?) async {
            guard let metadata else {
                reset()
                return
            }
            guard let window = playbackWindow else { return }
            let displayManager = window.avDisplayManager
            guard displayManager.isDisplayCriteriaMatchingEnabled else {
                reset()
                return
            }
            guard let formatDescription = makeFormatDescription(for: metadata) else { return }

            let frameRate = Float(metadata.frameRate ?? 24)
            displayManager.preferredDisplayCriteria = AVDisplayCriteria(
                refreshRate: frameRate,
                formatDescription: formatDescription
            )
            didApplyCriteria = true

            #if DEBUG
                let profileLabel = metadata.dolbyVisionProfile.map(String.init) ?? "unknown"
                print(
                    "Video display criteria: range=\(metadata.dynamicRange) "
                        + "rate=\(frameRate) dvProfile=\(profileLabel)"
                )
            #endif

            guard metadata.dynamicRange != .sdr else { return }
            await waitForDisplaySwitch(displayManager)
        }

        private func makeFormatDescription(
            for metadata: VideoPlaybackDisplayMetadata
        ) -> CMVideoFormatDescription? {
            var description: CMVideoFormatDescription?
            let status = CMVideoFormatDescriptionCreate(
                allocator: kCFAllocatorDefault,
                codecType: codecType(for: metadata),
                width: Int32(metadata.width ?? 3_840),
                height: Int32(metadata.height ?? 2_160),
                extensions: colorExtensions(for: metadata),
                formatDescriptionOut: &description
            )
            guard status == noErr else { return nil }
            return description
        }

        private func codecType(
            for metadata: VideoPlaybackDisplayMetadata
        ) -> CMVideoCodecType {
            if metadata.dynamicRange == .dolbyVision {
                return kCMVideoCodecType_DolbyVisionHEVC
            }
            let codec = metadata.codec?.lowercased()
            if codec == "h264" || codec == "avc" {
                return kCMVideoCodecType_H264
            }
            return kCMVideoCodecType_HEVC
        }

        private func colorExtensions(
            for metadata: VideoPlaybackDisplayMetadata
        ) -> CFDictionary? {
            guard metadata.dynamicRange != .sdr else { return nil }
            let transferFunction: CFString =
                metadata.dynamicRange == .hlg
                ? kCVImageBufferTransferFunction_ITU_R_2100_HLG
                : kCVImageBufferTransferFunction_SMPTE_ST_2084_PQ
            return [
                kCMFormatDescriptionExtension_ColorPrimaries: kCVImageBufferColorPrimaries_ITU_R_2020,
                kCMFormatDescriptionExtension_TransferFunction: transferFunction,
                kCMFormatDescriptionExtension_YCbCrMatrix: kCVImageBufferYCbCrMatrix_ITU_R_2020,
            ] as CFDictionary
        }

        private func waitForDisplaySwitch(_ displayManager: AVDisplayManager) async {
            var switchStarted = false
            for _ in 0..<100 {
                guard !Task.isCancelled else { return }
                if displayManager.isDisplayModeSwitchInProgress {
                    switchStarted = true
                    break
                }
                try? await Task.sleep(for: .milliseconds(10))
            }
            guard switchStarted else { return }

            for _ in 0..<40 {
                guard !Task.isCancelled, displayManager.isDisplayModeSwitchInProgress else { return }
                try? await Task.sleep(for: .milliseconds(50))
            }
        }

        private func reset() {
            guard didApplyCriteria else { return }
            playbackWindow?.avDisplayManager.preferredDisplayCriteria = nil
            didApplyCriteria = false
        }

        private var playbackWindow: UIWindow? {
            let windows = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
            return windows.first(where: \.isKeyWindow)
                ?? windows.first(where: { !$0.isHidden })
        }
    }
#endif
