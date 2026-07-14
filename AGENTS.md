# Prismedia SwiftUI Engineering Contract

## Architecture: Model-View

- Do not introduce ViewModel classes.
- Views own transient presentation state with private `@State` values.
- `PrismediaAppEnvironment` and app-wide routers/sessions use `@Observable` and typed `.environment(...)` injection.
- Use `@Bindable` only when a child needs bindings into an injected observable model.
- Use focused `@MainActor` service or use-case structs to orchestrate async work. Keep persistence and network transport behind protocols.
- Domain models must not construct HTTP requests or depend on feature UI.
- Dependencies point inward: app composition wires features to infrastructure; features depend on domain values, design components, and service protocols; infrastructure implements those protocols.
- Keep platform shells and system adapters separate. Share content components and behavior across platforms, not lowest-common-denominator navigation chrome.

## Feature organization

- Organize feature code vertically under `Features/<Feature>` with `Components`, `Models`, `Services`, and `Support` as needed.
- Keep one named enum, struct, class, actor, or protocol per Swift source file. A view file should contain its single view declaration; place secondary views in `Components` and feature-owned data shapes or helpers in `Models` or `Support`.
- Keep a type at the narrowest feature scope that owns it. Promote it to a higher shared folder only when multiple feature areas use it.
- Private `CodingKeys` and framework-required nested coordinator types may remain nested implementation details in non-view files.
- Root screens compose real, narrowly-scoped `View` types. Do not use large computed `some View` properties as a substitute for component boundaries.
- Keep app entry points and `App/Shell` small. Long-running playback, restoration, and navigation orchestration belong in focused support types.
- Isolate necessary AVKit, MediaPlayer, UIKit, and AppKit bridges under `Infrastructure/PlatformAdapters` and expose SwiftUI-facing wrappers.

## Native adaptive design

- Prismedia intentionally uses one dark app-chrome appearance on every platform. Reader document themes may still offer light or sepia content, but navigation, controls, and presentations remain dark.
- Use semantic color roles from `DesignSystem/Tokens`; feature files must not hard-code foreground/background colors except for purpose-built immersive media canvases.
- Prefer native `TabView`, `NavigationStack`, `NavigationSplitView`, toolbars, sheets, inspectors, menus, search, and standard controls so platform appearance and Liquid Glass adapt automatically.
- Treat Liquid Glass as the floating functional layer for navigation and important controls. Keep media, lists, grids, tables, and cards in the content layer.
- Use custom glass sparingly. Do not stack glass on glass, apply it to every card, or add custom backgrounds behind system bars.
- Prismedia buttons default to native clear, untinted Liquid Glass on every surface. A single contextually primary action in a local control group may use native prominent glass with a contrast-safe artwork-derived tint; secondary and utility actions remain clear and untinted. Put other semantic color in the label foreground rather than tinting the glass. Other custom glass uses regular glass by default; reserve clear glass outside buttons for rich media where foreground content remains legible.
- Group related glass with `GlassEffectContainer`; match its spacing to layout spacing. Apply `.interactive()` only to interactive elements.
- Use tint only for meaningful non-button selection or status—not decoration. Keep button glass untinted; communicate button semantics through the label foreground and the shared prominent-action beam. Prefer monochrome toolbar symbols otherwise.
- Use capsule controls for touch-friendly prominent actions and concentric corners when a control nests against its container. Preserve denser rounded-rectangle controls on macOS.
- A custom `Button` or tap gesture that owns a `List` or `Form` row must expand its label to the full available width and define a rectangular content shape. Never rely on intrinsic text hit testing; regression tests should tap row whitespace. Native row-owning controls and nested inline actions are exempt.
- Test Reduce Transparency, Increase Contrast, Reduce Motion, Dynamic Type, VoiceOver, the fixed dark appearance, window resizing, and platform input modes.

## Previews

- Keep each component's `#Preview` beside the component.
- Previews must use in-memory dependencies and bundled fixtures. Never depend on live network, keychain, UserDefaults, or disk state.
- Important components need meaningful content, loading, empty, error, dark, and accessibility-size scenarios. Reader content-theme previews may additionally cover light and sepia document presentation.

## Playback invariants

- Playing video must remain visible. Request Picture in Picture synchronously before navigation hides an active player.
- Playback resolution must activate a controller/session before the loading state can complete.
- Prefer native codec and AVKit capability first; bridge only where SwiftUI does not expose the required media behavior.

## Validation

- Run `swift test` after shared behavior or architecture changes.
- Build all shared app schemes with code signing disabled:
  - `PrismediaiOS` for a generic iOS Simulator
  - `PrismediaMac` for generic macOS
  - `PrismediaTV` for a generic tvOS Simulator
- Run focused UI smoke tests from a fresh, isolated preference/session state after shell, sign-in, search, or navigation changes.
- Keep `ModernArchitectureGuardTests` passing; update the contract only through an intentional architecture decision.
