# Session Widget: Scope (v1)

Status: draft v0.1, 2026-10-22. Working name: SessionBoard (rename freely).

## Problem

Switching between many projects across Claude sessions makes it hard to see where work was last happening. There is no at-a-glance view on the desktop outside the Claude app itself.

## Goal

A native macOS widget that shows the 10 or more most recent Claude Code sessions: project name, last prompt, time since last activity. Clicking a row opens Claude Desktop's Code tab in that project's folder.

## User stories

1. Glance at the desktop and see the last N sessions with project names and what I last asked.
2. Click a row and Claude Desktop comes forward, pointed at the right folder.
3. The list stays current without manual action.
4. Hide prompt text when screen sharing.

## Acceptance criteria

| ID | Criterion |
|---|---|
| AC1 | Large widget lists at least 10 sessions, ordered by last activity (macOS 14+). Extra-large lists 12 if the family is available on macOS. |
| AC2 | Each row shows project folder name, last user prompt (one line, truncated), relative time. |
| AC3 | Clicking a row opens `claude://code/new` with the correct folder. Claude Desktop opens the Code tab and asks to confirm the folder. |
| AC4 | A session started in any project appears within 5 minutes with no manual action. |
| AC5 | Correct in light and dark appearance. |
| AC6 | `~/.claude` is only read. Nothing is written outside the app's own container. Zero network calls. |
| AC7 | With 500+ session files present, a refresh finishes in under 2 seconds and the app idles at near-zero CPU. |
| AC8 | "Hide prompt text" removes snippets from both the UI and the shared JSON file. |

## Non-goals (v1)

- Reopening the exact existing thread. No supported deep link for this was found as of 2026-10-22.
- claude.ai chats and Cowork sessions.
- Codex, Gemini, or other tools. The architecture allows them; none are built.
- Phone, iOS, Windows, Linux.
- Search, filters, editing or deleting sessions, token or cost analytics.
- Live status (running, waiting). Needs hooks. Deferred.
- App Store distribution and notarization.

## Known limitations (accept up front)

1. A click opens a **new** Code session in the folder, not the old thread. The last-prompt text is the orientation aid. Desktop asks to confirm the folder on every link.
2. Not real-time. WidgetKit throttles reloads. Expect seconds to minutes of lag.
3. Depends on an undocumented transcript format. A Claude Code update can break the parser.
4. Assumes Desktop Code-tab sessions write to `~/.claude/projects`. VERIFY in Phase 0. If false, scope changes.

## Constraints

- macOS 14+ (desktop widgets), Xcode installed, Swift and SwiftUI.
- Zero third-party dependencies. Personal use, local signing.
- Free Apple ID team is acceptable unless it blocks App Groups. If blocked, use Option B in `ARCHITECTURE.md`.

## Decisions

| ID | Decision | Reason |
|---|---|---|
| D1 | One row per session, as requested. Add a "one row per project" toggle in Phase 4. | Click granularity is the folder, so two rows from one folder behave the same. The toggle lets the user choose. |
| D2 | Split into a host app plus a widget extension. Only the host reads `~/.claude`. | The widget is sandboxed and cannot read that folder. |
| D3 | Native Swift and SwiftUI. | WidgetKit requires it, and Xcode is available. |
| D4 | The host app also shows a menu bar popover that reuses the same row view. | Cheap fallback if widget refresh is too laggy, and a faster dev loop. |

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Transcript schema differs from the spec or changes later | Medium | High | Phase 0 inspection, tolerant parser that skips bad lines, fixtures, `schemaVersion` in output |
| Desktop Code sessions are stored elsewhere | Low to medium | High | Phase 0 check before any code |
| App Group unavailable on free team | Medium | Medium | Option B (read-only home-relative exception) |
| Widget refresh too slow to feel useful | Medium | Medium | Host calls `reloadTimelines` on change, 5 minute backstop, menu bar popover as live view |
| Deep link parameter names differ from assumption | Medium | Low | Read the support page in Phase 0 and test by hand |
| Duplicate rows from resumed sessions | Medium | Low | Dedupe rule in `ARCHITECTURE.md`, VERIFY with real files |

## Open questions (resolve in Phase 0, answers go in FINDINGS.md)

- Q1: Do Desktop Code-tab sessions create `.jsonl` files in `~/.claude/projects`?
- Q2: Exact transcript field names and how resumed sessions appear.
- Q3: Exact `claude://code/new` parameter name for the folder, and whether the composer is prefilled.
- Q4: Is `systemExtraLarge` available for widgets on this macOS version?
- Q5: Does the user's Apple ID team allow App Groups? macOS and Xcode versions?

## Effort

3 to 5 working days. The uncertainty is signing, entitlements, and widget refresh behavior, not parsing logic.
