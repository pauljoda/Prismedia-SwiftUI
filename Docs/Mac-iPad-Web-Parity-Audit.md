# macOS and iPadOS Web-Parity Audit

Date: 2026-07-14

## Scope

This audit compares the existing SwiftUI pages with the current Svelte web app. It focuses on pages that already exist in both clients. Missing feature implementations inside Request and Identify are intentionally deferred.

The target is behavioral and information-architecture parity translated into native SwiftUI structure. macOS and regular-width iPadOS should use native split-view navigation, toolbars, menus, lists, grids, sheets, inspectors, keyboard input, and window resizing rather than reproduce browser chrome literally.

## Implemented in this pass

- macOS now always uses a native `NavigationSplitView` with every default web navigation destination visible in sectioned groups.
- Regular-width iPadOS uses the same sectioned split-view sidebar. Compact-width iOS keeps the existing tab presentation.
- Sidebar order now matches the web default: Overview, Video, Images, Audio, Books, Browse, and Operate.
- Operate combines Files, Identify, Request, Plugins, Jobs, and Settings, matching the web information architecture while continuing to enforce the existing native admin gate.
- Sidebar selection reuses `PrismediaAppRouter`, so existing per-destination navigation paths, deep links, media handoff, and restoration remain intact.

## Settings, Request, and Identify follow-up

Date: 2026-07-17

- Settings no longer presents array values as comma-separated text. Fixed catalogs use checkmark multi-selection, Auto Identify derives its provider choices from installed enabled plugins, selected provider priority is preserved, and open-ended values use an ordered Add/Delete/Move editor.
- Request keeps the web app's Discover, Downloads, Missing, Cutoff Unmet, and History anatomy. Native presentation now uses the system toolbar for section navigation and a sectioned `List` for provider fields, warnings, search actions, and candidates instead of stacked custom panels.
- Identify keeps its native compact stack and regular-width three-column split view. Sidebar selection, queue selection actions, provider search, and proposal actions now use native list selection, menus, control groups, and standard rows.
- Intentional platform adaptations remain: the web Identify dashboard combines kind cards and the review queue in one scrolling page, while native keeps those destinations in the sidebar; the web kind page uses a card grid, while native uses a selectable list that better supports keyboard, pointer, and bulk selection across window sizes.

## Page parity matrix

