// AUTO-GENERATED from Prismedia's backend code-registry manifest.
// Do not edit by hand. Run `python3 Scripts/generate-contract-codes.py`.

import Foundation

/// Complete generated snapshot of backend closed-set wire identifiers.
public enum PrismediaContractCodes {
    public enum AcquisitionCheckpointProtocol {
        public static let `placement` = "placement"
        public static let `television` = "television"
    }

    public enum AcquisitionHistoryEvent {
        public static let `grabbed` = "grabbed"
        public static let `imported` = "imported"
        public static let `importFailed` = "import-failed"
        public static let `downloadFailed` = "download-failed"
        public static let `blocklisted` = "blocklisted"
        public static let `upgraded` = "upgraded"
        public static let `removed` = "removed"
    }

    public enum AcquisitionImportContentKind {
        public static let `book` = "book"
        public static let `audio` = "audio"
        public static let `video` = "video"
        public static let `image` = "image"
        public static let `subtitle` = "subtitle"
        public static let `archive` = "archive"
        public static let `other` = "other"
    }

    public enum AcquisitionImportDecision {
        public static let `placeNew` = "place-new"
        public static let `replaceUpgrade` = "replace-upgrade"
        public static let `adoptExisting` = "adopt-existing"
        public static let `skipExisting` = "skip-existing"
        public static let `skipNotUpgrade` = "skip-not-upgrade"
        public static let `holdFormatChange` = "hold-format-change"
        public static let `holdStructuralConflict` = "hold-structural-conflict"
        public static let `unsupported` = "unsupported"
        public static let `ambiguous` = "ambiguous"
    }

    public enum AcquisitionImportFileRole {
        public static let `media` = "media"
        public static let `companion` = "companion"
        public static let `unknown` = "unknown"
    }

    public enum AcquisitionImportFileStatus {
        public static let `downloaded` = "downloaded"
        public static let `pendingImport` = "pending-import"
        public static let `importing` = "importing"
        public static let `imported` = "imported"
        public static let `skipped` = "skipped"
        public static let `failed` = "failed"
    }

    public enum AcquisitionImportPhase {
        public static let `downloading` = "downloading"
        public static let `downloaded` = "downloaded"
        public static let `importing` = "importing"
        public static let `imported` = "imported"
    }

    public enum AcquisitionNamingFamily {
        public static let `book` = "book"
        public static let `movie` = "movie"
        public static let `television` = "television"
        public static let `music` = "music"
    }

    public enum AcquisitionStatus {
        public static let `pending` = "pending"
        public static let `waitingForRelease` = "waiting-for-release"
        public static let `manualSearchRequired` = "manual-search-required"
        public static let `searching` = "searching"
        public static let `awaitingSelection` = "awaiting-selection"
        public static let `queued` = "queued"
        public static let `downloading` = "downloading"
        public static let `waitingForDownloadClient` = "waiting-for-download-client"
        public static let `downloaded` = "downloaded"
        public static let `importing` = "importing"
        public static let `imported` = "imported"
        public static let `stopping` = "stopping"
        public static let `failed` = "failed"
        public static let `cancelled` = "cancelled"
        public static let `manualImportRequired` = "manual-import-required"
    }

    public enum AcquisitionTeardownIntent {
        public static let `remove` = "remove"
        public static let `reacquire` = "reacquire"
    }

    public enum AudioQuality {
        public static let `unknown` = "unknown"
        public static let `lossy` = "lossy"
        public static let `lossyHigh` = "lossy-high"
        public static let `lossless` = "lossless"
        public static let `losslessHiRes` = "lossless-hires"
    }

    public enum AutoIdentifySelectorKind {
        public static let `video` = "video"
        public static let `gallery` = "gallery"
        public static let `image` = "image"
        public static let `audio` = "audio"
        public static let `book` = "book"
    }

    public enum BlocklistReason {
        public static let `failed` = "failed"
        public static let `stalled` = "stalled"
        public static let `noImportableFiles` = "no-importable-files"
        public static let `manual` = "manual"
        public static let `wrongContent` = "wrong-content"
    }

    public enum BookFormat {
        public static let `imageArchive` = "image-archive"
        public static let `epub` = "epub"
        public static let `pdf` = "pdf"
        public static let `audio` = "audio"
    }

    public enum BookFormatTier {
        public static let `unknown` = "unknown"
        public static let `fixed` = "fixed"
        public static let `reflowable` = "reflowable"
        public static let `archive` = "archive"
    }

    public enum BookRendition {
        public static let `ebook` = "ebook"
        public static let `audiobook` = "audiobook"
    }

    public enum BookSourceTier {
        public static let `unknown` = "unknown"
        public static let `web` = "web"
        public static let `retail` = "retail"
    }

    public enum BookType {
        public static let `book` = "book"
        public static let `comic` = "comic"
        public static let `manga` = "manga"
        public static let `novel` = "novel"
    }

    public enum CollectionCoverMode {
        public static let `mosaic` = "mosaic"
        public static let `custom` = "custom"
        public static let `item` = "item"
    }

    public enum CollectionItemSource {
        public static let `manual` = "manual"
        public static let `dynamic` = "dynamic"
    }

    public enum CollectionMode {
        public static let `manual` = "manual"
        public static let `dynamic` = "dynamic"
        public static let `hybrid` = "hybrid"
    }

    public enum CollectionRuleField {
        public static let `title` = "title"
        public static let `rating` = "rating"
        public static let `date` = "date"
        public static let `organized` = "organized"
        public static let `isNsfw` = "isNsfw"
        public static let `tags` = "tags"
        public static let `performers` = "performers"
        public static let `studio` = "studio"
        public static let `libraryRootId` = "libraryRootId"
        public static let `fileSize` = "fileSize"
        public static let `duration` = "duration"
        public static let `height` = "height"
        public static let `width` = "width"
        public static let `codec` = "codec"
        public static let `bitRate` = "bitRate"
        public static let `bitRateLegacy` = "bit_rate"
        public static let `channels` = "channels"
        public static let `sampleRate` = "sampleRate"
        public static let `sampleRateLegacy` = "sample_rate"
        public static let `accessCount` = "accessCount"
        public static let `skipCount` = "skipCount"
        public static let `resolution` = "resolution"
        public static let `videoSeriesId` = "videoSeriesId"
        public static let `galleryType` = "galleryType"
        public static let `imageCount` = "imageCount"
        public static let `format` = "format"
        public static let `createdAt` = "createdAt"
        public static let `interactive` = "interactive"
    }

