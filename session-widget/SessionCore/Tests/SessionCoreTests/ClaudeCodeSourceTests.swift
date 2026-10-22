import XCTest
@testable import SessionCore

final class ClaudeCodeSourceTests: XCTestCase {
    var fixtures: FixtureBuilder!
    let cwd = "/Users/test/dev/alpha"

    override func setUpWithError() throws { fixtures = try FixtureBuilder() }
    override func tearDown() { fixtures.cleanUp() }

    private func scan(limit: Int = 30) throws -> [Session] {
        try ClaudeCodeSource(projectsRoot: fixtures.root).recentSessions(limit: limit)
    }

    func testNormalSessionUsesLastPromptAndTimestamp() throws {
        let t0 = Date(timeIntervalSince1970: 1_800_000_000)
        try fixtures.write(project: "-Users-test-dev-alpha", session: "s1", lines: [
            FixtureBuilder.user("first question", cwd: cwd, at: t0),
            FixtureBuilder.assistant(cwd: cwd, at: t0 + 5),
            FixtureBuilder.user("second question", cwd: cwd, at: t0 + 60),
            FixtureBuilder.assistant(cwd: cwd, at: t0 + 90),
        ])
        let sessions = try scan()
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions[0].projectName, "alpha")
        XCTAssertEqual(sessions[0].projectPath, cwd)
        XCTAssertEqual(sessions[0].lastPrompt, "second question")
        XCTAssertEqual(sessions[0].lastActivity.timeIntervalSince1970, (t0 + 90).timeIntervalSince1970, accuracy: 0.01)
        XCTAssertEqual(sessions[0].openURL.absoluteString, "claude://code/new?folder=%2FUsers%2Ftest%2Fdev%2Falpha")
    }

    func testToolResultOnlyMessagesAreSkipped() throws {
        try fixtures.write(project: "p", session: "s1", lines: [
            FixtureBuilder.user("real prompt", cwd: cwd),
            FixtureBuilder.userBlocks([["type": "tool_result", "tool_use_id": "x", "content": "output"]], cwd: cwd),
        ])
        XCTAssertEqual(try scan().first?.lastPrompt, "real prompt")
    }

    func testTextBlocksCount() throws {
        try fixtures.write(project: "p", session: "s1", lines: [
            FixtureBuilder.userBlocks([["type": "text", "text": "block prompt"]], cwd: cwd),
        ])
        XCTAssertEqual(try scan().first?.lastPrompt, "block prompt")
    }

    func testCommandWrappersAndMetaAreSkipped() throws {
        try fixtures.write(project: "p", session: "s1", lines: [
            FixtureBuilder.user("real prompt", cwd: cwd),
            FixtureBuilder.user("<command-name>/clear</command-name>", cwd: cwd),
            FixtureBuilder.user("<local-command-stdout>x</local-command-stdout>", cwd: cwd),
            FixtureBuilder.user("Caveat: The messages below were generated", cwd: cwd),
            FixtureBuilder.user("[Request interrupted by user]", cwd: cwd),
            FixtureBuilder.user("meta text", cwd: cwd, meta: true),
        ])
        XCTAssertEqual(try scan().first?.lastPrompt, "real prompt")
    }

    func testSidechainFileIsSkipped() throws {
        try fixtures.write(project: "p", session: "agent", lines: [
            FixtureBuilder.user("subagent task", cwd: cwd, sidechain: true),
        ])
        XCTAssertTrue(try scan().isEmpty)
    }

    func testMalformedLineIsSkipped() throws {
        try fixtures.write(project: "p", session: "s1", lines: [
            "{not json",
            FixtureBuilder.user("still works", cwd: cwd),
            "",
            "[1,2,3]",
        ])
        XCTAssertEqual(try scan().first?.lastPrompt, "still works")
    }

    func testEmptyFileAndNoPromptFileAreSkipped() throws {
        try fixtures.write(project: "p", session: "empty", lines: [])
        try fixtures.write(project: "p", session: "noprompt", lines: [FixtureBuilder.assistant(cwd: cwd)])
        XCTAssertTrue(try scan().isEmpty)
    }

    func testVeryLargeFileFindsPromptOutsideTail() throws {
        let filler = FixtureBuilder.assistant(cwd: cwd)
        // About 2 MB of assistant lines after the only prompt, beyond the widened 1 MB tail.
        let count = (2 * 1024 * 1024) / filler.utf8.count
        let lines = [FixtureBuilder.user("early prompt", cwd: cwd)] + Array(repeating: filler, count: count)
        try fixtures.write(project: "p", session: "big", lines: lines)
        XCTAssertEqual(try scan().first?.lastPrompt, "early prompt")
    }

    func testLargeFilePromptInWidenedTail() throws {
        let filler = FixtureBuilder.assistant(cwd: cwd)
        let count = (512 * 1024) / filler.utf8.count
        let lines = [FixtureBuilder.user("head prompt", cwd: cwd)] + Array(repeating: filler, count: count)
            + [FixtureBuilder.user("mid prompt", cwd: cwd)] + Array(repeating: filler, count: count)
        try fixtures.write(project: "p", session: "big", lines: lines)
        XCTAssertEqual(try scan().first?.lastPrompt, "mid prompt")
    }

    func testNonASCIIAndSpacesInPath() throws {
        let path = "/Users/test/Client Work/caf\u{e9} \u{65e5}\u{672c}"
        try fixtures.write(project: "p", session: "s1", lines: [FixtureBuilder.user("pr\u{fc}fen \u{1f680}", cwd: path)])
        let s = try XCTUnwrap(try scan().first)
        XCTAssertEqual(s.projectName, "caf\u{e9} \u{65e5}\u{672c}")
        XCTAssertEqual(s.lastPrompt, "pr\u{fc}fen \u{1f680}")
        XCTAssertFalse(s.openURL.absoluteString.contains(" "))
        XCTAssertTrue(s.openURL.absoluteString.hasPrefix("claude://code/new?folder=%2FUsers%2Ftest%2FClient%20Work%2F"))
    }

    func testResumedDuplicateCollapses() throws {
        let t0 = Date(timeIntervalSince1970: 1_800_000_000)
        try fixtures.write(project: "p", session: "old", lines: [
            FixtureBuilder.user("same prompt", cwd: cwd, session: "old", at: t0),
        ], modified: t0)
        try fixtures.write(project: "p", session: "new", lines: [
            FixtureBuilder.user("same prompt", cwd: cwd, session: "new", at: t0 + 100),
        ], modified: t0 + 100)
        let sessions = try scan()
        XCTAssertEqual(sessions.map(\.id), ["new"])
    }

    func testOrderAndLimitAndCandidateCap() throws {
        let t0 = Date(timeIntervalSince1970: 1_800_000_000)
        for i in 0..<50 {
            let at = t0 + Double(i * 60)
            try fixtures.write(project: "proj\(i)", session: "s\(i)", lines: [
                FixtureBuilder.user("prompt \(i)", cwd: "/w/proj\(i)", session: "s\(i)", at: at),
            ], modified: at)
        }
        let all = try scan(limit: 100)
        XCTAssertEqual(all.count, 40, "only the newest 40 files are parsed")
        XCTAssertEqual(all.first?.id, "s49")
        XCTAssertEqual(try scan(limit: 10).count, 10)
    }

    func testSubfolderFilesAreIgnored() throws {
        try fixtures.write(project: "p/s1/subagents", session: "agent-1", lines: [FixtureBuilder.user("x", cwd: cwd)])
        XCTAssertTrue(try scan().isEmpty)
    }

    func testMissingRootReturnsEmpty() throws {
        let source = ClaudeCodeSource(projectsRoot: fixtures.root.appendingPathComponent("nope"))
        XCTAssertTrue(try source.recentSessions(limit: 10).isEmpty)
    }

    func testPerformanceWith500Files() throws {
        let filler = FixtureBuilder.assistant(cwd: cwd)
        for i in 0..<500 {
            try fixtures.write(project: "proj\(i % 25)", session: "s\(i)", lines:
                [FixtureBuilder.user("prompt \(i)", cwd: "/w/proj\(i % 25)")] + Array(repeating: filler, count: 200))
        }
        let start = Date()
        _ = try scan()
        XCTAssertLessThan(Date().timeIntervalSince(start), 2.0)
    }
}
