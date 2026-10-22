# Session Widget: Architecture

Status: draft v0.1, 2026-10-22. Items marked VERIFY are hypotheses to test in Phase 0.

## Overview

```
~/.claude/projects/**/*.jsonl
        |  read-only (FSEvents + 60s poll)
        v
+------------------------------+
| SessionBoard.app             |  menu bar agent (LSUIElement), not sandboxed (Option A)
|  SessionCore: scan, parse,   |
|  rank, build JSON            |
|  MenuBarExtra popover        |
+--------------+---------------+
               | writes sessions.json (atomic, mode 0600)
               v
   App Group container (Option A)  or  ~/Library/Application Support/SessionBoard/ (Option B)
               |
               v
+------------------------------+
| SessionWidget.appex          |  sandboxed, read-only consumer
|  TimelineProvider -> JSON    |
|  SwiftUI rows wrapped in Link|
+--------------+---------------+
               | click
               v
   claude://code/new?folder=<encoded path>  ->  Claude Desktop (Code tab, folder confirm)
```

Why the split: widget extensions are sandboxed and cannot read `~/.claude`. The host app is the only reader and hands the widget a small JSON file.

## Components

| Component | Type | Responsibility |
|---|---|---|
| `SessionCore` | Local Swift package, no UI | Models, `SessionSource` protocol, `ClaudeCodeSource`, ranking, JSON encode and decode, deep link builder |
| `SessionBoard` | macOS app (LSUIElement) | Watches the transcript folder, runs `SessionCore`, writes `sessions.json`, reloads widget timelines, shows menu bar popover, settings, launch at login |
| `SessionWidget` | WidgetKit extension | Reads `sessions.json`, renders rows, each row a `Link` to the deep link |

## Source adapter (for future tools)

```swift
public protocol SessionSource {
    var id: String { get }                       // "claude-code"
    func recentSessions(limit: Int) throws -> [Session]
}

public struct Session: Codable, Identifiable, Equatable {
    public let id: String                        // session uuid
    public let source: String
    public let projectName: String               // last path component of projectPath
    public let projectPath: String
    public let lastPrompt: String?               // nil when hidden or absent
    public let lastActivity: Date
    public let openURL: URL
}
```

Only `ClaudeCodeSource` is built in v1. Later candidates: `~/.codex/sessions`, `~/.gemini/tmp` (paths used by other open-source monitors; VERIFY before use).

## Shared data contract: `sessions.json`

```json
{
  "schemaVersion": 1,
  "generatedAt": "2026-10-22T09:30:00Z",
  "hideSnippets": false,
  "sessions": [
    {
      "id": "7c1f0c2e-0000-0000-0000-000000000000",
      "source": "claude-code",
      "projectName": "example-project",
      "projectPath": "/Users/<you>/dev/example-project",
      "lastPrompt": "first 160 chars of last real user prompt, single line",
      "lastActivity": "2026-10-22T09:12:03Z",
      "openURL": "claude://code/new?folder=%2FUsers%2F<you>%2Fdev%2Fexample-project"
    }
  ]
}
```

Rules:
- Dates are ISO 8601 UTC. Sessions sorted by `lastActivity` descending. Host writes at most 30 entries.
- When "hide prompt text" is on, the host omits `lastPrompt` entirely. Privacy is enforced at write time, not in the view.
- Write atomically (temp file then rename), file mode 0600.
- The widget treats an unknown `schemaVersion` as an error state, not a crash.

## Claude Code transcript parser (VERIFY all field names against real files)

Location: `~/.claude/projects/<encoded-cwd>/<session-uuid>.jsonl`. One JSON object per line.

Hypothesized fields: `type` (`user`, `assistant`, `summary`, `system`), `message.role`, `message.content` (string, or array of blocks with `type` of `text`, `tool_use`, `tool_result`), `cwd`, `sessionId`, `timestamp`, `isSidechain`, `isMeta`.

