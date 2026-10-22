import SwiftUI
import WidgetKit

/// Thin color bar per project. Hash is FNV-1a because `hashValue` changes every launch.
struct ProjectChip: View {
    let projectPath: String

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Self.color(for: projectPath))
            .frame(width: 4)
            .widgetAccentable()
    }

    static func color(for path: String) -> Color {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in path.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100_0000_01b3
        }
        let hue = Double(hash % 360) / 360
        return Color(hue: hue, saturation: 0.55, brightness: 0.85)
    }
}
