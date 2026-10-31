---
name: prismedia-adaptive-layout
description: Prismedia's rules for iOS screens that adapt across sizes, including iPhone Duo's outer and inner displays and the fold. Branch on size class, let system containers (NavigationSplitView, ArrangementView via PrismediaArrangedPanes, adaptive grids) place things, and keep controls off the fold. Use when adding or changing any iOS screen, sheet, toolbar, floating bar or two-pane layout, or when checking a layout on the iPhone Duo simulator. Read with the iphone-duo-* skills, which cover the platform itself.
---

# Adaptive layout in Prismedia

The `iphone-duo-*` skills explain the platform. This one records what the
user asked for and what we learned adapting Prismedia, building on the same
work in Crest and Kairos. `AGENTS.md` › iPhone Duo has the short version.

## The rules

- **Branch on `horizontalSizeClass` only.** The outer display is compact
  width (like any iPhone); the inner display is regular × regular in any
  orientation and ignores the app's portrait-only mask. No idiom, orientation
  or measured-width checks to pick a layout.
- **Let containers size things.** A screen fills the space it gets: a
  split-view column, half of an arrangement, or the display less the side bar.
  Don't add new content-width caps or breakpoints.
- **Nothing tappable on the fold.** Media may cross the middle of the open
  display. Buttons, text fields, sliders and grabbers stay on one side, or a
  container places them.
- **Bars come from the system.** Toolbar and tab items from `NavigationStack`
  or `NavigationSplitView` move to the side bar on the iOS 27.1 SDK. Every item
  needs a title and a symbol (`Label`, `Button(_:systemImage:)`,
  `PrismediaToolbarActionButton`). Hand-drawn bars and custom-view items stay
  where they are.
- **State survives the fold.** Opening and closing swaps the tab shell for the
  sidebar shell. Navigation lives in `PrismediaAppRouter`, playback in its
  controllers and hosts above the shell, so neither resets.

## What the user asked for

- **One floating bar, not two capsules.** The regular-width mini player is a
  single glass bar; only its contents are arranged around the fold.
- **A way to get the bar out of the way.** Minimize collapses it to floating
  artwork in a bottom corner (like the web player), draggable between the
  two corners. The bar's artwork flies into the tile with matched geometry
  and back again; state changes that move artwork between places animate as
  one piece, never a fade between two copies.
- **A visible grabber where a swipe dismisses.** Regular-width Now Playing
  keeps a grabber at the top of the player pane, plus Close in the side bar.
- **Window controls in the side bar.** The sidebar toggle sits in the
  right-edge bar, not beside the brand.
- **Floating chrome never covers active input.** The mini player hides while
  a search field shares its spot.
- **Tabletop playback like Netflix.** Half closed on a table, the video takes
  the raised half and the overlay chrome becomes a persistent panel of large
  tiles on the flat half.

## Pick the container by the content

| Content | Container | Prismedia screens |
|---|---|---|
| Destinations and a page | `NavigationSplitView`, `.balanced` (the wide shell) | App shell |
| Two related groups that both stay visible | `PrismediaArrangedPanes` (`ArrangementView`, split style) | Now Playing (player · queue), mini player (track · transport) |
| A feed of cards | adaptive `LazyVGrid` | Library grids |
| Media and its controls, half closed on a table | `onTabletopFoldChange`: media above the fold, a persistent panel below | Full-screen video (`VideoTabletopControlPanel`) |

- `PrismediaArrangedPanes` is the one `ArrangementView` wrapper. Use it on
  regular width only. It falls back to two equal columns on the 27.0 SDK and
  on macOS and tvOS.
- Don't put an arrangement inside a `ScrollView` or `List`, or a split view
  inside an arrangement.
- Inside the shell's detail column a page is roughly phone-width beside the
  sidebar, so most pages stay one column there. An arrangement in a column
  that is taller than wide stacks its panes vertically.

## Gotchas we hit

- **`ArrangementView` has no ideal height.** In a `safeAreaInset` or with
  `fixedSize` it collapsed to a sliver and its contents overflowed off the
  bottom of the screen. Size the bar from a hidden copy of its tallest group
  and lay the arrangement over it with `.overlay`
  (`IPadMusicMiniPlayerView`).
