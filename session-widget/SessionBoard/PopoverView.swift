import SwiftUI
import SessionCore

struct PopoverView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openURL) private var openURL
    @State private var showingSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent sessions")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            content

            Divider()
            if showingSettings {
                SettingsView().padding(12)
                Divider()
            }
            footer
        }
        .frame(width: 360)
    }

    @ViewBuilder
    private var content: some View {
        let sessions = Array(model.file?.sessions.prefix(12) ?? [])
        if let problem = model.problem, sessions.isEmpty {
            placeholder(problem)
        } else if model.file == nil {
            placeholder("Scanning")
        } else if sessions.isEmpty {
            placeholder("No recent sessions")
        } else {
            VStack(spacing: 0) {
                ForEach(sessions) { session in
                    Button { openURL(session.openURL) } label: {
                        SessionRowView(session: session, style: .twoLine)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func placeholder(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 80)
    }

    private var footer: some View {
        HStack {
            Button(showingSettings ? "Done" : "Settings") { showingSettings.toggle() }
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
