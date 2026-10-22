import Foundation

public enum SessionRanking {
    /// Resumed sessions can copy history into a new file. Same folder plus same last prompt is one row.
    public static func dedupe(_ sessions: [Session]) -> [Session] {
        var seen = Set<String>()
        return sortedNewestFirst(sessions).filter { session in
            guard let prompt = session.lastPrompt else { return true }
            return seen.insert(session.projectPath + "\u{0}" + prompt).inserted
        }
    }

    /// One row per project folder, keeping the newest session (decision D1 toggle).
    public static func collapseByProject(_ sessions: [Session]) -> [Session] {
        var seen = Set<String>()
        return sortedNewestFirst(sessions).filter { seen.insert($0.projectPath).inserted }
    }

    public static func sortedNewestFirst(_ sessions: [Session]) -> [Session] {
        sessions.sorted { $0.lastActivity > $1.lastActivity }
    }
}
