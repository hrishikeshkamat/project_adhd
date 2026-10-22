# Session Widget: Phase 0 Findings

Status: partial, 2026-10-22. Gathered from a Linux cloud session. Items needing the user's Mac are marked PENDING.

## Environment (PENDING, needs the Mac)

- `sw_vers`: PENDING
- `xcodebuild -version`: PENDING
- `swift --version`: PENDING

## Q1: Do Desktop Code-tab sessions write to `~/.claude/projects`?

PENDING. Needs a test session in Claude Desktop on the Mac.

## Q2: Transcript field names and resumed sessions

PENDING. Needs read-only inspection of `~/.claude/projects` on the Mac (keys only).

## Q3: `claude://code/new` folder parameter

Source: support article 14729294, read 2026-10-22.

- Folder parameter is `folder`: an absolute path, URL-encoded. Only the first `folder` value is applied.
- Other parameters: `q` (alias `prompt`) prefills the composer; `file` is accepted but not supported yet. We pass neither.
- A folder from a link is treated as untrusted. Desktop asks the user to confirm it every time, even for folders trusted before. Matches SCOPE limitation 1.
- If Desktop is not running, the OS launches it first.
- Without `q` the composer should be empty. PENDING hand test with `open "claude://code/new?folder=%2Ftmp%2Ftest"` on the Mac.

## Q4: `systemExtraLarge` on macOS

PENDING. Needs the installed SDK.

## Q5: Signing team and App Groups

PENDING. User checks Xcode > Settings > Accounts.

## Decisions taken

- Deep link format fixed as `claude://code/new?folder=<percent-encoded absolute path>`.
- 2026-10-22: user asked to build the full system before Phase 0 finished. All code for Phases 1 to 4 is written but has **never been compiled or run**: the cloud session had no Swift toolchain (download host blocked, no Docker). Parser field names follow the ARCHITECTURE hypotheses and still need Q2.
- Test fixtures are generated in code (`FixtureBuilder`) instead of files under `Fixtures/`. Keeps them synthetic and avoids SwiftPM resource bundles.
- Only top-level `*.jsonl` in each project folder are read. Subfolders are assumed to hold subagent transcripts. VERIFY with Q2.
- Sidechain detection: a file whose head records are all `isSidechain == true` is skipped.
- If no prompt is found in the 1 MB tail, the parser falls back to the last prompt in the 16 KB head instead of dropping the session.
- Default storage is Option A (`AppConfig.storage = .appGroup`, id `group.com.hrishikesh.sessionboard`). Change both in `session-widget/Shared/AppConfig.swift` after Q5.
- `systemExtraLarge` is left out of `supportedFamilies` until Q4. The view already handles it.
- `sessions.json` is written via a temp file created with mode 0600, then `rename(2)`, so it is never briefly world-readable.
