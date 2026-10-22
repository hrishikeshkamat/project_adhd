import Foundation

/// Decides what counts as a real user prompt and normalizes it for one-line display.
public enum PromptFilter {
    public static let maxLength = 160

    // Messages Claude Code injects on the user's behalf.
    static let wrapperPrefixes = [
        "<command-name>",
        "<command-message>",
        "<command-args>",
        "<local-command",
        "<system-reminder>",
        "Caveat: The messages below",
        "[Request interrupted",
    ]

    static func isRealPrompt(_ record: TranscriptRecord) -> Bool {
        guard record.type == "user", !record.isSidechain, !record.isMeta,
              let text = record.userText else { return false }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return !wrapperPrefixes.contains { trimmed.hasPrefix($0) }
    }

    public static func normalize(_ text: String) -> String {
        let collapsed = text.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        guard collapsed.count > maxLength else { return collapsed }
        return String(collapsed.prefix(maxLength - 1)) + "\u{2026}"
    }
}