| Area | Current parity | Important differences | Next direction |
| --- | --- | --- | --- |
| App shell and sidebar | Strong after this pass | Web navigation layout can be reordered, regrouped, collapsed, hidden, and persisted through `/api/nav-layout`; native currently uses the default fixed catalog. Web also carries version, docs, edit-navigation, and account actions in the sidebar footer. | Keep the native sidebar as the baseline. Add shared server layout persistence only if cross-client customization is a product requirement; place account and secondary commands in native toolbar/menu locations. |
| Dashboard | Strong | Both have a continue hero, Continue, Recent, and entity-family shelves. Web renders People, Studios, and Tags as compact chip bands; native renders every family as an artwork shelf. Web lazy-loads lower shelves as they approach the viewport. | Add a native compact taxonomy-band presentation and consider deferred shelf loading if macOS profiling shows meaningful cost. |
| Movies, Series, Videos, Galleries, Images, Books, Authors, Comics, eBooks, People, Studios, Tags, Collections | Strong shared core | Native has shared search, sort, filters, presets, density, page size, grid/list/feed/wall modes, and cursor pagination. Route defaults are not web-exact: web starts Images in media-wall mode and exposes feed only for Galleries and Images. Native exposes all display modes broadly. Web also has selection/bulk actions, taxonomy create/delete, media deletion, Add to Collection, and a New Collection action. | Add route-owned `EntityGridConfiguration` capabilities/defaults, then build shared native selection and action seams instead of route-local toolbars. Prioritize Images/Galleries defaults, Collections creation, and People/Studios/Tags creation. |
| Audio | Functionally strong, structurally different | Web `/audio` is the generic audio-library index. Native maps the sidebar’s Audio row to Albums and uses the richer sectioned `MusicLibraryView`; native also has Artists, Tracks, and audio Collections surfaces that the web default sidebar does not expose. | Keep the richer native library, but rename the page to Audio when entered from the web-parity sidebar and verify album card density, sorting, and search against `/audio`. Do not remove native-only Tracks or audio Collections. |
| Search | Largest consumer-page gap | Web has a dedicated Search page with an immediately focused field, media-kind filters, rating/date filters, URL-backed query state, top-result navigation, grouped results, and per-group expansion. Native `SearchHubView` is a Browse landing page with mode cards, recent content, system search, grouped results, account actions, and no equivalent filter surface. | Split Browse landing from a dedicated Search presentation while reusing `SearchHubService` and grouped result models. On macOS/iPadOS, the sidebar Search row should open the dedicated page; compact iPhone can retain the semantic search tab. |
| Playback Stats | Moderate | Filters, summary metrics, daily activity, top entities, and recent events exist in both. Web includes an interactive daily chart, selection/legend state, denser desktop composition, and clearer running-period context. Native uses stacked bar rows only. | Add a Swift Charts daily activity visualization with accessible summaries, then adapt the remaining content into a two-column wide layout while keeping a single-column compact fallback. |
| Entity detail | Strong native adaptation | The shared native detail shell already covers artwork atmosphere, media actions, progress, relationships, ratings, tags, cast/reference content, and platform playback/reader presentation. Exact web tab/action density varies by entity kind. | Audit kind-by-kind with fixtures and wide previews after the page-index work. Preserve native playback and reader ownership rather than flattening them into web layouts. |
| Files | Page exists; major function gap | Native browses roots and folders. Web additionally supports folder creation, move, delete, upload/drop, rescan, selection, and richer file operations. | Deferred under the current instruction. When resumed, extend the shared file browser service and use native context menus, file importers, drop destinations, and commands. |
| Plugins | Page exists; major function gap | Native lists installed plugins and supports update. Web has Installed, Prismedia Community, and Stash Community tabs plus install, remove, credentials, search, and scraper discovery. | Deferred functional work. Preserve the native list/detail shape and expose install/auth flows as sheets or inspectors. |
| Jobs | Moderate | Native shows queue counts, recent runs, progress, cancel, clear failures, and rebuild previews. Web separates running, queued, failed, and completed work; shows schedule/last-scan context; supports starting job kinds and kill-all. | First match the web status grouping and wide information hierarchy using native sections. Defer missing job commands until their service contracts are intentionally added. |
| Settings | Moderate directory parity | Native has Acquisition, Playback, Subtitles, Generation Pipeline, Auto Identify, Transcode Cache, Database Backups, and server-returned fallback groups. Web also has Watched Libraries, Users, and Diagnostics with permission-specific visibility. | Add the three missing directories when their existing APIs are wired into focused native pages. Keep the current native `NavigationStack` directory/detail pattern. |
| Request and Identify | Page shells exist | Internal workflow parity is incomplete and intentionally excluded from this audit pass. | Revisit separately after the shared desktop page shell is stable. |

## Recommended implementation order

1. Dedicated Search page and macOS/iPad search behavior.
2. Route-owned entity-grid capabilities and defaults, starting with Images and Galleries.
3. Shared entity-grid selection/actions for Collections and manageable taxonomy pages.
4. Swift Charts Stats layout and wide-window composition.
5. Dashboard taxonomy bands and lower-shelf loading review.
6. Settings directory completion.
7. Jobs visual grouping, then the deferred Files, Plugins, Request, and Identify capability work.

## Validation target for each follow-up pass

- macOS minimum and wide window sizes, sidebar shown and hidden, keyboard navigation, toolbar overflow, and pointer interaction.
- iPad full screen plus continuous resizing through regular and compact widths without losing selection or navigation paths.
- Fixed dark app chrome, Increase Contrast, Reduce Transparency, Reduce Motion, and accessibility Dynamic Type.
- Focused unsigned iOS and macOS builds, `swift test` for shared behavior, deterministic previews, and manual fixture-backed UI review.