- **The sidebar toggle belongs in the detail column.** Only the detail
  column's items join the side bar. The sidebar removes the system toggle with
  `.toolbar(removing: .sidebarToggle)` next to its
  `navigationSplitViewColumnWidth`, and the shell adds a Show/Hide Sidebar
  item to the detail. Applied outside the sidebar view, the removal let the
  column grow to its maximum width.
- **A floating bar shares the bottom with search.** iPhone Duo is a phone, so
  even on regular width the system puts `.searchable` at the bottom, where the
  mini player floats. `EntityGridSearchModifier` (also used by the music
  library) places library search in the navigation bar drawer on regular
  width, and `.suppressesMusicMiniPlayerWhileSearching()` hides the bar during
  any search that still lands at the bottom.
- **Stacked panes need their own content split.** Open in portrait, an
  arrangement stacks its panes, so a pane that holds media plus controls gets
  cramped. Now Playing splits looking (artwork, title) from touching (queue,
  transport, controls) so both orientations and tabletop work.
- **Gestures on media block swipe-to-dismiss.** A tap or drag on Now
  Playing's artwork stopped the cover's swipe down. Leave big media surfaces
  without gestures and put actions in buttons.
- **Tabletop is a fold that runs across the view.** `onTabletopFoldChange`
  reports the division region while it is active and wider than tall, in the
  view's own space with its clearance included; lay media out above
  `fold.minY` and controls below `fold.maxY`. Book-fold and flat report nil,
  so the overlay layout stays. The overlay arrangement style's `axes` option
  exists but has no published docs, so the player reads the fold directly.
- **Chrome stays while it's being used.** The player's auto-hide restarts
  from `isScrubbing`; any new control that the person holds (a slider, a
  drag) must suspend auto-hide the same way.
- **The inner display won't rotate on request.** Fullscreen video forces
  landscape only on a compact-width phone window
  (`VideoFullscreenOrientationPolicy`).
- **Gate 27.1 APIs twice.** Both Xcodes ship the same Swift compiler, so use
  `#if os(iOS) && canImport(SwiftUICore, _version: 8.0.85)` plus
  `if #available(iOS 27.1, *)`, and keep the 27.0 build compiling.

## Checking on the iPhone Duo simulator

1. Build with the 27.1 SDK:
   `DEVELOPER_DIR="/Applications/Xcode 27.1.app/Contents/Developer" xcodebuild -project Prismedia.xcodeproj -scheme PrismediaiOS -destination 'id=<duo udid>' CODE_SIGNING_ALLOWED=NO build`,
   then `xcrun simctl install` the app. A 27.0 build runs letterboxed with
   horizontal bars.
2. Run `python3 Scripts/mock-server.py` (port 8899) and launch with
   `xcrun simctl launch <udid> com.pauljoda.Prismedia -prismedia-ui-testing -prismedia-reset-session`,
   passing `SIMCTL_CHILD_`-prefixed environment:
   - `PRISMEDIA_UI_TEST_SESSION_SERVER=http://localhost:8899` and
     `PRISMEDIA_UI_TEST_SESSION_TOKEN=mock-session-token` sign in.
   - `PRISMEDIA_UI_TEST_MODE_ID` / `PRISMEDIA_UI_TEST_DESTINATION_ID` open a
     destination (`video`/`movies`); `PRISMEDIA_UI_TEST_ENTITY_ID` /
     `PRISMEDIA_UI_TEST_ENTITY_KIND` open a detail page.
   - `PRISMEDIA_UI_TEST_MUSIC_TRACK_ID` and `…_TITLE` start a track;
     `PRISMEDIA_UI_TEST_SHOW_NOW_PLAYING=1` opens Now Playing and
     `PRISMEDIA_UI_TEST_COLLAPSE_MINI_PLAYER=1` collapses the mini player.
3. Capture each display with `xcrun simctl io <udid> screenshot --display=<uuid>`.
   The display UUIDs change on every `simctl io <udid> enumerate`, so look
   them up each time: the 2007 × 2853 port is the inner display and
   1398 × 2034 the outer. A tiny all-black capture means that display is off.
4. Poses (closed, book-fold, flat, rotate) are buttons under the device in
   Xcode 27.1's Device Hub. Clicks from outside don't land there, so ask the
   user to switch poses. Taps don't land reliably on the inner display either;
   use the launch environment to reach a screen.

Check every changed screen closed, open flat, open in portrait and
book-folded.
