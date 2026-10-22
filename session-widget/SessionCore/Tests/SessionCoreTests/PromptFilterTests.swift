import XCTest
@testable import SessionCore

final class PromptFilterTests: XCTestCase {
    func testCollapsesWhitespace() {
        XCTAssertEqual(PromptFilter.normalize("  a\n\n b\t c  "), "a b c")
    }

    func testTruncatesTo160() {
        let out = PromptFilter.normalize(String(repeating: "x", count: 500))
        XCTAssertEqual(out.count, PromptFilter.maxLength)
        XCTAssertTrue(out.hasSuffix("\u{2026}"))
    }

    func testShortTextUnchanged() {
        XCTAssertEqual(PromptFilter.normalize("hello"), "hello")
    }
}