    public enum CollectionRuleGroupOperator {
        public static let `and` = "and"
        public static let `or` = "or"
        public static let `not` = "not"
    }

    public enum CollectionRuleOperator {
        public static let `equals` = "equals"
        public static let `notEquals` = "not_equals"
        public static let `contains` = "contains"
        public static let `notContains` = "not_contains"
        public static let `greaterThan` = "greater_than"
        public static let `lessThan` = "less_than"
        public static let `greaterEqual` = "greater_equal"
        public static let `lessEqual` = "less_equal"
        public static let `between` = "between"
        public static let `in` = "in"
        public static let `notIn` = "not_in"
        public static let `isNull` = "is_null"
        public static let `isNotNull` = "is_not_null"
        public static let `isTrue` = "is_true"
        public static let `isFalse` = "is_false"
    }

    public enum ConsumptionActivityKind {
        public static let `viewing` = "viewing"
        public static let `listening` = "listening"
        public static let `reading` = "reading"
    }

    public enum ConsumptionEventKind {
        public static let `accessed` = "accessed"
        public static let `completed` = "completed"
        public static let `skipped` = "skipped"
    }

    public enum CreditRole {
        public static let `person` = "person"
        public static let `actor` = "actor"
        public static let `director` = "director"
        public static let `writer` = "writer"
        public static let `producer` = "producer"
        public static let `creator` = "creator"
        public static let `artist` = "artist"
        public static let `narrator` = "narrator"
        public static let `composer` = "composer"
    }

    public enum CustomFormatConditionType {
        public static let `releaseTitle` = "release-title"
        public static let `releaseGroup` = "release-group"
        public static let `language` = "language"
        public static let `quality` = "quality"
    }

    public enum DatabaseBackupStatus {
        public static let `running` = "running"
        public static let `completed` = "completed"
        public static let `failed` = "failed"
    }

    public enum DatePrecision {
        public static let `day` = "day"
        public static let `month` = "month"
        public static let `year` = "year"
    }

    public enum DownloadClientKind {
        public static let `qBittorrent` = "qbittorrent"
        public static let `transmission` = "transmission"
        public static let `sabnzbd` = "sabnzbd"
        public static let `slskd` = "slskd"
    }

    public enum DownloadProtocol {
        public static let `torrent` = "torrent"
        public static let `usenet` = "usenet"
        public static let `soulseek` = "soulseek"
    }

    public enum EntityAccentHue {
        public static let `red` = "red"
        public static let `orange` = "orange"
        public static let `yellow` = "yellow"
        public static let `green` = "green"
        public static let `cyan` = "cyan"
        public static let `blue` = "blue"
        public static let `violet` = "violet"
        public static let `magenta` = "magenta"
    }

    public enum EntityArtworkFit {
        public static let `cover` = "cover"
        public static let `contain` = "contain"
    }

    public enum EntityDateType {
        public static let `announcement` = "announcement"
        public static let `premiere` = "premiere"
        public static let `theatricalRelease` = "theatrical-release"
        public static let `streamingRelease` = "streaming-release"
        public static let `digitalRelease` = "digital-release"
        public static let `physicalRelease` = "physical-release"
        public static let `air` = "air"
        public static let `firstAir` = "first-air"
        public static let `lastAir` = "last-air"
        public static let `publication` = "publication"
        public static let `release` = "release"
        public static let `birth` = "birth"
        public static let `death` = "death"
        public static let `careerStart` = "career-start"
        public static let `careerEnd` = "career-end"
    }

    public enum EntityEngagementMode {
        public static let `none` = "none"
        public static let `playback` = "playback"
        public static let `reading` = "reading"
    }

    public enum EntityFileRole {
        public static let `source` = "source"
        public static let `thumbnail` = "thumbnail"
        public static let `gridThumbnail` = "grid-thumbnail"
        public static let `gridThumbnail2x` = "grid-thumbnail-2x"
        public static let `poster` = "poster"
        public static let `backdrop` = "backdrop"
        public static let `logo` = "logo"
        public static let `preview` = "preview"
        public static let `sprite` = "sprite"
        public static let `trickplay` = "trickplay"
        public static let `waveform` = "waveform"
        public static let `cover` = "cover"
        public static let `hls` = "hls"
    }

    public enum EntityKind {
        public static let `audio` = "audio"
        public static let `audioLibrary` = "audio-library"
        public static let `audioTrack` = "audio-track"
        public static let `book` = "book"
        public static let `bookVolume` = "book-volume"
        public static let `bookChapter` = "book-chapter"
        public static let `bookPage` = "book-page"
        public static let `collection` = "collection"
        public static let `gallery` = "gallery"
        public static let `image` = "image"
        public static let `musicArtist` = "music-artist"
        public static let `bookAuthor` = "book-author"
        public static let `person` = "person"
        public static let `movie` = "movie"
        public static let `studio` = "studio"
        public static let `tag` = "tag"
        public static let `video` = "video"
        public static let `videoEpisode` = "video-episode"
        public static let `videoSeries` = "video-series"
        public static let `videoSeason` = "video-season"
    }

    public enum EntityKindIcon {
        public static let `album` = "album"
        public static let `artist` = "artist"
        public static let `audio` = "audio"
        public static let `author` = "author"
        public static let `book` = "book"
        public static let `chapter` = "chapter"
        public static let `collection` = "collection"
        public static let `gallery` = "gallery"
        public static let `image` = "image"
        public static let `movie` = "movie"
        public static let `page` = "page"
        public static let `person` = "person"
        public static let `season` = "season"
        public static let `series` = "series"
        public static let `studio` = "studio"
        public static let `tag` = "tag"
        public static let `track` = "track"
        public static let `video` = "video"
        public static let `volume` = "volume"
    }

    public enum EntityLifecycleClaimKind {
        public static let `deletingFiles` = "deleting-files"
    }

