# project_adhd

Personal tools that reduce context-switching overhead. Built and extended with Claude Code.

## Tools

| Tool | What it does | Status |
|---|---|---|
| session-widget | macOS desktop widget listing recent Claude Code sessions. Click a row to open Claude Desktop's Code tab in that project's folder. | Code written, not yet compiled. Phase 0 open. |

## Running the build with Claude Code

1. Clone the repo, `cd project_adhd`, run `claude`.
2. Prompt: `Read CLAUDE.md, then start Phase 0 of docs/session-widget/PLAN.md.`
3. Review `docs/session-widget/FINDINGS.md` (written by Phase 0) before approving Phase 1.
4. Phase 2 has a short manual Xcode step. PLAN.md lists it exactly.

## Install (session-widget)

1. `cd session-widget/SessionCore && swift test`
2. Follow `docs/session-widget/XCODE_SETUP.md`.

Known limitations: a click opens a **new** Code session in the folder, not the old thread, and Desktop asks you to confirm the folder each time. Refresh is not real-time. The transcript format is undocumented and can change.

## Docs

| File | Purpose |
|---|---|
| `CLAUDE.md` | Rules Claude Code follows in this repo |
| `docs/session-widget/SCOPE.md` | Goal, non-goals, acceptance criteria, risks, open questions |
| `docs/session-widget/ARCHITECTURE.md` | Components, data contract, parser spec, entitlements, deep link |
| `docs/session-widget/DESIGN.md` | Widget layout, sizes, states, appearance |
| `docs/session-widget/PLAN.md` | Phased build with verification gates and checklists |
| `docs/session-widget/FINDINGS.md` | Phase 0 results and build decisions |
| `docs/session-widget/XCODE_SETUP.md` | Manual Xcode project and signing steps |

## Layout (target)

```
project_adhd/
  README.md
  CLAUDE.md
  docs/session-widget/
  session-widget/          Xcode project and SessionCore package (created in Phases 1 and 2)
```
