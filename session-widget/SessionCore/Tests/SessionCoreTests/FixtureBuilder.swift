import Foundation

/// Builds synthetic transcript folders. No real transcript content is ever used.
final class FixtureBuilder {
    let root: URL

    init() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("SessionCoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    func cleanUp() {
        try? FileManager.default.removeItem(at: root)
    }

    @discardableResult
    func write(project: String, session: String, lines: [String], modified: Date = Date()) throws -> URL {
        let dir = root.appendingPathComponent(project, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("\(session).jsonl")
        try Data((lines.joined(separator: "\n") + "\n").utf8).write(to: file)
        try FileManager.default.setAttributes([.modificationDate: modified], ofItemAtPath: file.path)
        return file
    }

    static func iso(_ date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: date)
    }

    static func json(_ object: [String: Any]) -> String {
        let data = try! JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        return String(decoding: data, as: UTF8.self)
    }

    static func user(_ text: String, cwd: String, session: String = "s1", at date: Date = Date(),
                     sidechain: Bool = false, meta: Bool = false) -> String {
        json([
            "type": "user", "cwd": cwd, "sessionId": session, "timestamp": iso(date),
            "isSidechain": sidechain, "isMeta": meta,
            "message": ["role": "user", "content": text],
        ])
    }

    static func userBlocks(_ blocks: [[String: Any]], cwd: String, at date: Date = Date()) -> String {
        json([
            "type": "user", "cwd": cwd, "sessionId": "s1", "timestamp": iso(date),
            "isSidechain": false, "message": ["role": "user", "content": blocks],
        ])
    }

    static func assistant(cwd: String, at date: Date = Date()) -> String {
        json([
            "type": "assistant", "cwd": cwd, "sessionId": "s1", "timestamp": iso(date),
            "isSidechain": false,
            "message": ["role": "assistant", "content": [["type": "text", "text": "synthetic reply"]]],
        ])
    }
}