    public enum EntityListSort {
        public static let `title` = "title"
        public static let `dateAdded` = "date-added"
        public static let `rating` = "rating"
        public static let `random` = "random"
        public static let `lastActive` = "last-active"
        public static let `references` = "references"
    }

    public enum EntityMediaQualityFamily {
        public static let `none` = "none"
        public static let `video` = "video"
        public static let `audio` = "audio"
    }

    public enum EntitySortDirection {
        public static let `ascending` = "asc"
        public static let `descending` = "desc"
    }

    public enum EntitySourceCode {
        public static let `folder` = "folder"
    }

    public enum EntityStorageShape {
        public static let `none` = "none"
        public static let `folder` = "folder"
        public static let `file` = "file"
        public static let `archive` = "archive"
        public static let `archiveEntry` = "archive-entry"
    }

    public enum EntitySubtitleSource {
        public static let `manual` = "manual"
        public static let `embedded` = "embedded"
        public static let `generated` = "generated"
        public static let `provider` = "provider"
        public static let `upload` = "upload"
        public static let `sidecar` = "sidecar"
    }

    public enum FileEntryKind {
        public static let `directory` = "directory"
        public static let `file` = "file"
    }

    public enum FileSourceKind {
        public static let `scan` = "scan"
        public static let `custom` = "custom"
    }

    public enum FingerprintAlgorithm {
        public static let `md5` = "md5"
        public static let `oshash` = "oshash"
    }

    public enum FingerprintSubmissionStatus {
        public static let `success` = "success"
        public static let `error` = "error"
    }

    public enum GalleryType {
        public static let `virtual` = "virtual"
        public static let `folder` = "folder"
        public static let `zip` = "zip"
    }

    public enum GeneratedAssetFamily {
        public static let `none` = "none"
        public static let `video` = "video"
        public static let `image` = "image"
        public static let `bookPage` = "book-page"
        public static let `audioTrack` = "audio-track"
    }

    public enum IdentifyAction {
        public static let `search` = "search"
        public static let `lookupId` = "lookup-id"
        public static let `lookupUrl` = "lookup-url"
    }

    public enum IdentifyApplyState {
        public static let `running` = "running"
        public static let `succeeded` = "succeeded"
        public static let `failed` = "failed"
    }

    public enum IdentifyQueueState {
        public static let `search` = "search"
        public static let `queued` = "queued"
        public static let `searching` = "searching"
        public static let `proposal` = "proposal"
        public static let `applying` = "applying"
        public static let `done` = "done"
        public static let `deleted` = "deleted"
        public static let `error` = "error"
    }

    public enum IdentifyResultKind {
        public static let `proposal` = "proposal"
        public static let `candidates` = "candidates"
    }

    public enum IdentifyResultStatus {
        public static let `pending` = "pending"
        public static let `applied` = "applied"
        public static let `rejected` = "rejected"
        public static let `failed` = "failed"
    }

    public enum ImportMode {
        public static let `move` = "move"
        public static let `copy` = "copy"
        public static let `hardlink` = "hardlink"
    }

    public enum IndexerKind {
        public static let `prowlarr` = "prowlarr"
        public static let `jackett` = "jackett"
        public static let `torznab` = "torznab"
        public static let `newznab` = "newznab"
        public static let `slskd` = "slskd"
    }

    public enum JobGraphOrigin {
        public static let `background` = "background"
        public static let `interactive` = "interactive"
    }

    public enum JobGraphSignalKind {
        public static let `identifyReview` = "identify-review"
        public static let `externalTransfer` = "external-transfer"
        public static let `domainEvent` = "domain-event"
    }

    public enum JobGraphStatus {
        public static let `queued` = "queued"
        public static let `running` = "running"
        public static let `waiting` = "waiting"
        public static let `completed` = "completed"
        public static let `completedWithWarnings` = "completed-with-warnings"
        public static let `failed` = "failed"
        public static let `cancelled` = "cancelled"
    }

    public enum JobNodeImportance {
        public static let `required` = "required"
        public static let `bestEffort` = "best-effort"
    }

    public enum JobResourceClass {
        public static let `light` = "light"
        public static let `standardCpu` = "standard-cpu"
        public static let `heavyCpu` = "heavy-cpu"
    }

    public enum JobRunStatus {
        public static let `queued` = "queued"
        public static let `running` = "running"
        public static let `completed` = "completed"
        public static let `failed` = "failed"
        public static let `cancelled` = "cancelled"
    }

    public enum JobType {
        public static let `noop` = "noop"
        public static let `scanLibrary` = "scan-library"
        public static let `scanGallery` = "scan-gallery"
        public static let `scanBook` = "scan-book"
        public static let `scanAudio` = "scan-audio"
        public static let `reconcileEntity` = "reconcile-entity"
        public static let `probeVideo` = "probe-video"
        public static let `probeAudio` = "probe-audio"
        public static let `fingerprintVideo` = "fingerprint-video"
        public static let `fingerprintImage` = "fingerprint-image"
        public static let `fingerprintAudio` = "fingerprint-audio"
        public static let `generatePreview` = "generate-preview"
        public static let `generateImageThumbnail` = "generate-image-thumbnail"
        public static let `generateGridThumbnail` = "generate-grid-thumbnail"
        public static let `gridThumbnailSweep` = "grid-thumbnail-sweep"
        public static let `generateBookPageThumbnail` = "generate-book-page-thumbnail"
        public static let `generateBookCoverThumbnail` = "generate-book-cover-thumbnail"
        public static let `generateAudioWaveform` = "generate-audio-waveform"
        public static let `extractSubtitles` = "extract-subtitles"
        public static let `acquireSubtitles` = "acquire-subtitles"
        public static let `acquireSubtitle` = "acquire-subtitle"
        public static let `importMetadata` = "import-metadata"
        public static let `refreshCollection` = "refresh-collection"
        public static let `libraryMaintenance` = "library-maintenance"
        public static let `databaseBackup` = "database-backup"
        public static let `refreshEntity` = "refresh-entity"
        public static let `identifySearch` = "identify-search"
        public static let `identifyProviderCall` = "identify-provider-call"
        public static let `identifyApply` = "identify-apply"
        public static let `bulkIdentify` = "bulk-identify"
        public static let `autoIdentify` = "auto-identify"
        public static let `identifyCascade` = "identify-cascade"
        public static let `acquisitionSearch` = "acquisition-search"
        public static let `acquisitionMonitor` = "acquisition-monitor"
        public static let `acquisitionImport` = "acquisition-import"
        public static let `acquisitionFinalize` = "acquisition-finalize"
        public static let `acquisitionFailedHandle` = "acquisition-failed-handle"
        public static let `monitoredSearch` = "monitored-search"
        public static let `acquisitionUpgradeReplace` = "acquisition-upgrade-replace"
        public static let `acquisitionEnrich` = "acquisition-enrich"
        public static let `requestAcquisitionFanout` = "request-acquisition-fanout"
        public static let `recycleBinCleanup` = "recycle-bin-cleanup"
    }

