# Session Widget: Build Plan

Status: draft v0.1, 2026-10-22. Tick boxes as work completes. Do not start a phase until the previous gate passes.

## Status, 2026-10-22

All [CC] code for Phases 1 to 4 is written in `session-widget/` but has not been compiled, tested, or run. Phase 0 is still open. Boxes below stay unticked until each item is verified on the Mac. Start with Phase 0, then `swift test`, then `docs/session-widget/XCODE_SETUP.md`.

Roles: **[CC]** Claude Code does it. **[YOU]** the user does it, usually in Xcode.

## Phase 0: Spike and verify (about 0.5 day)

Goal: turn every VERIFY item into a fact before writing app code. Output: `docs/session-widget/FINDINGS.md`.

- [ ] [CC] Record `sw_vers`, `xcodebuild -version`, `swift --version` in FINDINGS.md.
- [ ] [CC] Inspect `~/.claude/projects` read-only. Report folder naming, file counts, and the field names actually present in `.jsonl` lines (use `jq` on keys only, never paste prompt text). Compare to the hypotheses in ARCHITECTURE.md. Answers Q2.
- [ ] [YOU] Start one Code-tab session in Claude Desktop in a throwaway folder and send one message. [CC] checks whether a new `.jsonl` appeared and which path. Answers Q1.
- [~] [CC] (docs read, hand test pending) Read `https://support.claude.com/en/articles/14729294-open-claude-desktop-with-a-link`. Record the exact folder parameter for `claude://code/new`. Test with `open "claude://code/new?<param>=<encoded folder>"`. Record whether the composer is prefilled and that the folder confirm dialog appears. Answers Q3.
- [ ] [CC] Check whether `WidgetFamily.systemExtraLarge` is available for macOS targets with the installed SDK. Answers Q4.
- [ ] [YOU] In Xcode > Settings > Accounts, confirm which team is signed in (free or paid). [CC] chooses Option A or B from ARCHITECTURE.md and records it. Answers Q5.
- [ ] [CC] Update ARCHITECTURE.md and SCOPE.md where reality differs from the docs.

**Gate:** FINDINGS.md answers Q1 to Q5. If Q1 is "no" (Desktop sessions are stored elsewhere), stop and re-scope with the user.

## Phase 1: SessionCore package and CLI (about 1 to 1.5 days)

Goal: correct session list from real files, tested, no UI.

- [ ] [CC] Create `session-widget/SessionCore` Swift package (library plus a small executable target `sessionboard-cli`).
- [ ] [CC] Models: `Session`, `SessionsFile` (the JSON contract), `SessionSource` protocol.
- [ ] [CC] `ClaudeCodeSource` implementing the parser rules in ARCHITECTURE.md (tail reads, filters, dedupe).
- [ ] [CC] `DeepLink.codeSession(folder:)` with percent-encoding, using the parameter from FINDINGS.md.
- [ ] [CC] Synthetic fixtures and unit tests for every case listed under Testing in ARCHITECTURE.md.
- [ ] [CC] Perf test: 500 synthetic files, scan under 2 seconds.
- [ ] [CC] CLI: `sessionboard-cli list --limit 15` prints project, time ago, truncated prompt. `--json` prints the contract file.
- [ ] [YOU] Run the CLI on your real data and compare with what you remember working on.

**Gate:** `swift test` passes. CLI output matches reality for your 10 most recent sessions. AC2 and AC7 verified for the core.

## Phase 2: Host app and menu bar (about 1 day)

Goal: a running app that scans, writes the JSON, and shows a clickable list in the menu bar.

Manual Xcode steps first:

- [ ] [YOU] Xcode > File > New > Project > macOS > App. Product name `SessionBoard`, Interface SwiftUI, Language Swift, your team, save inside `session-widget/`.
- [ ] [YOU] File > New > Target > Widget Extension. Name `SessionWidget`. Untick "Include Configuration App Intent" and "Include Live Activity".
- [ ] [YOU] File > Add Package Dependencies > Add Local, choose `session-widget/SessionCore`. Link the library to both targets.
- [ ] [YOU] Signing & Capabilities: if Option A, add App Groups to both targets with the same group, and remove App Sandbox from the host target. If Option B, skip App Groups and let [CC] add the widget exception entitlement.
- [ ] [YOU] Host target Info: set "Application is agent (UIElement)" to YES.
- [ ] [YOU] Tell Claude Code: "Xcode project is ready, continue Phase 2."

