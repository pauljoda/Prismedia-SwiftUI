# Performance Audit — 2026-07-13

## Outcome

This audit found five concrete performance problems and corrected them:

1. Grid thumbnails decoded artwork at 2,048 px and discarded the decoded result when a SwiftUI view was recreated.
2. Image-viewer source bytes had no aggregate memory limit.
3. Comic pages decoded at up to 8,192 px, duplicate callers could repeat the decode, and prewarming could start five large decodes together.
4. Trick-play frame selection linearly scanned the complete frame list on every lookup.
5. Search ranking repeatedly normalized and projected item titles inside the sort comparator.

Focused red/green tests, isolated before/after measurements, the complete Swift test suite, all three app builds, and iOS Simulator UI smoke tests were used for validation. No physical-device result is included.

## Before and after

| Area | Before | After | Result |
| --- | ---: | ---: | --- |
| Search ranking, 5,000 items × 20 runs | 4,698.873 ms | 105.817 ms | 44.4× faster |
| Filmstrip, 10,000 frames × 50,000 lookups | 94.022 ms | 2.133 ms | 44.1× faster |
| Representative thumbnail decoded bytes | 16,777,216 B at 2,048 px | 1,048,576 B at 512 px | 16× less decoded memory |
| Representative thumbnail decode | 97.1 ms at 2,048 px | 4.90 ms at 512 px | 19.8× faster for the fixture |
| Repeated thumbnail request | transport and decode could recur with view recreation | 0.0026 ms decoded-cache hit; one transport | work is coalesced and reused |
| Comic page decode ceiling | 8,192 px; the whole warm window could decode together | 4,096 px; at most 2 prewarm loads | 256 MiB → 64 MiB per square RGBA page; at most 128 MiB decoding concurrently |
| Image-viewer source cache | unbounded aggregate bytes | 64 MiB LRU | deterministic memory ceiling |

The image timings are fixture-specific isolated microbenchmarks, not Instruments wall-clock measurements. The decoded-byte and concurrency reductions are deterministic. Comic figures are worst-case square 4-byte-per-pixel ceilings; typical portrait pages are smaller. A double-page spread plus its warm neighbors can retain up to six pages, so the theoretical retained decoded window falls from 1.5 GiB to 384 MiB.

## Implementation

### Artwork and image viewer

- `RemoteArtworkPipeline` now coalesces transport and decode by URL plus requested pixel size.
- `RemoteArtworkCache` retains decoded `CGImage` values under a 64 MiB byte-cost LRU while preserving compressed data for palette extraction.
- ImageIO downsampling remains off the main actor and applies embedded orientation.
- Grid thumbnails request 512 px instead of 2,048 px.
- The iOS and tvOS thumbnail paths no longer create an unused `GeometryReader`.
- `EntityMediaContentLoader` retains the complete feed identity but bounds resident source bytes with a 64 MiB LRU.

### Comic reader

- The page-cache decode limit is 4,096 px and injectable for deterministic tests.
- A single tokenized task now owns both transport and decode, so concurrent callers share all expensive work.
- Prewarming runs at most two page loads concurrently while retaining the existing visible-plus-warm window.

### Search and playback

- Search normalizes the query once and each title once, decorates results with rank and original offset, then performs a stable sort.
- Filmstrip lookup uses an upper-bound binary search. Duplicate timestamps and boundary behavior remain covered by tests.

## Instruments and runtime findings

### iOS Simulator

The frozen Debug baseline passed the broad shell/search/detail UI scenario twice (57.428 s and 57.507 s including XCTest waits and automation). A host-wide Time Profiler fallback sampled only 16 ms of Prismedia CPU during an 11.011 s idle Dashboard capture; 10 ms was on the main thread, with 0.091% main-running coverage. The app-specific `sample` capture showed the main thread normally parked in `mach_msg2_trap`.

Steady Dashboard physical footprint was 29 MiB. This is an idle reference, not a substitute for an image-viewer or comic-reader Allocations trace.

The original movie-grid smoke failure was a test-driver defect, not a grid virtualization defect: the test entered Video mode but remained on the two-item Videos destination while waiting for a movie. The corrected test explicitly selects Movies before scrolling.

