# CLAUDE.md

Repo of small personal tools. Current tool: `session-widget` (macOS widget listing recent Claude Code sessions). Owner: Hrishikesh. Date of docs: 2026-10-22.

## Read first, in this order

1. `docs/session-widget/SCOPE.md`
2. `docs/session-widget/ARCHITECTURE.md`
3. `docs/session-widget/DESIGN.md`
4. `docs/session-widget/PLAN.md`

## How to work

- Follow `PLAN.md` phases in order. Do not start a phase until the previous phase's verification gate passes. Tick the checkboxes in `PLAN.md` as you go.
- Anything marked `VERIFY` in the docs is a hypothesis, not a fact. Phase 0 exists to test them. If reality differs, update the docs first, then code. Record results in `docs/session-widget/FINDINGS.md`.
- Small commits, one task each. Imperative messages, no fluff.
- If a decision is not covered by the docs and changes scope, cost, or the user's machine settings, stop and ask. Otherwise decide, note it in `FINDINGS.md`, and continue.

## Hard rules

- Read-only on `~/.claude`, `~/.codex`, `~/.gemini`. Never write, move, or delete anything there.
- Transcripts contain private client and project content. Never paste real transcript content into the repo, docs, commit messages, issues, or logs. All test fixtures must be synthetic.
- No network calls from the app or widget. No analytics. No telemetry.
- Zero third-party dependencies unless `PLAN.md` explicitly allows one. Prefer Apple frameworks.
- The deep link URL contains only the folder path. Never put prompt text, or any transcript-derived text, into a URL or a `q` parameter.
- Do not change the user's system settings, signing identities, or Keychain. Ask the user to do signing steps in Xcode.
- Do not build anything listed under Non-goals in `SCOPE.md`.

## Tech baseline

- Swift 5.9+, SwiftUI, WidgetKit, deployment target macOS 14.0 (confirm in Phase 0 with `sw_vers` and `xcodebuild -version`).
- `SessionCore` is a local Swift package with no UI imports, so it builds and tests from the CLI: `swift test` inside `session-widget/SessionCore`.
- App and widget builds: `xcodebuild -scheme SessionBoard -destination 'platform=macOS' build`. Run it before declaring a phase done.

## Style

- Plain, short comments that explain why, not what.
- No em dashes in docs, comments, or commit messages. Use commas, colons, or periods.
- Keep files small. One type per file where practical.

## Definition of done (any task)

1. Builds clean with no new warnings.
2. Unit tests for the touched logic pass (`swift test`).
3. The relevant acceptance criteria in `SCOPE.md` are checked or explicitly deferred with a reason.
4. `PLAN.md` checkboxes and `FINDINGS.md` updated.
