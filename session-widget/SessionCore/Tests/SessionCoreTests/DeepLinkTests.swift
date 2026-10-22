import XCTest
@testable import SessionCore

final class DeepLinkTests: XCTestCase {
    func testEncodesSlashesAndSpaces() {
        XCTAssertEqual(DeepLink.codeSession(folder: "/Users/a/My Project").absoluteString,
                       "claude://code/new?folder=%2FUsers%2Fa%2FMy%20Project")
    }

    func testEncodesNonASCIIAndReserved() {
        let url = DeepLink.codeSession(folder: "/w/caf\u{e9}&q=x#y").absoluteString
        XCTAssertEqual(url, "claude://code/new?folder=%2Fw%2Fcaf%C3%A9%26q%3Dx%23y")
        XCTAssertFalse(url.contains("&q="), "a folder name must never inject a q parameter")
    }

    func testRoundTrip() {
        let folder = "/Users/a/\u{65e5}\u{672c} dir"
        let url = DeepLink.codeSession(folder: folder)
        let item = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first
        XCTAssertEqual(item?.name, "folder")
        XCTAssertEqual(item?.value, folder)
    }
}