Then:

- [ ] [CC] `MenuBarExtra` with the two-line row view from DESIGN.md. Click a row opens its `openURL` via `NSWorkspace`.
- [ ] [CC] Scanner service: FSEvents on `~/.claude/projects` (2 s latency) plus 60 s timer. Debounce writes.
- [ ] [CC] Write `sessions.json` atomically, mode 0600, to the Option A or B location. Skip the write and the reload if content is unchanged.
- [ ] [CC] Call `WidgetCenter.shared.reloadTimelines(ofKind:)` after a changed write.
- [ ] [CC] `os.Logger` with private interpolation only. No snippet text in logs.
- [ ] [CC] `xcodebuild` clean build, no new warnings.

**Gate:** with the app running, start a new session in any project, and it appears in the popover within 60 seconds. Click opens Claude Desktop with the folder confirm. AC3, AC4 (popover), AC6 verified.

## Phase 3: Widget (about 1 to 1.5 days)

Goal: the widget on the desktop, matching DESIGN.md.

- [ ] [CC] `StaticConfiguration` widget, `TimelineProvider` reads `sessions.json`, one entry, refresh `.after(now + 5 min)`.
- [ ] [CC] Shared row view moved to a small shared target or `SessionCore` UI-free helpers, so popover and widget stay consistent.
- [ ] [CC] Medium, Large, and (if Q4 is yes) ExtraLarge layouts. Omit `systemSmall`.
- [ ] [CC] All states in DESIGN.md with SwiftUI previews and sample JSON.
- [ ] [CC] Rows as `Link`. Chip color hash. `containerBackground`. Accented rendering support.
- [ ] [YOU] Run the host app from Xcode once, then right-click the desktop > Edit Widgets > SessionBoard, and add the Large widget.

Manual checklist:

- [ ] Large shows 10 rows with real data.
- [ ] Clicking a row opens Claude Desktop with the right folder.
- [ ] New session appears within 5 minutes with no action.
- [ ] Light and dark appearance both correct.
- [ ] Widget shows the error state if `sessions.json` is deleted, and recovers when the host rewrites it.

**Gate:** AC1, AC2, AC3, AC4, AC5 pass on the real desktop.

## Phase 4: Polish and harden (about 0.5 to 1 day)

- [ ] [CC] Settings: hide prompt text (writes JSON without `lastPrompt`, AC8), launch at login via `SMAppService`, collapse-by-project toggle (D1).
- [ ] [CC] Handle missing `~/.claude`, unreadable files, and an unknown schema version without crashing.
- [ ] [CC] Idle CPU check with Activity Monitor over 10 minutes, record result in FINDINGS.md.
- [ ] [CC] Update README with install steps, known limitations, and a screenshot placeholder.
- [ ] [CC] Tag `v0.1.0`.
- [ ] [YOU] One week of real use. Note what annoys you, then decide what to do next.

**Gate:** all of AC1 to AC8 pass. FINDINGS.md has no open blocking items.

## Later (not now, do not build)

- Resume the exact session via `claude --resume <id>` in Terminal as a secondary action.
- Live status (running, waiting) using Claude Code hooks.
- Group rows by workstream.
- Codex and Gemini sources via the `SessionSource` protocol.
- Phone view (needs a sync path, separate design).
- Re-check for a deep link that reopens an existing session. If Anthropic adds one, this widget gets much better.

## Effort summary

| Phase | Estimate |
|---|---|
| 0 | 0.5 day |
| 1 | 1 to 1.5 days |
| 2 | 1 day |
| 3 | 1 to 1.5 days |
| 4 | 0.5 to 1 day |
| **Total** | **3 to 5 working days** |
