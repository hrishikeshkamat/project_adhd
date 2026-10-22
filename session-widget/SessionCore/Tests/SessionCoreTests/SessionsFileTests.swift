import XCTest
@testable import SessionCore

final class SessionsFileTests: XCTestCase {
    private func session(_ id: String, prompt: String? = "p", at seconds: TimeInterval) -> Session {
        Session(id: id, source: "claude-code", projectName: "x", projectPath: "/x", lastPrompt: prompt,
                lastActivity: Date(timeIntervalSince1970: seconds), openURL: DeepLink.codeSession(folder: "/x"))
    }

    func testHideSnippetsRemovesPromptFromJSON() throws {
        let file = SessionsFile(generatedAt: Date(), hideSnippets: true, sessions: [session("a", prompt: "secret", at: 1)])
        let json = String(decoding: try file.encoded(), as: UTF8.self)
        XCTAssertFalse(json.contains("secret"))
        XCTAssertFalse(json.contains("lastPrompt"))
    }

    func testRoundTripAndSorting() throws {
        let file = SessionsFile(generatedAt: Date(timeIntervalSince1970: 100), hideSnippets: false,
                                sessions: [session("old", at: 1), session("new", at: 2)])
        let decoded = try SessionsFile.decode(file.encoded())
        XCTAssertEqual(decoded.sessions.map(\.id), ["new", "old"])
        XCTAssertEqual(decoded, file)
    }

    func testCapsEntries() {
        let many = (0..<50).map { session("s\($0)", at: TimeInterval($0)) }
        XCTAssertEqual(SessionsFile(generatedAt: Date(), hideSnippets: false, sessions: many).sessions.count,
                       SessionsFile.maxEntries)
    }

    func testUnknownSchemaVersionThrows() {
        let data = Data(#"{"schemaVersion":99,"generatedAt":"2026-10-22T09:30:00Z","hideSnippets":false,"sessions":[]}"#.utf8)
        XCTAssertThrowsError(try SessionsFile.decode(data)) { error in
            XCTAssertEqual(error as? SessionsFileError, .unknownSchemaVersion(99))
        }
    }

    func testSameContentIgnoresGeneratedAt() {
        let a = SessionsFile(generatedAt: Date(timeIntervalSince1970: 1), hideSnippets: false, sessions: [session("a", at: 1)])
        let b = SessionsFile(generatedAt: Date(timeIntervalSince1970: 2), hideSnippets: false, sessions: [session("a", at: 1)])
        XCTAssertTrue(a.hasSameContent(as: b))
    }

    func testCollapseByProject() {
        let s1 = Session(id: "1", source: "c", projectName: "a", projectPath: "/a", lastPrompt: "x",
                         lastActivity: Date(timeIntervalSince1970: 1), openURL: DeepLink.codeSession(folder: "/a"))
        let s2 = Session(id: "2", source: "c", projectName: "a", projectPath: "/a", lastPrompt: "y",
                         lastActivity: Date(timeIntervalSince1970: 2), openURL: DeepLink.codeSession(folder: "/a"))
        XCTAssertEqual(SessionRanking.collapseByProject([s1, s2]).map(\.id), ["2"])
    }
}
