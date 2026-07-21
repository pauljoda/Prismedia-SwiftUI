# Prismedia SwiftUI

Native Prismedia clients for iOS, iPadOS, macOS, and tvOS, built from one shared Model-View codebase.

The app targets iOS 26, macOS 26, and tvOS 26. Prismedia intentionally uses one dark app-chrome appearance, native SwiftUI structure, and Liquid Glass for the functional layer. Reader document content may still use light or sepia themes without changing the surrounding app chrome.

## Architecture

Prismedia uses modern Model-View rather than ViewModels:

- views own private value state with `@State`;
- focused service/use-case structs perform async orchestration;
- `PrismediaAppEnvironment`, `PrismediaAppRouter`, playback controllers, and narrow caches use Observation and typed environment injection;
- feature and shared UI code is SwiftUI-only;
- the few APIs without SwiftUI equivalents live under `Infrastructure/PlatformAdapters`.

The shared source tree is organized vertically:

- `App` — composition, routing, and platform-adaptive shells
- `Features` — Authentication, Dashboard, Entity Detail, Entity Grid, Playback, Reader, Search, Statistics, and Television
- `DesignSystem` — semantic dark-chrome tokens, content materials, and reusable visual primitives
- `Domain` — transport-independent product values and presentation policy
- `Infrastructure` — API implementations and required Apple-framework adapters
- `Networking` and `Storage` — transport and persistence boundaries
- `PreviewSupport` — deterministic fixtures and in-memory preview dependencies

See [Docs/Architecture.md](Docs/Architecture.md) for the dependency rules, feature template, playback boundaries, and validation contract. `AGENTS.md` is the enforceable engineering and native-design contract.

## Custom VLCKit builds

Prismedia publishes reproducible, checksum-pinned VLCKit 3.7.3 XCFrameworks for
iOS, macOS, and tvOS. These are intentionally public because the two downstream
fixes are useful to any Apple-platform client with the same requirements:

- restore FFmpeg's MLP demuxer, parser, and decoder so Dolby TrueHD/MLP audio is
  available;
- force VLC's `pipe()` fallback instead of importing `pipe2()`, which newer SDKs
  declare even though the symbol is unavailable on older supported tvOS
  releases.

The patch also gives the frameworks explicit minimums of iOS/tvOS 15 and macOS
12. It does not otherwise change VLCKit's public API.

| Release asset | Contents |
| --- | --- |
| `MobileVLCKit.xcframework.zip` | iOS device and Simulator slices |
| `VLCKit.xcframework.zip` | Universal Apple-silicon and Intel macOS framework |
| `TVVLCKit.xcframework.zip` | tvOS device and Simulator slices |

The [latest custom VLCKit release](https://github.com/pauljoda/Prismedia-SwiftUI/releases/latest)
contains each archive and its SHA-256 file. The release workflow requires Xcode
26, checks the compiled SDK with `vtool`, and refuses to publish unless the
expected TrueHD/MLP symbols are present and `pipe2()` is not an undefined
import. Release tags are immutable.

To reproduce the frameworks locally, run `Scripts/bootstrap-vlckit.sh`. Set
`PRISMEDIA_VLCKIT_PLATFORM` to `ios`, `macos`, or `tvos` to build one platform;
omit it to build all three. The script clones the upstream 3.7.3 tag, applies
the narrow patch in `Scripts/Patches`, validates the binaries, and installs them
under the ignored `Carthage/Build` directory.

See [Docs/CustomVLCKit.md](Docs/CustomVLCKit.md) for download examples, exact
verification behavior, supported slices, and licensing details. These are
downstream community builds, not official VideoLAN releases.

### Xcode Cloud integration

Xcode Cloud runs `ci_scripts/ci_post_clone.sh` to download only the XCFramework
for the current action. The script verifies its hard-coded SHA-256 before
installing it. Swift package versions are separately locked by the committed
`Package.resolved` files.

`PrismediaCloud.xcworkspace` exposes the app and bootstrap schemes to Xcode
Cloud without granting repository access to the owners of public Swift package
dependencies. Packages such as Point-Free's `combine-schedulers` remain normal
public dependencies; they do not require owner sign-in or repository access.

## Native design

- One system `TabView` adapts into sidebar presentation where the platform and width support it while preserving router state.
- System bars, sheets, menus, buttons, and search own Liquid Glass. Content cards use semantic fills or standard materials instead of glass.
- Custom glass remains limited to important controls floating over rich media.
- Feature code uses semantic roles instead of literal colors. The generic content layer is black with a muted spectral haze derived from the app icon, while increased-contrast variants remain available for interactive accents.
- Video, music Now Playing, tvOS cinema surfaces, and the comic reader intentionally keep receding dark media presentation.

## Xcode previews

Every visual type has a named, direct `#Preview` beside it, enforced by `PreviewCoverageTests`. A screen preview may wrap the type in navigation or `PreviewShell`, but it must still instantiate the component under test rather than substituting a larger screen. `PreviewShell` injects an in-memory app environment, router, API fixture loader, and artwork loader so previews never require a server, Keychain, preferences, or network.

Important surfaces include representative loading, content, empty/error, fixed-dark, and accessibility-size scenarios. Reader previews may additionally exercise document-specific light and sepia themes. Xcode's preview controls remain the source of truth for Reduce Transparency and Increase Contrast because those environment values are read-only.

## Verify

```sh
swift test
swift test --filter PreviewCoverageTests
xcodebuild -project Prismedia.xcodeproj -scheme PrismediaiOS -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
xcodebuild -project Prismedia.xcodeproj -scheme PrismediaMac -destination 'generic/platform=macOS' build CODE_SIGNING_ALLOWED=NO
xcodebuild -project Prismedia.xcodeproj -scheme PrismediaTV -destination 'generic/platform=tvOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

UI smoke test against the deterministic mock server:

```sh
python3 Scripts/mock-server.py &
xcodebuild test -project Prismedia.xcodeproj -scheme PrismediaiOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

The mock credentials are `test` / `test1234` at `localhost:8899`. For the local Prismedia development server, use `localhost:8008` and a real account.
