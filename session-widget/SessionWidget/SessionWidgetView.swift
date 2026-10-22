import SessionCore
import SwiftUI
import WidgetKit

struct SessionWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SessionEntry

    private static let staleAfter: TimeInterval = 10 * 60

    var body: some View {
        switch entry.content {
        case .loaded(let file): loaded(file)
        case .noData: message("Open SessionBoard to refresh")
        case .needsUpdate: message("Update SessionBoard")
        }
    }

    private var rowCount: Int {
        switch family {
        case .systemMedium: return 3
        case .systemExtraLarge: return 12
        default: return 10
        }
    }

    private var rowStyle: SessionRowView.Style {
        family == .systemLarge ? .dense : .twoLine
    }

    @ViewBuilder
    private func loaded(_ file: SessionsFile) -> some View {
        let sessions = Array(file.sessions.prefix(rowCount))
        VStack(alignment: .leading, spacing: 0) {
            header(file)
            if sessions.isEmpty {
                message("No recent sessions")
            } else {
                VStack(spacing: 0) {
                    ForEach(sessions) { session in
                        Link(destination: session.openURL) {
                            SessionRowView(session: session, style: rowStyle)
                                .frame(maxHeight: .infinity)
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private func header(_ file: SessionsFile) -> some View {
        HStack {
            Text("Recent sessions")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
            if entry.date.timeIntervalSince(file.generatedAt) > Self.staleAfter {
                (Text("Updated ") + Text(file.generatedAt, style: .relative))
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(height: 20, alignment: .top)
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Large", as: .systemLarge) {
    SessionWidget()
} timeline: {
    SessionEntry(date: Date(), content: .loaded(SampleData.file))
    SessionEntry(date: Date(), content: .loaded(SampleData.hiddenFile))
    SessionEntry(date: Date(), content: .loaded(SampleData.staleFile))
    SessionEntry(date: Date(), content: .loaded(SessionsFile(generatedAt: Date(), hideSnippets: false, sessions: [])))
    SessionEntry(date: Date(), content: .noData)
    SessionEntry(date: Date(), content: .needsUpdate)
}

#Preview("Medium", as: .systemMedium) {
    SessionWidget()
} timeline: {
    SessionEntry(date: Date(), content: .loaded(SampleData.file))
}
