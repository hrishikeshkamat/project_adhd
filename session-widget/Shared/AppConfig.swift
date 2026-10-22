import Foundation

/// Values both targets must agree on. Set `storage` and `appGroupID` from FINDINGS.md Q5.
enum AppConfig {
    enum Storage {
        /// Option A: shared App Group container. Needs the App Groups capability on both targets.
        case appGroup
        /// Option B: Application Support plus a read-only home-relative exception on the widget.
        case applicationSupport
    }

    static let storage: Storage = .appGroup
    /// Must match the group Xcode registers in Signing and Capabilities, character for character.
    static let appGroupID = "group.com.hrishikesh.sessionboard"
    static let widgetKind = "SessionWidget"
    static let fileName = "sessions.json"
    static let logSubsystem = "com.hrishikesh.sessionboard"
}
