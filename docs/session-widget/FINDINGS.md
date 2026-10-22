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
