import Foundation

/// Reads `~/.claude/projects/<encoded-cwd>/<session>.jsonl`. Read-only, never writes.
public struct ClaudeCodeSource: SessionSource, Sendable {
    public let id = "claude-code"
    public let projectsRoot: URL
    public var candidateLimit = 40
    var headBytes = 16 * 1024
    var tailBytes = 128 * 1024
    var widenedTailBytes = 1024 * 1024

    public init(projectsRoot: URL) {
        self.projectsRoot = projectsRoot
    }

    public static func defaultRoot() -> URL {
        RealHome.url.appendingPathComponent(".claude/projects", isDirectory: true)
    }

    public func recentSessions(limit: Int) throws -> [Session] {
        let candidates = try candidateFiles()
        let sessions = candidates.compactMap { parse(file: $0.url, modified: $0.modified) }
        return Array(SessionRanking.dedupe(sessions).prefix(limit))
    }

    /// Newest `candidateLimit` top-level transcripts by modification date. Subfolders hold subagent files.
    func candidateFiles() throws -> [(url: URL, modified: Date)] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: projectsRoot.path) else { return [] }
        let keys: [URLResourceKey] = [.contentModificationDateKey, .isDirectoryKey]
        var files: [(URL, Date)] = []
        let projectDirs = try fm.contentsOfDirectory(at: projectsRoot, includingPropertiesForKeys: keys,
                                                     options: [.skipsHiddenFiles])
        for dir in projectDirs where (try? dir.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
            // One unreadable folder must not hide the rest.
            guard let entries = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: keys,
                                                            options: [.skipsHiddenFiles]) else { continue }
            for file in entries where file.pathExtension == "jsonl" {
                let modified = (try? file.resourceValues(forKeys: [.contentModificationDateKey])
                    .contentModificationDate) ?? .distantPast
                files.append((file, modified))
            }
        }
        return files.sorted { $0.1 > $1.1 }.prefix(candidateLimit).map { (url: $0.0, modified: $0.1) }
    }

    func parse(file: URL, modified: Date) -> Session? {
        guard let head = try? FileTail.head(of: file, bytes: headBytes) else { return nil }
        let headRecords = FileTail.lines(in: head).compactMap(TranscriptRecord.init(line:))
        guard !headRecords.isEmpty else { return nil }
        // Subagent transcripts mark every record as sidechain.
        if headRecords.allSatisfy({ $0.isSidechain }) { return nil }
        guard let cwd = headRecords.lazy.compactMap(\.cwd).first, !cwd.isEmpty else { return nil }

        var tail = readTail(file, bytes: tailBytes)
        if tail.prompt == nil, !tail.isWholeFile {
            tail = readTail(file, bytes: widenedTailBytes)
        }
        // Still nothing: it may be in a huge file, so scan the head before skipping it.
        let prompt = tail.prompt ?? headRecords.last(where: PromptFilter.isRealPrompt)?.userText
        guard let prompt else { return nil }

        let sessionId = headRecords.lazy.compactMap(\.sessionId).first
            ?? file.deletingPathExtension().lastPathComponent
        return Session(
            id: sessionId,
            source: id,
            projectName: URL(fileURLWithPath: cwd).lastPathComponent,
            projectPath: cwd,
            lastPrompt: PromptFilter.normalize(prompt),
            lastActivity: tail.lastTimestamp ?? modified,
            openURL: DeepLink.codeSession(folder: cwd)
        )
    }

    private func readTail(_ file: URL, bytes: Int) -> (prompt: String?, lastTimestamp: Date?, isWholeFile: Bool) {
        guard let result = try? FileTail.tail(of: file, bytes: bytes) else { return (nil, nil, true) }
        let records = FileTail.lines(in: result.data).compactMap(TranscriptRecord.init(line:))
        let prompt = records.last(where: PromptFilter.isRealPrompt)?.userText
        let lastTimestamp = records.compactMap(\.timestamp).max()
        return (prompt, lastTimestamp, result.isWholeFile)
    }
}
