# Swift Line-of-Code Cleanup

This document tracks the behavior-preserving cleanup that started after checkpoint
`801ea3b91cacf3ba64494336e5453b3ef042764b`.

## Measurement scope

Production Swift includes:

- `PrismediaShared`
- `PrismediaiOS`
- `PrismediaMac`
- `PrismediaTV`

Test Swift includes:

- `PrismediaCoreTests`
- `PrismediaiOSUITests`

Code, blank, and comment lines are measured with `cloc`. Raw lines and file-size distribution are measured
with `wc -l`. Generated build output and package checkouts are excluded.

## Baseline

| Metric | Baseline |
| --- | ---: |
| Production Swift files | 975 |
| Production code lines | 53,405 |
| Production raw lines | 59,181 |
| Test Swift files | 91 |
| Test code lines | 10,407 |
| Test raw lines | 12,956 |
| Production files at or above 200 raw lines | 64 |
| Raw lines in files at or above 200 lines | 22,451 |
| Production files at or below 10 raw lines | 253 |
| Raw lines in files at or below 10 lines | 1,683 |
| Median production Swift file | 26 raw lines |

## Cleanup rules

- Preserve user-visible behavior and external API contracts.
- Delete unreachable and speculative compatibility code before introducing abstractions.
- Put typed capability access on the Entity domain seam while keeping raw capabilities forward compatible.
- Share data lifecycle and policy, not platform navigation chrome or renderer-specific behavior.
- Keep feature-owned components inside their feature until multiple independent features use them.
- Do not count file splitting or file moves as line-of-code savings.
- Validate shared behavior with durable seam-level tests; validate view composition with builds and previews.

## Results

Final metrics will be recorded after the cleanup and full validation pass.