    public enum LibraryRootMediaCapability {
        public static let `scanBooks` = "scanBooks"
        public static let `scanVideos` = "scanVideos"
        public static let `scanAudio` = "scanAudio"
    }

    public enum MediaFileIgnoreReason {
        public static let `deletedFromLibrary` = "deleted-from-library"
        public static let `excludedFromLibrary` = "excluded-from-library"
    }

    public enum MediaImageKind {
        public static let `poster` = "poster"
        public static let `still` = "still"
        public static let `cover` = "cover"
        public static let `backdrop` = "backdrop"
        public static let `logo` = "logo"
        public static let `banner` = "banner"
        public static let `hero` = "hero"
        public static let `thumbnail` = "thumbnail"
        public static let `profile` = "profile"
    }

    public enum MetadataPatchField {
        public static let `title` = "title"
        public static let `description` = "description"
        public static let `externalIds` = "externalIds"
        public static let `urls` = "urls"
        public static let `dates` = "dates"
        public static let `stats` = "stats"
        public static let `positions` = "positions"
        public static let `classification` = "classification"
        public static let `flags` = "flags"
        public static let `tags` = "tags"
        public static let `studio` = "studio"
        public static let `credits` = "credits"
        public static let `images` = "images"
    }

    public enum MonitorPreset {
        public static let `all` = "all"
        public static let `future` = "future"
        public static let `missing` = "missing"
        public static let `none` = "none"
    }

    public enum MonitorStatus {
        public static let `active` = "active"
        public static let `paused` = "paused"
        public static let `deletingFiles` = "deleting-files"
        public static let `stopping` = "stopping"
        public static let `fulfilled` = "fulfilled"
    }

    public enum MusicPlayerMiniSide {
        public static let `left` = "left"
        public static let `right` = "right"
    }

    public enum MusicPlayerRepeatMode {
        public static let `off` = "off"
        public static let `all` = "all"
        public static let `one` = "one"
    }

    public enum OrganizeItemStatus {
        public static let `ready` = "ready"
        public static let `unchanged` = "unchanged"
        public static let `skipped` = "skipped"
        public static let `applied` = "applied"
        public static let `failed` = "failed"
    }

    public enum PlaybackMode {
        public static let `direct` = "direct"
        public static let `hls` = "hls"
    }

    public enum PluginSearchFieldType {
        public static let `text` = "text"
        public static let `number` = "number"
        public static let `year` = "year"
    }

    public enum ProgressUnit {
        public static let `item` = "item"
        public static let `page` = "page"
        public static let `chapter` = "chapter"
        public static let `track` = "track"
        public static let `cfi` = "cfi"
        public static let `second` = "second"
    }

    public enum ProperDownloadPolicy {
        public static let `preferAndUpgrade` = "prefer-and-upgrade"
        public static let `doNotUpgrade` = "do-not-upgrade"
        public static let `doNotPrefer` = "do-not-prefer"
    }

    public enum ProviderType {
        public static let `native` = "native"
        public static let `externalProcess` = "external-process"
        public static let `stashCompat` = "stash-compat"
    }

    public enum ReaderMode {
        public static let `paged` = "paged"
        public static let `webtoon` = "webtoon"
        public static let `scrolled` = "scrolled"
    }

    public enum RelationshipKind {
        public static let `cast` = "cast"
        public static let `credits` = "credits"
        public static let `studio` = "studio"
        public static let `tags` = "tags"
        public static let `related` = "related"
    }

    public enum ReleaseRejectionReason {
        public static let `unsupportedFormat` = "unsupported-format"
        public static let `belowMinSeeders` = "below-min-seeders"
        public static let `sizeOutOfRange` = "size-out-of-range"
        public static let `missingRequiredTerm` = "missing-required-term"
        public static let `hasIgnoredTerm` = "has-ignored-term"
        public static let `languageMismatch` = "language-mismatch"
        public static let `wrongProtocol` = "wrong-protocol"
        public static let `noDownloadLink` = "no-download-link"
        public static let `blocklisted` = "blocklisted"
        public static let `qualityNotAllowed` = "quality-not-allowed"
        public static let `notAnUpgrade` = "not-an-upgrade"
        public static let `formatDowngrade` = "format-downgrade"
        public static let `wrongTvUnit` = "wrong-tv-unit"
        public static let `belowMinFormatScore` = "below-min-format-score"
        public static let `dangerousContent` = "dangerous-content"
        public static let `titleMismatch` = "title-mismatch"
        public static let `wrongYear` = "wrong-year"
        public static let `wrongVolume` = "wrong-volume"
    }

    public enum RequestCommitOutcome {
        public static let `requested` = "requested"
        public static let `alreadyOwned` = "already-owned"
        public static let `alreadyRequested` = "already-requested"
    }

    public enum RequestMediaKind {
        public static let `book` = "book"
        public static let `audiobook` = "audiobook"
        public static let `author` = "author"
        public static let `movie` = "movie"
        public static let `series` = "series"
        public static let `season` = "season"
        public static let `episode` = "episode"
        public static let `artist` = "artist"
        public static let `album` = "album"
        public static let `track` = "track"
        public static let `plugin` = "plugin"
    }

    public enum RequestProviderKind {
        public static let `plugin` = "plugin"
    }

    public enum RequestReviewSelection {
        public static let `root` = "root"
        public static let `directChildren` = "direct-children"
        public static let `directChildrenWhenPresent` = "direct-children-when-present"
    }

