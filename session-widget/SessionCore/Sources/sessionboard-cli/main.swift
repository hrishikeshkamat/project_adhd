import Foundation
import SessionCore

// Usage: sessionboard-cli list [--limit N] [--json] [--hide-prompts] [--by-project] [--root PATH]
let args = Array(CommandLine.arguments.dropFirst())

func value(after flag: String) -> String? {
    guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
    return args[i + 1]
}

guard args.first == "list" else {
    FileHandle.standardError.write(Data(
        "usage: sessionboard-cli list [--limit N] [--json] [--hide-prompts] [--by-project] [--root PATH]\n".utf8))
    exit(2)
}

let limit = value(after: "--limit").flatMap(Int.init) ?? 15
let root = value(after: "--root").map { URL(fileURLWithPath: $0, isDirectory: true) }
    ?? ClaudeCodeSource.defaultRoot()
let hide = args.contains("--hide-prompts")

do {
    let start = Date()
    var sessions = try ClaudeCodeSource(projectsRoot: root).recentSessions(limit: SessionsFile.maxEntries)
    if args.contains("--by-project") { sessions = SessionRanking.collapseByProject(sessions) }
    sessions = Array(sessions.prefix(limit))
    let file = SessionsFile(generatedAt: Date(), hideSnippets: hide, sessions: sessions)

    if args.contains("--json") {
        FileHandle.standardOutput.write(try file.encoded())
        print()
    } else {
        for s in file.sessions {
            let name = s.projectName.padding(toLength: 24, withPad: " ", startingAt: 0)
            let time = RelativeTime.short(from: s.lastActivity).padding(toLength: 5, withPad: " ", startingAt: 0)
            let prompt = s.lastPrompt.map { String($0.prefix(80)) } ?? ""
            print("\(name) \(time) \(prompt)")
        }
        let ms = Int(Date().timeIntervalSince(start) * 1000)
        FileHandle.standardError.write(Data("\(file.sessions.count) sessions in \(ms) ms\n".utf8))
    }
} catch {
    FileHandle.standardError.write(Data("error: \(error)\n".utf8))
    exit(1)
}
