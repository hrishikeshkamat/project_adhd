import Foundation

/// Short "5m", "3h", "2d" labels for the CLI. Views use SwiftUI relative text instead.
public enum RelativeTime {
    public static func short(from date: Date, now: Date = Date()) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(date)))
        switch seconds {
        case ..<60: return "now"
        case ..<3600: return "\(seconds / 60)m"
        case ..<86_400: return "\(seconds / 3600)h"
        default: return "\(seconds / 86_400)d"
        }
    }
}