After the fixes, the corrected long-grid test and the broad shell/search/detail test both passed on an iPhone 17 Pro simulator running iOS 26.5. The first attempt never launched because SpringBoard reported a busy preflight state; both tests passed after rebooting only that simulator and rerunning the already-built test bundle. The final result bundle contains 2 passed, 0 failed, and no runtime warnings.

An after-build Movies-screen sample measured a 32.8 MiB footprint (33.3 MiB peak). Of 3,696 main-thread samples, 3,695 were normally parked in `mach_msg2_trap`; no post-fix idle CPU spin appeared. This busier screen is not directly comparable to the 29 MiB baseline Dashboard, but it confirms the fixed build remains within the same low steady-state memory range.

### macOS

The first opening of Playback Stats produced a 315.41 ms CPU-bound microhang and a 241.67 ms worst hitch in a Debug SwiftUI trace. A timestamped warm reopen produced no hang and an 8.33 ms worst hitch, a 96.6% reduction. Protocol-conformance instantiation accounted for 177.7 ms of the first trace, while the warm route's largest app callback was 7.93 ms.

This is one-time Debug runtime/type-metadata warmup rather than a repeatable Stats algorithmic bottleneck, so no speculative production change was made. Broad environment propagation remains a structural observation, but the warm route stayed within frame budget.

### tvOS Simulator

The deterministic signed-in Home screen launched. A five-second, 1 ms `sample` captured a 30.8 MiB footprint, 31.3 MiB peak, 0.0% steady CPU, and all 3,860 main-thread samples parked in the run loop. No steady-state spin was found.

## Tool limitations

Xcode 27 beta created an Instruments run and then stalled before sampling or before finalization for simulator-targeted Time Profiler, Allocations, and App Launch captures in several attach/launch modes. The usable evidence therefore combines:

- a valid macOS SwiftUI trace,
- a valid host-wide Time Profiler trace filtered to Prismedia's simulator process,
- app-specific `sample` and `footprint` captures,
- deterministic simulator UI tests,
- focused algorithm and memory tests with before/after microbenchmarks.

The runs used normal Debug builds. Applying `-O` globally to the Debug test graph reproducibly crashed the Xcode 27 Swift 6.4 compiler in the external `xctest-dynamic-overlay` package.

Before the user restricted testing to simulators, one physical-device App Launch command had already completed and may have installed/replaced and launched the app. That trace was excluded. No physical-device command was issued afterward.

## Residual audit

The following were inspected but were not demonstrated as current bottlenecks:

- PDFKit document loading and outline construction are main-actor-sensitive. They should be revisited with a large deterministic PDF fixture before changing isolation.
- The prominent-action border beam repeats slowly, but neither valid signed-in trace attributed measurable work to it.
- The loading canvas can animate at display cadence, but no idle CPU spin appeared in the simulator samples.
- Dashboard shelves intentionally use a bounded eager `HStack`; an earlier lazy implementation clipped mixed-ratio posters, and current shelf sizes are bounded.
- SwiftUI grids are lazy, trick-play/palette caches are bounded, polling tasks cancel correctly, API decoding is off-main, and playback observation is already granular.

No other high-confidence, user-visible performance problem was found in the tested flows. Large real libraries, very large PDFs/comics, and populated playback-history data remain the best candidates for a later dataset-backed profiling pass.

## Evidence and reproduction

Primary artifacts are under:

- `/tmp/prismedia-perf-baseline-ios`
- `/tmp/prismedia-perf-baseline-platforms`
- `/tmp/prismedia-perf-after-builds`
- `/tmp/prismedia-perf-after-ios-ui-retry-20260713.xcresult`
- `/tmp/prismedia-perf-after-ios-movies.sample.txt`
- `/tmp/prismedia-image-memory-red.log`
- `/tmp/prismedia-image-memory-green-attempt.log`
- `/tmp/prismedia-image-memory-microbenchmark.log`
- `/tmp/prismedia-image-memory-full-swift-test.log`

Core validation commands:

```sh
swift test --parallel

xcodebuild -project Prismedia.xcodeproj -scheme PrismediaiOS \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Prismedia.xcodeproj -scheme PrismediaMac \
  -destination 'generic/platform=macOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Prismedia.xcodeproj -scheme PrismediaTV \
  -destination 'generic/platform=tvOS Simulator' CODE_SIGNING_ALLOWED=NO build
```
