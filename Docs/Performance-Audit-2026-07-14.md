# Performance Audit — 2026-07-14

## Outcome

This pass removed trick-play work from passive episode previews and corrected five additional high-confidence hot paths found by a code-first audit:

1. Dashboard and tvOS episode backgrounds fetched and parsed trick-play manifests, sampled frames, decoded sprite sheets, and maintained animation state for decorative previews.
2. Search loaded five independent recent-content groups serially.
3. The compressed artwork cache was count-bounded but not byte-bounded.
4. Audiobook queue construction fetched detail for every track and launched every request at once.
5. Music progress checkpoints JSON-encoded the complete queue every five seconds, while system Now Playing artwork could decode at full source resolution on the main actor.

The resulting paths now use one known thumbnail, concurrent independent search requests, explicit memory/concurrency ceilings, compact progress checkpoints, and the shared off-main artwork downsampler.

## Measured and deterministic changes

| Area | Before | After | Evidence |
| --- | --- | --- | --- |
| Episode hero/background | Thumbnail or hero plus one trick-play manifest per selected episode, sampled sprite-frame image work, timers, and animation state | One `bestCoverPath` thumbnail; zero trick-play manifest or sprite work | Source-path removal and iOS Simulator smoke |
| Search recent groups | Five serial requests | Five overlapping requests, results restored to catalog order | Controlled loader observed maximum overlap of 5; injected serial delay is 150 ms versus a 50 ms parallel critical path |
| Compressed artwork cache | 96-entry count cap with no aggregate byte limit | 96-entry count cap plus 64 MiB total-cost limit; entries larger than the budget are rejected | Deterministic cache test |
| Audiobook queue, complete thumbnail metadata | One detail request per track | Zero detail requests | Focused queue-loader test |
| Audiobook queue, missing metadata | One task per missing track with no request ceiling | Rolling task group capped at 6 requests | 12-track test observed concurrency and proved the ceiling |
| Music resume persistence, 1,000 tracks | Complete queue blob rewritten for each 5-second checkpoint | Complete queue remains unchanged; checkpoint is stored separately | Test fixture encodes to 119,045 B while its checkpoint is under 256 B, reducing periodic payload by more than 99.7% |
| System Now Playing artwork | Full-resolution `UIImage(data:)` decode could occur on the main actor | Shared ImageIO downsample at 1,024 px off-main; decoded result reused | Deterministic 1,024² RGBA ceiling is approximately 4 MiB |

The injected request timings measure controlled test delay, not production network latency. The byte and concurrency ceilings are deterministic. `UserDefaults` figures describe JSON payload size, not a claim about physical disk writes.

## Episode preview simplification

Dashboard hero pages now render `EntityThumbnail.bestCoverPath`, whose preference order is `coverThumb2xURL`, `coverThumbURL`, then `coverURL`. The selected featured item may still advance every four seconds, but an item no longer advances through hover images or trick-play scenes.

The tvOS seasons background now uses the selected episode's same thumbnail path and falls back to the series image only when the episode has no cover. The former preview backdrop, frame sampler, scene timer, pan animation, and Dashboard trick-play support types were removed.

This does not remove trick-play from the playback domain. The playlist parser and playback-facing service remain available for interactive seeking surfaces.

## Other implementation changes

### Search and data loading

- `PrismediaSearchHubLoader` uses a throwing task group for the five independent entity kinds and reorders completed values by their catalog index.
- `AudiobookQueueLoader` trusts finite positive durations already present on thumbnails, hydrates only missing or invalid values, and preserves the original track when detail hydration fails.

### Memory and image decode

- `RemoteArtworkCache` charges compressed entries by `Data.count` and enforces a 64 MiB `NSCache.totalCostLimit` in addition to the existing decoded-image byte LRU.
- Music and video Now Playing coordinators request a 1,024 px decoded image from `RemoteArtworkPipeline`, which performs ImageIO downsampling in a detached task.
- Video retains compressed bytes separately only because AV external metadata requires them; concurrent data and image requests share the pipeline's in-flight transport.

### Playback persistence

- Structural queue changes continue to persist a complete `MusicPlaybackRestoration`.
- Resume, pause, seek, periodic elapsed-time, and completion updates persist a small `MusicPlaybackProgressCheckpoint` instead.
- Loading merges the checkpoint only when its track still exists in the restored queue. A structural save refreshes both records, preventing stale checkpoint state from overriding a replacement queue.

## Validation

- `swift test --parallel`: 414 tests passed, 0 failures.
- Focused search/artwork tests: 16 passed.
- Focused music persistence/controller tests: 17 passed.
- Focused audiobook tests: 14 passed, including 3 new queue-loader seam tests.
- iOS Simulator signed-in smoke: Dashboard rendered the static episode thumbnail successfully.
- Strict Swift formatting and `git diff --check`: passed for the changed performance files.
- Signing-disabled generic iOS, macOS, and tvOS builds: passed.

## Profiling boundary and next priorities

This pass used simulator smoke validation and deterministic seam measurements. It does not claim fresh physical-device launch, scroll-hitch, energy, or Allocations numbers: a trustworthy absolute trace should use a frozen Release build, a repeatable populated dataset, and a physical device. Simulator traces remain useful for correctness and relative debugging but are not a substitute for device hitch/energy evidence.

The next evidence-driven tranche should target:

1. Reader manifest hydration, which currently has serial per-volume detail work.
2. Large EPUB fallback loading, which can inflate a complete archive in memory.
3. Small-row artwork call sites that still accept the shared 2,048 px default.
4. Large-library grouping/prewarming and eager queue/search layouts, after capturing a populated-library SwiftUI trace.

## Reproduction

```sh
swift test --parallel

xcodebuild -project Prismedia.xcodeproj -scheme PrismediaiOS \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Prismedia.xcodeproj -scheme PrismediaMac \
  -destination 'generic/platform=macOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Prismedia.xcodeproj -scheme PrismediaTV \
  -destination 'generic/platform=tvOS Simulator' CODE_SIGNING_ALLOWED=NO build
```
