# Session Widget: Xcode Setup

The sources exist. The Xcode project does not, because it has to be created and signed on your Mac. About 10 minutes.

## 1. Check the core first

```
cd session-widget/SessionCore
swift test
swift run sessionboard-cli list --limit 15
```

Fix anything here before touching Xcode. The CLI is read-only on `~/.claude`.

## 2. Create the project

1. Xcode > File > New > Project > macOS > App. Product name `SessionBoard`, Interface SwiftUI, Language Swift, your team. Save in `session-widget/`.
2. Delete the generated `ContentView.swift` and `SessionBoardApp.swift`.
3. Drag the existing `session-widget/SessionBoard/` sources into the SessionBoard target. Uncheck "Copy items if needed".
4. File > New > Target > Widget Extension. Name `SessionWidget`. Untick "Include Configuration App Intent" and "Include Live Activity". Delete its generated Swift files, then add the existing `session-widget/SessionWidget/*.swift` to the widget target.
5. Add every file in `session-widget/Shared/` to **both** targets.
6. File > Add Package Dependencies > Add Local > `session-widget/SessionCore`. Link the `SessionCore` library to both targets.
7. SessionBoard target > Info: add `Application is agent (UIElement)` = YES.

## 3. Signing and data sharing

**Option A (App Groups):**
- Both targets: add the App Groups capability with the same group id.
- Copy the exact id Xcode shows into `AppConfig.appGroupID`.
- SessionBoard target: remove App Sandbox. It must read `~/.claude`.

**Option B (no App Groups, free team fallback):**
- Set `AppConfig.storage = .applicationSupport`.
- SessionWidget target > Build Settings > Code Signing Entitlements = `SessionWidget/OptionB.entitlements`.
- SessionBoard target: remove App Sandbox.

Neither target needs the network entitlement. Leave it off.

## 4. Build and run

```
xcodebuild -scheme SessionBoard -destination 'platform=macOS' build
```

Run from Xcode once, then right-click the desktop > Edit Widgets > SessionBoard > Large.