    public enum StreamKind {
        public static let `video` = "Video"
        public static let `audio` = "Audio"
    }

    public enum SubtitleStyle {
        public static let `stylized` = "stylized"
        public static let `plain` = "plain"
    }

    public enum ThumbnailHoverKind {
        public static let `none` = "none"
        public static let `sprite` = "sprite"
        public static let `imageSequence` = "image-sequence"
        public static let `trickplay` = "trickplay"
    }

    public enum TransferOwnershipState {
        public static let `adding` = "adding"
    }

    public enum UserRole {
        public static let `admin` = "admin"
        public static let `member` = "member"
    }

    public enum VideoPlaybackMethod {
        public static let `direct` = "direct"
        public static let `remux` = "remux"
        public static let `transcode` = "transcode"
    }

    public enum VideoQuality {
        public static let `unknown` = "unknown"
        public static let `sdtv` = "sdtv"
        public static let `dvd` = "dvd"
        public static let `hdtv720p` = "hdtv-720p"
        public static let `webrip720p` = "webrip-720p"
        public static let `webdl720p` = "webdl-720p"
        public static let `bluray720p` = "bluray-720p"
        public static let `hdtv1080p` = "hdtv-1080p"
        public static let `webrip1080p` = "webrip-1080p"
        public static let `webdl1080p` = "webdl-1080p"
        public static let `bluray1080p` = "bluray-1080p"
        public static let `remux1080p` = "remux-1080p"
        public static let `hdtv2160p` = "hdtv-2160p"
        public static let `webrip2160p` = "webrip-2160p"
        public static let `webdl2160p` = "webdl-2160p"
        public static let `bluray2160p` = "bluray-2160p"
        public static let `remux2160p` = "remux-2160p"
    }

    public enum VideoSeriesRenderingMode {
        public static let `flat` = "flat"
        public static let `seasons` = "seasons"
        public static let `mixed` = "mixed"
    }

    public enum CapabilityKind {
        public static let `bookMetadata` = "book-metadata"
        public static let `classification` = "classification"
        public static let `collectionConfiguration` = "collection-configuration"
        public static let `consumption` = "consumption"
        public static let `coverSelection` = "cover-selection"
        public static let `credits` = "credits"
        public static let `dates` = "dates"
        public static let `description` = "description"
        public static let `embeddedAudioMetadata` = "embedded-audio-metadata"
        public static let `fileManagement` = "file-management"
        public static let `files` = "files"
        public static let `fingerprints` = "fingerprints"
        public static let `flags` = "flags"
        public static let `galleryMetadata` = "gallery-metadata"
        public static let `images` = "images"
        public static let `lifetime` = "lifetime"
        public static let `links` = "links"
        public static let `markers` = "markers"
        public static let `personProfile` = "person-profile"
        public static let `playableVideo` = "playable-video"
        public static let `position` = "position"
        public static let `progress` = "progress"
        public static let `providerIdentity` = "provider-identity"
        public static let `rating` = "rating"
        public static let `seriesMetadata` = "series-metadata"
        public static let `source` = "source"
        public static let `stats` = "stats"
        public static let `subtitles` = "subtitles"
        public static let `tagPolicy` = "tag-policy"
        public static let `technical` = "technical"
    }

    public enum ExternalIDProvider {
        public static let `aniDb` = "anidb"
        public static let `imdb` = "imdb"
        public static let `musicBrainz` = "musicbrainz"
        public static let `stash` = "stash"
        public static let `tmdb` = "tmdb"
        public static let `tvdb` = "tvdb"
    }

    public enum ProblemCode {
        public static let `acquisitionImportBlocked` = "acquisition_import_blocked"
        public static let `acquisitionInvalid` = "acquisition_invalid"
        public static let `acquisitionNotFound` = "acquisition_not_found"
        public static let `acquisitionProfileInvalid` = "acquisition_profile_invalid"
        public static let `acquisitionReleaseNotFound` = "acquisition_release_not_found"
        public static let `adminRequired` = "admin_required"
        public static let `audioStreamNotFound` = "audio_stream_not_found"
        public static let `authRateLimited` = "auth_rate_limited"
        public static let `authenticationRequired` = "authentication_required"
        public static let `calendarRangeInvalid` = "calendar_range_invalid"
        public static let `changelogNotFound` = "changelog_not_found"
        public static let `collectionNotFound` = "collection_not_found"
        public static let `databaseBackupInvalid` = "database_backup_invalid"
        public static let `databaseBackupNotFound` = "database_backup_not_found"
        public static let `databaseRestoreInvalid` = "database_restore_invalid"
        public static let `downloadClientInvalid` = "download_client_invalid"
        public static let `downloadClientUnreachable` = "download_client_unreachable"
        public static let `emptyBulkIdentify` = "empty_bulk_identify"
        public static let `entityDeletionConflict` = "entity_deletion_conflict"
        public static let `entityFileNotFound` = "entity_file_not_found"
        public static let `entityNotCreatable` = "entity_not_creatable"
        public static let `entityNotDeletable` = "entity_not_deletable"
        public static let `entityNotFound` = "entity_not_found"
        public static let `externalIdentityAmbiguous` = "external_identity_ambiguous"
        public static let `fileConflict` = "file_conflict"
        public static let `identifyApplyProgressNotFound` = "identify_apply_progress_not_found"
        public static let `identifyFailed` = "identify_failed"
        public static let `identifyQueueApplyInvalid` = "identify_queue_apply_invalid"
        public static let `identifyQueueItemNotFound` = "identify_queue_item_not_found"
        public static let `identifyQueueProposalInvalid` = "identify_queue_proposal_invalid"
        public static let `identifyTargetNotEligible` = "identify_target_not_eligible"
        public static let `indexerInvalid` = "indexer_invalid"
        public static let `indexerUnreachable` = "indexer_unreachable"
        public static let `invalidCollection` = "invalid_collection"
        public static let `invalidCollectionItems` = "invalid_collection_items"
        public static let `invalidCollectionRules` = "invalid_collection_rules"
        public static let `invalidConsumptionEventKind` = "invalid_consumption_event_kind"
        public static let `invalidConsumptionStatisticsWindow` = "invalid_consumption_statistics_window"
        public static let `invalidCredentials` = "invalid_credentials"
        public static let `invalidEntity` = "invalid_entity"
        public static let `invalidEntityImageUpload` = "invalid_entity_image_upload"
        public static let `invalidEntityKind` = "invalid_entity_kind"
        public static let `invalidEntityMetadataPatch` = "invalid_entity_metadata_patch"
        public static let `invalidOpdsRequest` = "invalid_opds_request"
        public static let `invalidPath` = "invalid_path"
        public static let `invalidUpload` = "invalid_upload"
        public static let `lastAdminRequired` = "last_admin_required"
        public static let `libraryRootPathConflict` = "library_root_path_conflict"
        public static let `notFound` = "not_found"
        public static let `passwordInvalid` = "password_invalid"
        public static let `playbackItemNotFound` = "playback_item_not_found"
        public static let `playbackSourceNotFound` = "playback_source_not_found"
        public static let `pluginNotFound` = "plugin_not_found"
        public static let `pluginUpdateNotFound` = "plugin_update_not_found"
        public static let `requestInvalid` = "request_invalid"
        public static let `requestProposalChanged` = "request_proposal_changed"
        public static let `requestServiceInvalid` = "request_service_invalid"
        public static let `rootNotFound` = "root_not_found"
        public static let `sessionNotFound` = "session_not_found"
        public static let `settingInvalid` = "setting_invalid"
        public static let `settingNotFound` = "setting_not_found"
        public static let `setupAlreadyCompleted` = "setup_already_completed"
        public static let `subtitleCandidateUnavailable` = "subtitle_candidate_unavailable"
        public static let `subtitleImportFailed` = "subtitle_import_failed"
        public static let `subtitleProviderUnavailable` = "subtitle_provider_unavailable"
        public static let `subtitleSearchFailed` = "subtitle_search_failed"
        public static let `unknownJobType` = "unknown_job_type"
        public static let `unsupportedEntityImageRole` = "unsupported_entity_image_role"
        public static let `userInvalid` = "user_invalid"
        public static let `userNotFound` = "user_not_found"
        public static let `videoHlsNotFound` = "video_hls_not_found"
        public static let `videoStreamNotFound` = "video_stream_not_found"
        public static let `videoSubtitleNotFound` = "video_subtitle_not_found"
        public static let `videoSubtitleSourceNotFound` = "video_subtitle_source_not_found"
        public static let `videoTrickplayNotFound` = "video_trickplay_not_found"
        public static let `videoTrickplayTileNotFound` = "video_trickplay_tile_not_found"
    }

