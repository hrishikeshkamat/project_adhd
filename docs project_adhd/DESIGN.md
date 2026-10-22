# Session Widget: Design

Status: draft v0.1, 2026-10-22. Native macOS look. Quiet, scannable, no decoration. Sizes and row counts are estimates: tune them in SwiftUI previews.

## Principles

1. Scan first, read second. Project identity must be recognizable in under a second.
2. Follow the system. Use semantic colors and system fonts. No custom light or dark overrides.
3. Show what helps you resume: project, last prompt, how long ago.

## Row content

| Element | Style |
|---|---|
| Project chip | 4 pt wide rounded bar, color from a stable hash of `projectPath` (hue from hash, fixed saturation 0.55 and brightness 0.85). Never the only identifier, the name is always shown. |
| Project name | System font, 13 pt, semibold, `.primary`, one line, truncate tail |
| Last prompt | System font, 11 pt, regular, `.secondary`, truncate tail |
| Relative time | System font, 11 pt, `.tertiary`, trailing, `Text(date, style: .relative)` |

## Layouts by widget family

| Family | Layout | Rows |
|---|---|---|
| `systemMedium` | Two-line rows: name and time on line 1, prompt on line 2 | 3 |
| `systemLarge` | Dense single-line rows: chip, name (semibold) followed by prompt (secondary) sharing the line, time trailing | 10 |
| `systemExtraLarge` (if available on macOS, VERIFY) | Two columns of two-line rows | 12 |
| `systemSmall` | Not supported in v1. Omit from `supportedFamilies`. | 0 |

Approximate geometry for Large: about 354 pt tall. Header 28 pt, padding 16 pt top and bottom, rows at 28 pt each gives 10 rows. Adjust after previews.

## Header

Left: "Recent sessions" in 11 pt semibold `.secondary`. Right (only if data is stale, older than 10 minutes): "Updated <relative time>" in 11 pt `.tertiary`.

## States

| State | Behavior |
|---|---|
| Normal | Rows as above |
| Empty | Centered "No recent sessions" in `.secondary` |
| Stale | Header shows "Updated <time>". Rows still shown |
| No data file or access error | Centered "Open SessionBoard to refresh" in `.secondary` |
| Unknown `schemaVersion` | Same as error, with "Update SessionBoard" text |
| Prompt hidden | Omit the prompt text. Rows show chip, name, time only |

## Appearance

- `containerBackground(.background, for: .widget)`. No hard-coded backgrounds.
- Support the system rendering modes (full color, accented, vibrant). In accented mode the chip uses `widgetAccentable()`.
- Standard widget corner radius and margins from the system. Do not draw your own rounded container.
- Hover feedback on rows is system default for `Link`. Do not add custom effects.

## Interaction

- Each row is a `Link(destination: session.openURL)`. No buttons, no App Intents in v1.
- Clicking opens the Code tab in Claude Desktop for that folder. Desktop shows a confirm dialog. Do not try to work around it.

## Menu bar popover (host app)

- Reuses the same row view, two-line style, 12 rows, in a fixed 360 pt wide `MenuBarExtra` window.
- Footer: Settings (hide prompt text, launch at login, collapse by project in Phase 4), Quit.
- Menu bar icon: SF Symbol `clock.arrow.circlepath` or similar, template rendering.

## Accessibility

- Each row has an `accessibilityLabel` of "<project>, <prompt>, <relative time>" and the hint "Opens in Claude Desktop".
- Meet contrast with semantic colors. Do not rely on the chip color alone.