Rules:
1. **Project path:** take `cwd` from inside the records. Do not decode the folder name, because the encoding is lossy (path separators and hyphens collide).
2. **Candidates:** enumerate `*.jsonl`, sort by file modification date, take the newest 40, parse only those.
3. **Reading:** read the first 16 KB for `cwd`. Read the last 128 KB for the last real user prompt and last timestamp. If no real prompt is in the tail, widen to 1 MB, then give up and leave `lastPrompt` nil. Never load whole files.
4. **Real user prompt:** `type == "user"`, not `isSidechain`, not `isMeta`, and content is a string or has at least one `text` block. Exclude tool-result-only messages and wrapper messages (for example starting with `<command-name>`, `<local-command`, `<command-message>`, "Caveat: The messages below", or "[Request interrupted"). Collapse whitespace, trim to 160 characters.
5. **Skip** files that are sidechain (subagent) transcripts, empty, or have no user prompt at all.
6. **Last activity:** newest valid `timestamp` in the tail, falling back to file modification date.
7. **Dedupe (VERIFY):** if resumed sessions copy prior history into a new file, collapse entries with the same `cwd` and identical last prompt, keeping the newest.
8. **Tolerance:** a malformed line is skipped, never fatal. Unknown fields are ignored.

## Deep link

- Scheme: `claude://code/new` opens Claude Code in Claude Desktop. Documented at `https://support.claude.com/en/articles/14729294-open-claude-desktop-with-a-link`.
- Folder parameter: `folder` (absolute path, URL-encoded, only the first value applied). See FINDINGS.md Q3.
- Percent-encode the folder path.
- Never pass `q` or any prompt text. Pass only the folder.
- Desktop shows a confirmation dialog for folders from links. This is expected behavior and cannot be skipped.
- Build the URL in `SessionCore` (`DeepLink.codeSession(folder:)`) and unit test the encoding, including spaces and non-ASCII characters.

## Refresh strategy

- Host watches `~/.claude/projects` with an FSEvents stream (2 second latency), plus a 60 second timer as a backstop.
- After a scan, if the JSON content changed, write it and call `WidgetCenter.shared.reloadTimelines(ofKind:)`.
- Widget timeline: one entry, policy `.after(now + 5 minutes)`. Relative times are rendered with `Text(date, style: .relative)` so they tick without reloads.
- WidgetKit may throttle reloads. This is a known limitation. The menu bar popover is the live view.

## Sandbox and entitlements

The widget extension must be sandboxed. Two options for getting data to it:

**Option A (preferred if available):**
- Host app: App Sandbox off (it must read `~/.claude`). Hardened runtime not required for local use.
- Both targets: App Groups capability, same group id. Let Xcode generate and register it in Signing and Capabilities. On macOS the id format has team-prefix rules; use what Xcode produces. VERIFY.
- Both read and write `sessions.json` in `FileManager.containerURL(forSecurityApplicationGroupIdentifier:)`.

**Option B (fallback, personal use only):**
- Host writes to `~/Library/Application Support/SessionBoard/sessions.json`.
- Widget target gets entitlement `com.apple.security.temporary-exception.files.home-relative-path.read-only` with value `/Library/Application Support/SessionBoard/`. VERIFY it is honored for widgets.
- Not suitable for App Store distribution. Acceptable here.

Decide in Phase 0 after checking the signing team type.

## Security and privacy

- Transcripts are private. The host extracts at most one 160 character snippet per session and nothing else.
- `sessions.json` holds snippets in plain text on disk. Mode 0600, inside the app container or app support folder, never logged.
- No network entitlement on either target.
- Treat transcript text as untrusted data for display only. It never feeds URLs, shell commands, or prompts.
- Logging uses `os.Logger` with paths and counts only, never snippet text. Use `privacy: .private` on any dynamic value.

## Testing

- `SessionCore` unit tests run with `swift test`, using synthetic fixtures in `Tests/SessionCoreTests/Fixtures/`.
- Fixture cases: normal session, tool-result-only user messages, command wrapper messages, sidechain file, malformed line, empty file, very large file, non-ASCII project path and prompt, path with spaces, resumed-session duplicate.
- Perf test: generate 500 synthetic files, assert scan time under 2 seconds.
- Widget: SwiftUI previews with sample JSON for every size and state in `DESIGN.md`.
- Manual: the checklist at the end of Phase 3 in `PLAN.md`.

## Repo layout (target)

```
session-widget/
  SessionCore/                 Swift package
    Package.swift
    Sources/SessionCore/
    Tests/SessionCoreTests/Fixtures/
  SessionBoard.xcodeproj
  SessionBoard/                host app sources
  SessionWidget/               widget extension sources
```