    public enum SettingKey {
        public static let `acquisitionDownloadPropers` = "acquisition.downloadPropers"
        public static let `acquisitionPreferredProtocol` = "acquisition.preferredProtocol"
        public static let `acquisitionRecycleBinCleanupDays` = "acquisition.recycleBinCleanupDays"
        public static let `acquisitionRecycleBinPath` = "acquisition.recycleBinPath"
        public static let `autoIdentifyConfidenceThreshold` = "autoIdentify.confidenceThreshold"
        public static let `autoIdentifyEnabled` = "autoIdentify.enabled"
        public static let `autoIdentifyEntityKinds` = "autoIdentify.entityKinds"
        public static let `autoIdentifyProviders` = "autoIdentify.providers"
        public static let `autoIdentifyUnorganizedOnly` = "autoIdentify.unorganizedOnly"
        public static let `collectionsAutoRefreshEnabled` = "collections.autoRefreshEnabled"
        public static let `generationAutoGenerateMd5` = "generation.autoGenerateMd5"
        public static let `generationAutoGenerateMetadata` = "generation.autoGenerateMetadata"
        public static let `generationAutoGenerateOshash` = "generation.autoGenerateOshash"
        public static let `generationAutoGeneratePreview` = "generation.autoGeneratePreview"
        public static let `generationGenerateTrickplay` = "generation.generateTrickplay"
        public static let `generationMetadataStorageDedicated` = "generation.metadataStorageDedicated"
        public static let `generationPreviewClipDurationSeconds` = "generation.previewClipDurationSeconds"
        public static let `generationThumbnailQuality` = "generation.thumbnailQuality"
        public static let `generationTrickplayIntervalSeconds` = "generation.trickplayIntervalSeconds"
        public static let `generationTrickplayQuality` = "generation.trickplayQuality"
        public static let `hlsEnableAdaptiveBitrate` = "hls.enableAdaptiveBitrate"
        public static let `hlsEncodingThreadCount` = "hls.encodingThreadCount"
        public static let `hlsFfmpegPath` = "hls.ffmpegPath"
        public static let `hlsMaxCacheSizeGb` = "hls.maxCacheSizeGb"
        public static let `hlsTranscoderProfile` = "hls.transcoderProfile"
        public static let `hlsVaapiDevice` = "hls.vaapiDevice"
        public static let `identifyDefaultProviders` = "identify.defaultProviders"
        public static let `jobsBackgroundConcurrency` = "jobs.backgroundConcurrency"
        public static let `monitoringIntervalMinutes` = "monitoring.intervalMinutes"
        public static let `monitoringSearchEnabled` = "monitoring.searchEnabled"
        public static let `playbackAudioPreferredLanguages` = "playback.audioPreferredLanguages"
        public static let `playbackDefaultMode` = "playback.defaultMode"
        public static let `playbackShowCastControls` = "playback.showCastControls"
        public static let `scanAutoScanEnabled` = "scan.autoScanEnabled"
        public static let `scanIntervalMinutes` = "scan.intervalMinutes"
        public static let `subtitlesAutoDownloadEnabled` = "subtitles.autoDownloadEnabled"
        public static let `subtitlesAutoDownloadLanguages` = "subtitles.autoDownloadLanguages"
        public static let `subtitlesAutoDownloadMinimumConfidence` = "subtitles.autoDownloadMinimumConfidence"
        public static let `subtitlesAutoEnable` = "subtitles.autoEnable"
        public static let `subtitlesFontScale` = "subtitles.fontScale"
        public static let `subtitlesOpacity` = "subtitles.opacity"
        public static let `subtitlesPositionPercent` = "subtitles.positionPercent"
        public static let `subtitlesPreferredLanguages` = "subtitles.preferredLanguages"
        public static let `subtitlesStyle` = "subtitles.style"
        public static let `taxonomyRemoveOrphanTags` = "taxonomy.removeOrphanTags"
        public static let `visibilityDefaultMode` = "visibility.defaultMode"
    }

