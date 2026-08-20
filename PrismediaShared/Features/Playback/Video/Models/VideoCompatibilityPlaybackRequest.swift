import Foundation

struct VideoCompatibilityPlaybackRequest: Equatable, Sendable {
    let url: URL
    let resumeTime: Double
    let playbackRate: Float
    let audioStreams: [VideoPlaybackStreamChoice]
    let dolbyVisionProfile: Int?
    let networkCachingSeconds: Int
    let httpHeaders: [String: String]

    var httpBearerToken: String? {
        guard
            let authorization = httpHeaders.first(where: {
                $0.key.caseInsensitiveCompare("Authorization") == .orderedSame
            })?.value
        else { return nil }

        let fields = authorization.split(
            maxSplits: 1,
            omittingEmptySubsequences: true,
            whereSeparator: \.isWhitespace
        )
        guard fields.count == 2,
            fields[0].caseInsensitiveCompare("Bearer") == .orderedSame,
            !fields[1].isEmpty
        else { return nil }
        return String(fields[1])
    }

    init(
        url: URL,
        resumeTime: Double,
        playbackRate: Float,
        audioStreams: [VideoPlaybackStreamChoice],
        dolbyVisionProfile: Int?,
        networkCachingSeconds: Int = VLCNetworkCachingSettings.defaultSeconds,
        httpHeaders: [String: String] = [:]
    ) {
        self.url = url
        self.resumeTime = resumeTime
        self.playbackRate = playbackRate
        self.audioStreams = audioStreams
        self.dolbyVisionProfile = dolbyVisionProfile
        self.networkCachingSeconds = VLCNetworkCachingSettings.normalizedSeconds(
            networkCachingSeconds
        )
        self.httpHeaders = httpHeaders
    }

    func replacingResumeTime(_ resumeTime: Double) -> Self {
        Self(
            url: url,
            resumeTime: resumeTime,
            playbackRate: playbackRate,
            audioStreams: audioStreams,
            dolbyVisionProfile: dolbyVisionProfile,
            networkCachingSeconds: networkCachingSeconds,
            httpHeaders: httpHeaders
        )
    }
}
