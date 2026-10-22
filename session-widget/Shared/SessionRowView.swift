import SwiftUI
import SessionCore

/// One row, shared by the popover and the widget so they stay consistent.
struct SessionRowView: View {
    enum Style {
        /// Name and time on line 1, prompt on line 2.
        case twoLine
        /// Name then prompt on one line, time trailing.
        case dense
    }

    let session: Session
    let style: Style

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            ProjectChip(projectPath: session.projectPath)
                .frame(height: style == .dense ? 16 : 30)
            switch style {
            case .twoLine: twoLine
            case .dense: dense
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Opens in Claude Desktop")
    }

    private var twoLine: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                name
                Spacer(minLength: 6)
                time
            }
            if let prompt = session.lastPrompt {
                Text(prompt)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }

    private var dense: some View {
        HStack(spacing: 6) {
            name.layoutPriority(1)
            if let prompt = session.lastPrompt {
                Text(prompt)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: 6)
            time
        }
    }

    private var name: some View {
        Text(session.projectName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    private var time: some View {
        Text(session.lastActivity, style: .relative)
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)
            .monospacedDigit()
            .lineLimit(1)
            .fixedSize()
    }

    private var accessibilityText: String {
        let ago = RelativeDateTimeFormatter().localizedString(for: session.lastActivity, relativeTo: Date())
        return [session.projectName, session.lastPrompt, ago].compactMap { $0 }.joined(separator: ", ")
    }
}