    public enum ThumbnailMetaIcon {
        public static let `album` = "album"
        public static let `audio` = "audio"
        public static let `book` = "book"
        public static let `calendar` = "calendar"
        public static let `chapter` = "chapter"
        public static let `collection` = "collection"
        public static let `count` = "count"
        public static let `disc` = "disc"
        public static let `duration` = "duration"
        public static let `episode` = "episode"
        public static let `gallery` = "gallery"
        public static let `image` = "image"
        public static let `page` = "page"
        public static let `person` = "person"
        public static let `season` = "season"
        public static let `studio` = "studio"
        public static let `tag` = "tag"
        public static let `track` = "track"
        public static let `video` = "video"
        public static let `volume` = "volume"
    }
}

public extension AcquisitionStatus {
    static let `pending` = Self(rawValue: PrismediaContractCodes.AcquisitionStatus.`pending`)
    static let `waitingForRelease` = Self(rawValue: PrismediaContractCodes.AcquisitionStatus.`waitingForRelease`)
    static let `manualSearchRequired` = Self(rawValue: PrismediaContractCodes.AcquisitionStatus.`manualSearchRequired`)
    static let `searching` = Self(rawValue: PrismediaContractCodes.AcquisitionStatus.`searching`)
    static let `awaitingSelection` = Self(rawValue: PrismediaContractCodes.AcquisitionStatus.`awaitingSelection`)
    static let `queued` = Self(rawValue: PrismediaContractCodes.AcquisitionStatus.`queued`)
    static let `downloading` = Self(rawValue: PrismediaContractCodes.AcquisitionStatus.`downloading`)
    static let `waitingForDownloadClient` = Self(rawValue: PrismediaContractCodes.AcquisitionStatus.`waitingForDownloadClient`)
    static let `downloaded` = Self(rawValue: PrismediaContractCodes.AcquisitionStatus.`downloaded`)
    static let `importing` = Self(rawValue: PrismediaContractCodes.AcquisitionStatus.`importing`)
    static let `imported` = Self(rawValue: PrismediaContractCodes.AcquisitionStatus.`imported`)
    static let `stopping` = Self(rawValue: PrismediaContractCodes.AcquisitionStatus.`stopping`)
    static let `failed` = Self(rawValue: PrismediaContractCodes.AcquisitionStatus.`failed`)
    static let `cancelled` = Self(rawValue: PrismediaContractCodes.AcquisitionStatus.`cancelled`)
    static let `manualImportRequired` = Self(rawValue: PrismediaContractCodes.AcquisitionStatus.`manualImportRequired`)
}

public extension BookFormat {
    static let `imageArchive` = Self(rawValue: PrismediaContractCodes.BookFormat.`imageArchive`)
    static let `epub` = Self(rawValue: PrismediaContractCodes.BookFormat.`epub`)
    static let `pdf` = Self(rawValue: PrismediaContractCodes.BookFormat.`pdf`)
    static let `audio` = Self(rawValue: PrismediaContractCodes.BookFormat.`audio`)
}

public extension RequestActivityBookRendition {
    static let `ebook` = Self(rawValue: PrismediaContractCodes.BookRendition.`ebook`)
    static let `audiobook` = Self(rawValue: PrismediaContractCodes.BookRendition.`audiobook`)
}

public extension RequestActivityBlocklistReason {
    static let `failed` = Self(rawValue: PrismediaContractCodes.BlocklistReason.`failed`)
    static let `stalled` = Self(rawValue: PrismediaContractCodes.BlocklistReason.`stalled`)
    static let `noImportableFiles` = Self(rawValue: PrismediaContractCodes.BlocklistReason.`noImportableFiles`)
    static let `manual` = Self(rawValue: PrismediaContractCodes.BlocklistReason.`manual`)
    static let `wrongContent` = Self(rawValue: PrismediaContractCodes.BlocklistReason.`wrongContent`)
}

public extension ConsumptionActivityKind {
    static let `viewing` = Self(rawValue: PrismediaContractCodes.ConsumptionActivityKind.`viewing`)
    static let `listening` = Self(rawValue: PrismediaContractCodes.ConsumptionActivityKind.`listening`)
    static let `reading` = Self(rawValue: PrismediaContractCodes.ConsumptionActivityKind.`reading`)
}

public extension ConsumptionEventKind {
    static let `accessed` = Self(rawValue: PrismediaContractCodes.ConsumptionEventKind.`accessed`)
    static let `completed` = Self(rawValue: PrismediaContractCodes.ConsumptionEventKind.`completed`)
    static let `skipped` = Self(rawValue: PrismediaContractCodes.ConsumptionEventKind.`skipped`)
}

public extension RequestActivityDownloadProtocol {
    static let `torrent` = Self(rawValue: PrismediaContractCodes.DownloadProtocol.`torrent`)
    static let `usenet` = Self(rawValue: PrismediaContractCodes.DownloadProtocol.`usenet`)
    static let `soulseek` = Self(rawValue: PrismediaContractCodes.DownloadProtocol.`soulseek`)
}

public extension EntityEngagementMode {
    static let `none` = Self(rawValue: PrismediaContractCodes.EntityEngagementMode.`none`)
    static let `playback` = Self(rawValue: PrismediaContractCodes.EntityEngagementMode.`playback`)
    static let `reading` = Self(rawValue: PrismediaContractCodes.EntityEngagementMode.`reading`)
}

public extension EntityMonitorStatus {
    static let `active` = Self(rawValue: PrismediaContractCodes.MonitorStatus.`active`)
    static let `paused` = Self(rawValue: PrismediaContractCodes.MonitorStatus.`paused`)
    static let `deletingFiles` = Self(rawValue: PrismediaContractCodes.MonitorStatus.`deletingFiles`)
    static let `stopping` = Self(rawValue: PrismediaContractCodes.MonitorStatus.`stopping`)
    static let `fulfilled` = Self(rawValue: PrismediaContractCodes.MonitorStatus.`fulfilled`)
}

