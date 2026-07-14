# Video Thumbnail Design QA

- Source visual truth: `/var/folders/57/nxb_12wd085fd_4378sb50d40000gn/T/codex-clipboard-5dabd50d-2a12-4028-b2ff-30b5be9911f8.png`
- Implementation screenshot: `/tmp/PrismediaThumbQAVideos-20260711/69E8B3A8-4DFE-4211-81A1-CD1746DB835D.png`
- Viewport: iPhone 17 Pro simulator, 402 x 874 points, Prismedia's fixed dark appearance
- Appearance contract: app chrome remains dark; light and sepia are reader document-content themes only
- State: Videos grid containing two movie-owned video entities with duration and resolution metadata
- Primary interactions tested: sign in, enter Video mode, select Videos, render the entity grid
- Console errors checked: the selected UI test completed with no app errors; the simulator emitted only the known duplicate accessibility-bundle runtime warning

## Full-view comparison evidence

The rendered grid preserves the native two-column iOS layout while matching the source card hierarchy: artwork, title, then a compact metadata row. Both movie-owned video cards omit the incorrect `E0`/`E1` badge. The denser metadata treatment leaves more breathing room around and between cards.

## Focused region comparison evidence

The card region was compared in the same visual input as the source screenshot. Duration and quality now use caption-2 monospaced text, smaller symbols, 4-point internal gaps, 6-point horizontal padding, 3-point vertical padding, and a 6-point inter-chip gap. The resulting pills are visibly shorter and narrower than the source's button-sized controls while remaining legible.

## Required fidelity surfaces

- Fonts and typography: native SF typography is retained; metadata moves from caption to caption-2 with medium optical weight, while titles keep their existing hierarchy and truncation behavior.
- Spacing and layout rhythm: metadata pill padding and gaps are reduced, and the title-to-metadata gap changes from 10 to 7 points. Card and grid geometry remain unchanged.
- Colors and visual tokens: Prismedia surface, border, secondary-text, cool accent, and spectral roles are reused without drift.
- Image quality and asset fidelity: production cards still use the shared artwork pipeline. The deterministic UI fixture intentionally uses generated fallback artwork, so subject imagery differs from the source but no production asset was replaced.
- Copy and content: duration and resolution copy are unchanged. Invented episode labels are removed for movie-owned and standalone videos; structural episodes and seasons retain meaningful `E<n>` and `S<n>` labels.

## Findings

No actionable P0, P1, or P2 differences remain for the requested thumbnail changes.

## Comparison history

1. Initial source evidence showed P1 semantic drift (`E0` on a movie video) and P2 density drift (metadata chips reading like large buttons).
2. Fixed the shared overlay policy to require real series/season structure and a positive ordinal before rendering a position badge.
3. Fixed the shared metadata primitive with smaller type, symbols, padding, gaps, and title-row spacing.
4. Post-fix simulator evidence shows no `E0`/`E1` badges and compact duration/quality pills; the focused UI regression test passes.

## Implementation checklist

- [x] Movie-owned videos do not show episode badges.
- [x] Standalone videos do not infer episode badges from sort order.
- [x] Real episodes and seasons retain positive structural position badges.
- [x] Duration and quality pills use compact shared metrics.
- [x] Focused unit and iOS UI regression tests pass.

## Follow-up polish

No blocking polish items remain.

final result: passed
