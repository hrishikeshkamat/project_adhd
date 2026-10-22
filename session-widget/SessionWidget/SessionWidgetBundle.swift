import SwiftUI
import WidgetKit

@main
struct SessionWidgetBundle: WidgetBundle {
    var body: some Widget {
        SessionWidget()
    }
}

struct SessionWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppConfig.widgetKind, provider: SessionProvider()) { entry in
            SessionWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Recent sessions")
        .description("Your latest Claude Code sessions. Click one to open its folder in Claude.")
        // ExtraLarge on macOS is unconfirmed (FINDINGS Q4). Add `.systemExtraLarge` once verified.
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