public extension ProgressUnit {
    static let `item` = Self(rawValue: PrismediaContractCodes.ProgressUnit.`item`)
    static let `page` = Self(rawValue: PrismediaContractCodes.ProgressUnit.`page`)
    static let `chapter` = Self(rawValue: PrismediaContractCodes.ProgressUnit.`chapter`)
    static let `track` = Self(rawValue: PrismediaContractCodes.ProgressUnit.`track`)
    static let `cfi` = Self(rawValue: PrismediaContractCodes.ProgressUnit.`cfi`)
    static let `second` = Self(rawValue: PrismediaContractCodes.ProgressUnit.`second`)
}

public extension ReaderMode {
    static let `paged` = Self(rawValue: PrismediaContractCodes.ReaderMode.`paged`)
    static let `webtoon` = Self(rawValue: PrismediaContractCodes.ReaderMode.`webtoon`)
    static let `scrolled` = Self(rawValue: PrismediaContractCodes.ReaderMode.`scrolled`)
}

public extension RequestActivityReleaseRejection {
    static let `unsupportedFormat` = Self(rawValue: PrismediaContractCodes.ReleaseRejectionReason.`unsupportedFormat`)
    static let `belowMinSeeders` = Self(rawValue: PrismediaContractCodes.ReleaseRejectionReason.`belowMinSeeders`)
    static let `sizeOutOfRange` = Self(rawValue: PrismediaContractCodes.ReleaseRejectionReason.`sizeOutOfRange`)
    static let `missingRequiredTerm` = Self(rawValue: PrismediaContractCodes.ReleaseRejectionReason.`missingRequiredTerm`)
    static let `hasIgnoredTerm` = Self(rawValue: PrismediaContractCodes.ReleaseRejectionReason.`hasIgnoredTerm`)
    static let `languageMismatch` = Self(rawValue: PrismediaContractCodes.ReleaseRejectionReason.`languageMismatch`)
    static let `wrongProtocol` = Self(rawValue: PrismediaContractCodes.ReleaseRejectionReason.`wrongProtocol`)
    static let `noDownloadLink` = Self(rawValue: PrismediaContractCodes.ReleaseRejectionReason.`noDownloadLink`)
    static let `blocklisted` = Self(rawValue: PrismediaContractCodes.ReleaseRejectionReason.`blocklisted`)
    static let `qualityNotAllowed` = Self(rawValue: PrismediaContractCodes.ReleaseRejectionReason.`qualityNotAllowed`)
    static let `notAnUpgrade` = Self(rawValue: PrismediaContractCodes.ReleaseRejectionReason.`notAnUpgrade`)
    static let `formatDowngrade` = Self(rawValue: PrismediaContractCodes.ReleaseRejectionReason.`formatDowngrade`)
    static let `wrongTvUnit` = Self(rawValue: PrismediaContractCodes.ReleaseRejectionReason.`wrongTvUnit`)
    static let `belowMinFormatScore` = Self(rawValue: PrismediaContractCodes.ReleaseRejectionReason.`belowMinFormatScore`)
    static let `dangerousContent` = Self(rawValue: PrismediaContractCodes.ReleaseRejectionReason.`dangerousContent`)
    static let `titleMismatch` = Self(rawValue: PrismediaContractCodes.ReleaseRejectionReason.`titleMismatch`)
    static let `wrongYear` = Self(rawValue: PrismediaContractCodes.ReleaseRejectionReason.`wrongYear`)
    static let `wrongVolume` = Self(rawValue: PrismediaContractCodes.ReleaseRejectionReason.`wrongVolume`)
}

public extension RequestActivityHistoryEvent {
    static let `grabbed` = Self(rawValue: PrismediaContractCodes.AcquisitionHistoryEvent.`grabbed`)
    static let `imported` = Self(rawValue: PrismediaContractCodes.AcquisitionHistoryEvent.`imported`)
    static let `importFailed` = Self(rawValue: PrismediaContractCodes.AcquisitionHistoryEvent.`importFailed`)
    static let `downloadFailed` = Self(rawValue: PrismediaContractCodes.AcquisitionHistoryEvent.`downloadFailed`)
    static let `blocklisted` = Self(rawValue: PrismediaContractCodes.AcquisitionHistoryEvent.`blocklisted`)
    static let `upgraded` = Self(rawValue: PrismediaContractCodes.AcquisitionHistoryEvent.`upgraded`)
    static let `removed` = Self(rawValue: PrismediaContractCodes.AcquisitionHistoryEvent.`removed`)
}

public extension UserRole {
    static let `admin` = Self(rawValue: PrismediaContractCodes.UserRole.`admin`)
    static let `member` = Self(rawValue: PrismediaContractCodes.UserRole.`member`)
}

public extension EntityCapabilityKind {
    static let `bookMetadata` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`bookMetadata`)
    static let `classification` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`classification`)
    static let `collectionConfiguration` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`collectionConfiguration`)
    static let `consumption` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`consumption`)
    static let `coverSelection` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`coverSelection`)
    static let `credits` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`credits`)
    static let `dates` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`dates`)
    static let `description` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`description`)
    static let `embeddedAudioMetadata` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`embeddedAudioMetadata`)
    static let `fileManagement` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`fileManagement`)
    static let `files` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`files`)
    static let `fingerprints` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`fingerprints`)
    static let `flags` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`flags`)
    static let `galleryMetadata` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`galleryMetadata`)
    static let `images` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`images`)
    static let `lifetime` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`lifetime`)
    static let `links` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`links`)
    static let `markers` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`markers`)
    static let `personProfile` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`personProfile`)
    static let `playableVideo` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`playableVideo`)
    static let `position` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`position`)
    static let `progress` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`progress`)
    static let `providerIdentity` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`providerIdentity`)
    static let `rating` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`rating`)
    static let `seriesMetadata` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`seriesMetadata`)
    static let `source` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`source`)
    static let `stats` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`stats`)
    static let `subtitles` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`subtitles`)
    static let `tagPolicy` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`tagPolicy`)
    static let `technical` = Self(rawValue: PrismediaContractCodes.CapabilityKind.`technical`)
}
